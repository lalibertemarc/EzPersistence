-- EzPersistence: Edit Mode layouts, saved as the same text Edit Mode's own Share > Copy makes.
-- They aren't written back automatically (saving layouts from addon code could taint Edit Mode);
-- /ep layouts shows one ready to copy into Edit Mode's Import.
local _, ns = ...

local PRESET = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Preset or 0

local function Capture()
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.ConvertLayoutInfoToString) then return end
    local info = C_EditMode.GetLayouts()
    local list = {}
    for _, layout in ipairs(info and info.layouts or {}) do
        if layout.layoutType ~= PRESET then
            local ok, text = pcall(C_EditMode.ConvertLayoutInfoToString, layout)
            if ok and text then list[#list + 1] = { name = layout.layoutName, text = text } end
        end
    end
    return list
end

---------------------------------------------------------------------------
-- Copy box
---------------------------------------------------------------------------
local box

local function CopyBox()
    if box then return box end
    box = CreateFrame("Frame", "EzPersistenceCopyFrame", UIParent, "BasicFrameTemplateWithInset")
    box:SetSize(520, 300)
    box:SetPoint("CENTER")
    box:SetFrameStrata("DIALOG")
    box:SetMovable(true)
    box:EnableMouse(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", box.StartMoving)
    box:SetScript("OnDragStop", box.StopMovingOrSizing)
    -- The template's button goes through HideUIPanel, which is blocked in combat.
    if box.CloseButton then box.CloseButton:SetScript("OnClick", function() box:Hide() end) end
    tinsert(UISpecialFrames, "EzPersistenceCopyFrame") -- Escape closes it

    box.title = box.TitleText or box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    if not box.TitleText then box.title:SetPoint("TOP", 0, -5) end

    box.hint = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    box.hint:SetPoint("TOPLEFT", 14, -30)
    box.hint:SetText("Ctrl+C to copy, then Edit Mode > layout menu > Import, and Ctrl+V.")

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -48)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(470)
    edit:SetScript("OnEscapePressed", function() box:Hide() end)
    -- Read-only: typing puts the layout text back and selects it again.
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(box.text or "")
            self:HighlightText()
        end
    end)
    scroll:SetScrollChild(edit)
    box.edit = edit
    return box
end

local function ShowLayout(owner, layout, n, total)
    local frame = CopyBox()
    frame.title:SetText(("%s - %s (%d of %d)"):format(owner, layout.name, n, total))
    frame.text = layout.text
    frame.edit:SetText(layout.text)
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

-- /ep layouts [n] [name]
function ns.commands.layouts(arg)
    local n, key
    for word in arg:gmatch("%S+") do
        if tonumber(word) then n = tonumber(word) else key = strlower(word) end
    end
    key = key or ns.Me()
    local profile = ns.Profile(key)
    local list = profile and profile.layouts
    if not list or #list == 0 then
        -- Usually a new character: point at the profiles that do have layouts.
        local others = {}
        for _, other in ipairs(ns.ProfileKeys()) do
            local layouts = ns.Profile(other).layouts
            if layouts and #layouts > 0 then others[#others + 1] = other end
        end
        ns.Print(("no Edit Mode layouts saved for |cffffd100%s|r."):format(key or "this character"))
        if #others > 0 then
            ns.Print(("saved on: %s. Open theirs with |cffaaaaaa/ep layouts %s|r.")
                :format(table.concat(others, ", "), others[1]))
        end
        return
    end
    n = n or 1
    if not list[n] then return ns.Print(("there are %d saved layouts; pick 1 to %d."):format(#list, #list)) end
    ShowLayout(profile.character or key, list[n], n, #list)
    if #list > 1 then
        local names = {}
        for i, layout in ipairs(list) do names[#names + 1] = i .. ". " .. layout.name end
        ns.Print(("saved layouts: %s. |cffaaaaaa/ep layouts <number> %s|r for another.")
            :format(table.concat(names, ", "), key))
    end
end

-- "/ep layouts bergaber", so the hint works when restoring someone else's profile.
local function LayoutsCommand(profile)
    return "/ep layouts" .. (profile.character and " " .. strlower(profile.character) or "")
end

ns.RegisterPart({
    key = "layouts",
    label = "Edit Mode layouts",
    save = function(profile)
        profile.layouts = Capture()
        return profile.layouts and ("%d Edit Mode layouts"):format(#profile.layouts)
    end,
    restore = function(profile)
        local list = profile.layouts
        if not list or #list == 0 then return "Edit Mode layouts: none saved" end
        return ("Edit Mode layouts: %d saved, not restored automatically. |cffaaaaaa%s|r to copy one into Edit Mode's Import")
            :format(#list, LayoutsCommand(profile))
    end,
    status = function(profile)
        local list = profile.layouts
        if not list or #list == 0 then return "none saved" end
        return ("%d saved (import them by hand with |cffaaaaaa%s|r)"):format(#list, LayoutsCommand(profile))
    end,
})
