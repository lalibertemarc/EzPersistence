-- EzPersistence: saves a character's macros, key bindings, action bars, game settings and Edit
-- Mode layouts (/ep save) and puts them back (/ep restore), on this client or a new one. Each
-- of those is a "part" in its own file; everything goes through the normal addon API, out of combat.
local addonName, ns = ...

local events = CreateFrame("Frame")
local db -- EzPersistenceDB, set on ADDON_LOADED

ns.PARTS = {}    -- in restore order (macros first: bindings and bars refer to them by name)
ns.commands = {} -- /ep <command>; part files can add their own

local ALIASES = {
    macro = "macros", binds = "bindings", keybinds = "bindings", keys = "bindings",
    bar = "bars", cvars = "settings", layout = "layouts",
}

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99EzPersistence|r: " .. msg)
end

local Print = ns.Print

-- part = { key, label, save(profile, account, previous) -> summary, restore(profile, account) -> line,
-- status(profile, account) -> text }
function ns.RegisterPart(part)
    ns.PARTS[#ns.PARTS + 1] = part
end

local function FindPart(key)
    for _, part in ipairs(ns.PARTS) do
        if part.key == key then return part end
    end
end

-- Profile key (lowercase first name) and the name as shown. Forever names are unique by first name.
function ns.Me()
    local name = UnitName("player")
    if not name or (issecretvalue and issecretvalue(name)) then return end
    return strlower(name), name
end

-- What /ep save stored on this client wins over what's baked in (Baked.lua, your own install only).
function ns.Account()
    return db.account or ns.DATA.account or {}
end

function ns.Profile(key)
    return key and (db.characters[key] or ns.DATA.characters[key])
end

local function SavedWhen(key)
    local saved = db.characters[key]
    if saved and saved.savedAt then return "saved " .. date("%Y-%m-%d %H:%M", saved.savedAt) end
    return "baked in"
end

-- "/ep restore bars olizzy" -> { bars part }, "olizzy". No parts named means all of them.
local function ParseArgs(arg)
    local parts, key = {}, nil
    for word in arg:gmatch("%S+") do
        word = strlower(word)
        word = ALIASES[word] or word
        local part = FindPart(word)
        if part then
            parts[part] = true
        elseif word ~= "all" then
            key = word
        end
    end
    if not next(parts) then
        for _, part in ipairs(ns.PARTS) do parts[part] = true end
    end
    return parts, key or ns.Me()
end

local function NoProfile(key)
    Print(("nothing saved for |cffffd100%s|r. |cffaaaaaa/ep list|r shows what is."):format(key or "this character"))
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local commands = ns.commands

function commands.save()
    local key, name = ns.Me()
    if not key then return Print("can't read your character name right now. Try again in a moment.") end
    local previous = db.characters[key]
    local profile = { character = name, savedAt = time() }
    local account = {}
    for k, v in pairs(ns.Account()) do account[k] = v end -- parts replace what they capture

    local done = {}
    for _, part in ipairs(ns.PARTS) do
        local summary = part.save(profile, account, previous)
        if summary then done[#done + 1] = summary end
    end
    db.characters[key] = profile
    db.account = account
    Print(("saved |cffffd100%s|r: %s."):format(name, table.concat(done, ", ")))
end

function commands.restore(arg)
    local parts, key = ParseArgs(arg)
    local profile = ns.Profile(key)
    if not profile then return NoProfile(key) end
    if InCombatLockdown() then return Print("can't restore in combat. Try again after.") end

    Print(("restoring |cffffd100%s|r (%s):"):format(profile.character or key, SavedWhen(key)))
    for _, part in ipairs(ns.PARTS) do
        if parts[part] then
            local line = part.restore(profile, ns.Account())
            if line then Print("  " .. line) end
        end
    end
end

function commands.status(arg)
    local parts, key = ParseArgs(arg)
    local profile = ns.Profile(key)
    if not profile then return NoProfile(key) end
    Print(("|cffffd100%s|r (%s), compared with this character:"):format(profile.character or key, SavedWhen(key)))
    for _, part in ipairs(ns.PARTS) do
        if parts[part] then Print(("  %s: %s"):format(part.label, part.status(profile, ns.Account()))) end
    end
end

-- Every character with a profile, saved here or baked in, sorted.
function ns.ProfileKeys()
    local keys, seen = {}, {}
    for _, source in ipairs({ db.characters, ns.DATA.characters }) do
        for key in pairs(source) do
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
    end
    table.sort(keys)
    return keys
end

function commands.list()
    local keys = ns.ProfileKeys()
    if #keys == 0 then return Print("nothing saved yet. |cffaaaaaa/ep save|r on each character.") end
    for _, key in ipairs(keys) do
        Print(("  |cffffd100%s|r - %s"):format(ns.Profile(key).character or key, SavedWhen(key)))
    end
end

local HELP = {
    "/ep save - save this character's macros, key bindings, action bars, settings and Edit Mode layouts",
    "/ep restore [part] [name] - put them back on this character (default: everything you saved here)",
    "/ep status [part] [name] - what differs from the saved copy",
    "/ep list - characters with something saved",
    "/ep layouts [n] [name] - copy a saved Edit Mode layout to import it (name = the character that saved it)",
    "Parts: macros, bindings, bars, settings, layouts",
}

SLASH_EZPERSISTENCE1 = "/ep"
SLASH_EZPERSISTENCE2 = "/ezpersistence"
SlashCmdList.EZPERSISTENCE = function(input)
    if not db then return end
    local cmd, arg = strtrim(input or ""):match("^(%S*)%s*(.-)$")
    local handler = commands[strlower(cmd)]
    if handler then
        handler(strtrim(arg))
    else
        for _, line in ipairs(HELP) do Print(line) end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- Macros arrive from the server shortly after login, so wait before checking.
local function Hint()
    local profile = ns.Profile(ns.Me())
    if not profile then return end
    local pending = #ns.MacrosPending(profile, ns.Account())
    if pending > 0 then
        Print(("%d of your saved macros are missing or changed. |cffaaaaaa/ep status|r to see them, |cffaaaaaa/ep restore macros|r to put them back.")
            :format(pending))
    end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        if type(EzPersistenceDB) ~= "table" then EzPersistenceDB = {} end
        db = EzPersistenceDB
        if type(db.characters) ~= "table" then db.characters = {} end
        ns.DATA.characters = ns.DATA.characters or {}
    elseif arg1 or arg2 then -- PLAYER_ENTERING_WORLD: isInitialLogin, isReloadingUi
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        C_Timer.After(10, Hint)
    end
end)
