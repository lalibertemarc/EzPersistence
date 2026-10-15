std = "lua51"
max_line_length = false
self = false

globals = {
    "EzPersistenceDB",
    "SLASH_EZPERSISTENCE1",
    "SLASH_EZPERSISTENCE2",
    "SlashCmdList",
    "UISpecialFrames",
    -- EzEmote's saved variables: chains are added to EzEmoteDB.custom
    "EzEmoteDB",
}

read_globals = {
    -- Frames & UI
    "CreateFrame", "DEFAULT_CHAT_FRAME", "UIParent", "ChatFontNormal",
    -- Macros
    "Constants", "CreateMacro", "EditMacro", "GetMacroInfo", "GetNumMacros", "PickupMacro",
    -- Key bindings
    "GetBinding", "GetBindingAction", "GetCurrentBindingSet", "GetNumBindings", "SaveBindings", "SetBinding",
    -- Action bars and the cursor
    "C_ActionBar", "GetActionInfo", "GetActionText", "PickupAction", "PlaceAction",
    "C_Spell", "PickupSpell", "C_Item", "PickupItem", "C_EquipmentSet",
    "ClearCursor", "GetCursorInfo",
    -- Settings
    "ConsoleGetAllCommands", "GetCVar", "GetCVarDefault", "SetCVar",
    -- Edit Mode
    "C_EditMode", "Enum",
    -- Other addons
    "EzCinematicDB",
    -- Global APIs
    "C_Timer", "InCombatLockdown", "issecretvalue", "UnitName",
    -- Lua helpers WoW adds
    "date", "time", "strtrim", "strlower", "tinsert",
}
