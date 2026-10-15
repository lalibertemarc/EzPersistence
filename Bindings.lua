-- EzPersistence: key bindings, saved as key -> command ("SHIFT-1" -> "MACRO Power") with the
-- binding set they were in (account-wide or character-specific).
local _, ns = ...

local MODIFIERS = { "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }

local NAMED_KEYS = {
    "SPACE", "TAB", "ESCAPE", "ENTER", "BACKSPACE", "INSERT", "DELETE", "HOME", "END", "PAGEUP", "PAGEDOWN",
    "UP", "DOWN", "LEFT", "RIGHT", "CAPSLOCK", "PRINTSCREEN", "PAUSE", "SCROLLLOCK", "NUMLOCK",
    "NUMPADDIVIDE", "NUMPADMULTIPLY", "NUMPADMINUS", "NUMPADPLUS", "NUMPADDECIMAL",
    "MOUSEWHEELUP", "MOUSEWHEELDOWN",
    "`", "-", "=", "[", "]", "\\", ";", "'", ",", ".", "/",
}

local allKeys -- every key with every modifier, built on first use

local function AllKeys()
    if allKeys then return allKeys end
    local base = {}
    for c = string.byte("A"), string.byte("Z") do base[#base + 1] = string.char(c) end
    for i = 0, 9 do
        base[#base + 1] = tostring(i)
        base[#base + 1] = "NUMPAD" .. i
    end
    for i = 1, 24 do base[#base + 1] = "F" .. i end
    for i = 1, 10 do base[#base + 1] = "BUTTON" .. i end
    for _, key in ipairs(NAMED_KEYS) do base[#base + 1] = key end

    allKeys = {}
    for _, modifier in ipairs(MODIFIERS) do
        for _, key in ipairs(base) do allKeys[#allKeys + 1] = modifier .. key end
    end
    return allKeys
end

-- Every bound key and its command. GetBinding only lists commands from Bindings.xml files, so
-- macro, spell, item and click bindings are found by asking each key.
local function CurrentBindings()
    local map = {}
    for i = 1, GetNumBindings() do
        local binding = { GetBinding(i) } -- command, category, key1, key2, ...
        for k = 3, #binding do map[binding[k]] = binding[1] end
    end
    for _, key in ipairs(AllKeys()) do
        local command = GetBindingAction(key)
        if command and command ~= "" then map[key] = command end
    end
    return map
end

-- Keys whose command differs between the two maps.
local function Differences(current, saved)
    local keys = {}
    for key, command in pairs(current) do
        if saved[key] ~= command then keys[key] = true end
    end
    for key, command in pairs(saved) do
        if current[key] ~= command then keys[key] = true end
    end
    return keys
end

ns.RegisterPart({
    key = "bindings",
    label = "Key bindings",
    save = function(profile)
        local keys = CurrentBindings()
        local count = 0
        for _ in pairs(keys) do count = count + 1 end
        profile.bindings = { set = GetCurrentBindingSet(), keys = keys }
        return ("%d key bindings"):format(count)
    end,
    restore = function(profile)
        local saved = profile.bindings
        if not saved then return "key bindings: none saved" end
        local current = CurrentBindings()
        local changed, failed = 0, {}
        -- Unbind first, so a command moving to another key doesn't get unbound after.
        for key in pairs(Differences(current, saved.keys)) do
            changed = changed + 1
            if current[key] then SetBinding(key) end
        end
        for key, command in pairs(saved.keys) do
            if current[key] ~= command and not SetBinding(key, command) then
                failed[#failed + 1] = key .. " " .. command
            end
        end
        SaveBindings(saved.set or GetCurrentBindingSet())
        local line = ("key bindings: %d keys changed"):format(changed - #failed)
        if #failed > 0 then
            line = line .. (", |cffff5555couldn't bind|r %s"):format(table.concat(failed, ", "))
        end
        return line
    end,
    status = function(profile)
        if not profile.bindings then return "none saved" end
        local count = 0
        for _ in pairs(Differences(CurrentBindings(), profile.bindings.keys)) do count = count + 1 end
        if count == 0 then return "|cff00ff00all in place|r" end
        return ("|cffffd100%d keys differ|r"):format(count)
    end,
})
