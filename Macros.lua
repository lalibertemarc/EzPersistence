-- EzPersistence: account and character macros, and the EzEmote chains they run (/eze <name>).
-- CreateMacro/EditMacro are the same calls Blizzard's macro window makes; the server stores the
-- result like a hand-made macro.
local _, ns = ...

local FALLBACK = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 }

local function MacroConst(key)
    local consts = Constants and Constants.MacroConsts
    return consts and consts[key] or FALLBACK[key]
end

-- Macro indexes: account macros are 1..numAccount, character macros start after MAX_ACCOUNT_MACROS.
local function Range(account)
    local numAccount, numChar = GetNumMacros()
    if account then return 1, numAccount end
    local first = MacroConst("MAX_ACCOUNT_MACROS") + 1
    return first, first + numChar - 1
end

-- Index of the macro with this exact name in one group, or nil. GetMacroIndexByName would
-- search both, and the same name can exist in each ("pray").
function ns.FindMacro(name, account)
    local first, last = Range(account)
    for i = first, last do
        if GetMacroInfo(i) == name then return i end
    end
end

function ns.IsAccountMacro(index)
    return index <= MacroConst("MAX_ACCOUNT_MACROS")
end

local function SameIcon(a, b)
    return (tonumber(a) or a) == (tonumber(b) or b)
end

-- "ok", "differs" or "missing", plus the macro's index when it exists.
local function MacroStatus(m, account)
    local index = ns.FindMacro(m.name, account)
    if not index then return "missing" end
    local _, icon, body = GetMacroInfo(index)
    if strtrim(body or "") ~= m.body or not SameIcon(icon, m.icon) then return "differs", index end
    return "ok", index
end

local function CaptureMacros(account)
    local list = {}
    local first, last = Range(account)
    for i = first, last do
        local name, icon, body = GetMacroInfo(i)
        if name then
            list[#list + 1] = { name = name, icon = tonumber(icon) or icon, body = strtrim(body or "") }
        end
    end
    return list
end

local function HasRoom(account)
    local numAccount, numChar = GetNumMacros()
    if account then return numAccount < MacroConst("MAX_ACCOUNT_MACROS") end
    return numChar < MacroConst("MAX_CHARACTER_MACROS")
end

-- Returns created, updated, and the names that didn't fit.
local function InstallMacros(list, account)
    local created, updated, full = 0, 0, {}
    for _, m in ipairs(list or {}) do
        local status, index = MacroStatus(m, account)
        if status == "differs" then
            EditMacro(index, m.name, m.icon, m.body)
            updated = updated + 1
        elseif status == "missing" then
            if HasRoom(account) then
                CreateMacro(m.name, m.icon, m.body, not account or nil)
                created = created + 1
            else
                full[#full + 1] = m.name
            end
        end
    end
    return created, updated, full
end

---------------------------------------------------------------------------
-- EzEmote chains (account-wide, in EzEmoteDB.custom)
---------------------------------------------------------------------------
local function EzEmoteReady()
    return type(EzEmoteDB) == "table" and type(EzEmoteDB.custom) == "table"
end

local function FindChain(name)
    local lower = name:lower()
    for _, c in ipairs(EzEmoteDB.custom) do
        if type(c.name) == "string" and c.name:lower() == lower then return c end
    end
end

local function SameLines(a, b)
    if type(a) ~= "table" or #a ~= #b then return false end
    for i = 1, #b do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function ChainStatus(e)
    local c = FindChain(e.name)
    if not c then return "missing" end
    return SameLines(c.lines, e.lines) and "ok" or "differs", c
end

local function CaptureChains()
    local list = {}
    for _, c in ipairs(EzEmoteDB.custom) do
        if type(c.name) == "string" and type(c.lines) == "table" then
            list[#list + 1] = { name = c.name, lines = { unpack(c.lines) } }
        end
    end
    return list
end

-- Same ids and fields EzEmote's own editor uses. Returns created, updated.
local function InstallChains(list)
    local created, updated = 0, 0
    for _, e in ipairs(list) do
        local status, c = ChainStatus(e)
        if status == "missing" then
            c = { id = EzEmoteDB.nextId or #EzEmoteDB.custom + 1, name = e.name }
            EzEmoteDB.nextId = c.id + 1
            table.insert(EzEmoteDB.custom, c)
            created = created + 1
        elseif status == "differs" then
            updated = updated + 1
        end
        if status ~= "ok" then c.lines = { unpack(e.lines) } end
    end
    return created, updated
end

---------------------------------------------------------------------------
-- Part
---------------------------------------------------------------------------
-- Names of saved macros and chains that are missing or changed here.
function ns.MacrosPending(profile, account)
    local names = {}
    for _, m in ipairs(profile.macros or {}) do
        if MacroStatus(m, false) ~= "ok" then names[#names + 1] = m.name end
    end
    for _, m in ipairs(account.macros or {}) do
        if MacroStatus(m, true) ~= "ok" then names[#names + 1] = m.name .. " (account)" end
    end
    if EzEmoteReady() then
        for _, e in ipairs(account.emotes or {}) do
            if ChainStatus(e) ~= "ok" then names[#names + 1] = e.name .. " (EzEmote)" end
        end
    end
    return names
end

ns.RegisterPart({
    key = "macros",
    label = "Macros",
    save = function(profile, account)
        profile.macros = CaptureMacros(false)
        account.macros = CaptureMacros(true)
        if EzEmoteReady() then account.emotes = CaptureChains() end
        return ("%d macros (+%d account)"):format(#profile.macros, #account.macros)
    end,
    restore = function(profile, account)
        local accountCreated, accountUpdated, accountFull = InstallMacros(account.macros, true)
        local created, updated, full = InstallMacros(profile.macros, false)
        local line = ("macros: %d created, %d updated"):format(created + accountCreated, updated + accountUpdated)
        for _, name in ipairs(accountFull) do full[#full + 1] = name .. " (account)" end
        if #full > 0 then line = line .. (", |cffff5555no room for|r %s"):format(table.concat(full, ", ")) end
        if account.emotes then
            if EzEmoteReady() then
                line = line .. ("; EzEmote chains: %d created, %d updated"):format(InstallChains(account.emotes))
            else
                line = line .. "; EzEmote isn't loaded, so its chains were skipped"
            end
        end
        return line
    end,
    status = function(profile, account)
        local names = ns.MacrosPending(profile, account)
        if #names == 0 then return "|cff00ff00all in place|r" end
        return ("|cffffd100%d missing or changed|r: %s"):format(#names, table.concat(names, ", "))
    end,
})
