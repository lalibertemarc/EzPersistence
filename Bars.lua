-- EzPersistence: action bar slots. Spells, items, macros and equipment sets are put back by
-- picking them up and placing them, like dragging by hand; macros are found by name, so restore
-- macros first. Other kinds (mounts, pets, flyouts) are saved but left alone on restore.
local _, ns = ...

local NUM_SLOTS = 180 -- every action slot, including stance/form pages and the extra bars
local SUPPORTED = { macro = true, spell = true, item = true, equipmentset = true }

local function ActionText(slot)
    local get = C_ActionBar and C_ActionBar.GetActionText or GetActionText
    return get and get(slot)
end

-- What's in a slot, as saved: { type, id } or { type = "macro", name, account }, or nil if empty.
local function Capture(slot)
    local actionType, id, subType = GetActionInfo(slot)
    if not actionType then return end
    if actionType == "macro" then
        local name, account
        if type(id) == "number" and (subType == nil or subType == "") then
            name = GetMacroInfo(id)
            account = name and ns.IsAccountMacro(id)
        end
        name = name or ActionText(slot)
        return name and { type = "macro", name = name, account = account }
    elseif actionType == "equipmentset" then
        return { type = actionType, name = id }
    end
    return { type = actionType, id = id }
end

local function Same(a, b)
    if not a or not b then return a == b end
    return a.type == b.type and a.id == b.id and a.name == b.name
end

local function Describe(a)
    if a.type == "spell" then
        return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(a.id) or ("spell " .. a.id)
    elseif a.type == "item" then
        return C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(a.id) or ("item " .. a.id)
    end
    return tostring(a.name or a.id)
end

-- Puts the action on the cursor; returns whether something is there.
local function Pickup(a)
    ClearCursor()
    if a.type == "macro" then
        -- Saved group first; for a saved spell-macro the group is unknown, so character first.
        local index = ns.FindMacro(a.name, a.account or false) or ns.FindMacro(a.name, not a.account)
        if index then PickupMacro(index) end
    elseif a.type == "spell" then
        local pickup = C_Spell and C_Spell.PickupSpell or PickupSpell
        pickup(a.id)
    elseif a.type == "item" then
        local pickup = C_Item and C_Item.PickupItem or PickupItem
        pickup(a.id)
    elseif a.type == "equipmentset" then
        local setID = C_EquipmentSet.GetEquipmentSetID(a.name)
        if setID then C_EquipmentSet.PickupEquipmentSet(setID) end
    end
    return GetCursorInfo() ~= nil
end

local function CaptureAll()
    local bars = {}
    for slot = 1, NUM_SLOTS do bars[slot] = Capture(slot) end
    return bars
end

ns.RegisterPart({
    key = "bars",
    label = "Action bars",
    save = function(profile)
        profile.bars = CaptureAll()
        local count = 0
        for _ in pairs(profile.bars) do count = count + 1 end
        return ("%d action bar slots"):format(count)
    end,
    restore = function(profile)
        local saved = profile.bars
        if not saved then return "action bars: none saved" end
        local placed, cleared, skipped, missing = 0, 0, 0, {}
        for slot = 1, NUM_SLOTS do
            local want = saved[slot]
            if not Same(want, Capture(slot)) then
                if not want then
                    ClearCursor()
                    PickupAction(slot)
                    ClearCursor()
                    cleared = cleared + 1
                elseif not SUPPORTED[want.type] then
                    skipped = skipped + 1
                elseif Pickup(want) then
                    PlaceAction(slot)
                    ClearCursor()
                    placed = placed + 1
                else
                    missing[#missing + 1] = Describe(want)
                end
            end
        end
        ClearCursor()
        local line = ("action bars: %d placed, %d cleared"):format(placed, cleared)
        if skipped > 0 then line = line .. (", %d mounts/pets/other left alone"):format(skipped) end
        if #missing > 0 then
            line = line .. (", |cffff5555not known here|r: %s"):format(table.concat(missing, ", "))
        end
        return line
    end,
    status = function(profile)
        if not profile.bars then return "none saved" end
        local count = 0
        for slot = 1, NUM_SLOTS do
            if not Same(profile.bars[slot], Capture(slot)) then count = count + 1 end
        end
        if count == 0 then return "|cff00ff00all in place|r" end
        return ("|cffffd100%d slots differ|r"):format(count)
    end,
})
