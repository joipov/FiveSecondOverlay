-- Lua 5.1, explicit WoW globals. Modeled on HealPerMana / GatherSkillTooltip.
std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".release/",
	".annotations/",
	"assets/",
}

globals = {
	"FiveSecondOverlayDB",
	"FiveSecondOverlay_OnAddonCompartmentClick",
	"FiveSecondOverlayHighlight",
	"FiveSecondOverlayMinimapButton",
	"SLASH_FSO1",
	"SLASH_FSO2",
	SlashCmdList = { fields = { "FSO" } },
}

read_globals = {
	"issecretvalue",
	"canaccessvalue",
	"issecrettable",
	"canaccesstable",

	"C_Spell",
	"C_Timer",
	"Enum",
	"LibStub",

	"CreateFrame",
	"GetTime",
	"GetCursorPosition",
	"UnitPowerType",
	"UnitGUID",
	"IsAutoRepeatSpell",
	"Settings",
	"SettingsPanel",
	"CreateSettingsButtonInitializer",
	"ColorPickerFrame",
	"GameTooltip",
	"Minimap",
	"MinimalSliderWithSteppersMixin",
	"UIParent",
	"PlayerFrame",
	"PlayerFrameManaBar",
	"EllesmereUIUnitFrames_Player",
	"ERB_PrimaryBar",
	"print",
}
