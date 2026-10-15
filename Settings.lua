-- EzPersistence: game settings (CVars) you changed from their defaults - interface options,
-- nameplates, combat text, sound volumes and the like. Graphics, hardware and per-install ones
-- are left out: they belong to the PC, not to you.
local _, ns = ...

-- Enum.ConsoleCategory: Combat 3, Game 4, Default 5, Sound 7. Skips Debug, Graphics, Console,
-- Net, Gm, Reveal, None.
local KEEP_CATEGORY = { [3] = true, [4] = true, [5] = true, [7] = true }

local SKIP_PATTERNS = {
    "^gx", "^graphics", "^raidGraphics", "^Sound_Output", "^Sound_Input", "^Sound_Voice", "Device",
    "^last", "^realm", "^portal", "^account", "^agentUID", "Locale$", "^taintLog$", "^scriptErrors$",
}

local function Skipped(name)
    for _, pattern in ipairs(SKIP_PATTERNS) do
        if name:find(pattern) then return true end
    end
end

-- EzCinematic's screenshot mode changes settings until you leave it.
local function CinematicOn()
    return type(EzCinematicDB) == "table" and EzCinematicDB.saved ~= nil
end

-- Kept settings that aren't at their default: name -> value, plus name -> default.
local function NonDefault()
    if not ConsoleGetAllCommands then return end
    local values, defaults = {}, {}
    for _, info in ipairs(ConsoleGetAllCommands()) do
        local name = info.command
        if info.commandType == 0 and KEEP_CATEGORY[info.category] and not Skipped(name) then
            local okValue, value = pcall(GetCVar, name)
            local okDefault, default = pcall(GetCVarDefault, name)
            if okValue and okDefault and value ~= nil and value ~= default then
                values[name], defaults[name] = value, default
            end
        end
    end
    return values, defaults
end

local function Count(map)
    local count = 0
    for _ in pairs(map) do count = count + 1 end
    return count
end

-- name -> value that would make this client match the saved settings, or nil if it can't list them.
-- Ones you hadn't changed when you saved go back to their default.
local function Changes(saved)
    local values, defaults = NonDefault()
    if not values then return end
    local changes = {}
    for name, value in pairs(saved) do
        local ok, current = pcall(GetCVar, name)
        if ok and current ~= nil and current ~= value then changes[name] = value end
    end
    for name in pairs(values) do
        if saved[name] == nil then changes[name] = defaults[name] end
    end
    return changes
end

ns.RegisterPart({
    key = "settings",
    label = "Settings",
    save = function(profile, _, previous)
        if CinematicOn() then
            profile.cvars = previous and previous.cvars
            return "settings kept from your last save (screenshot mode is on)"
        end
        profile.cvars = NonDefault()
        return profile.cvars and ("%d settings"):format(Count(profile.cvars))
    end,
    restore = function(profile)
        local saved = profile.cvars
        if not saved then return "settings: none saved" end
        if CinematicOn() then return "settings: skipped, leave screenshot mode (/cine) first" end
        local changes = Changes(saved)
        if not changes then return "settings: this client can't list them" end
        local changed, failed = 0, {}
        for name, value in pairs(changes) do
            if pcall(SetCVar, name, value) then
                changed = changed + 1
            else
                failed[#failed + 1] = name
            end
        end
        local line = ("settings: %d changed"):format(changed)
        if #failed > 0 then line = line .. (", |cffff5555refused|r: %s"):format(table.concat(failed, ", ")) end
        return line
    end,
    status = function(profile)
        local saved = profile.cvars
        if not saved then return "none saved" end
        local changes = Changes(saved)
        if not changes then return "this client can't list them" end
        local count = Count(changes)
        if count == 0 then return "|cff00ff00all in place|r" end
        return ("|cffffd100%d differ|r"):format(count)
    end,
})
