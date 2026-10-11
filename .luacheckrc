-- Lua 5.1, explicit WoW globals. Same layout in every Joipov addon.
std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".release/",
	".annotations/",
	"assets/",
}

-- Globals this addon writes. It writes them through _G, so luacheck does not
-- require them; the list documents intent and catches accidental renames.
globals = {
	"FiveSecondOverlayDB",
	"FiveSecondOverlayHighlight",
	"SLASH_FSO1",
	"SLASH_FSO2",
	SlashCmdList = { fields = { "FSO" } },
}

-- WoW globals this addon reads. Anything else is an error.
read_globals = {
	"issecretvalue",
	"canaccessvalue",

	"C_AddOns",
	"C_Spell",
	"C_Timer",
	"Enum",
	"LibStub",

	"CreateFrame",
	"GetTime",
	"UnitPowerType",

	"GameTooltip",
	"GetCursorPosition",
	"Minimap",

	"Settings",
	"SettingsPanel",
	"ColorPickerFrame",
	"CreateSettingsButtonInitializer",
	"MinimalSliderWithSteppersMixin",

	"print",
}
