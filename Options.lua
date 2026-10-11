local _, ns = ...

-- Settings panel, in the Blizzard Settings API.

local Settings = Settings
local ColorPickerFrame = ColorPickerFrame
local SettingsPanel = SettingsPanel

local function Clamp01(value, fallback)
	value = tonumber(value)
	if not value then
		return fallback
	end
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

local function SetColor(r, g, b)
	local db = ns.db
	db.r = Clamp01(r, ns.defaults.r)
	db.g = Clamp01(g, ns.defaults.g)
	db.b = Clamp01(b, ns.defaults.b)
	ns.Refresh()
end

local function OpenColorPicker()
	local db = ns.db
	local r, g, b = db.r, db.g, db.b
	ColorPickerFrame:SetupColorPickerAndShow({
		r = r,
		g = g,
		b = b,
		hasOpacity = false,
		swatchFunc = function()
			SetColor(ColorPickerFrame:GetColorRGB())
		end,
		cancelFunc = function()
			SetColor(r, g, b)
		end,
	})
end

local function AddColorButton(category, tooltip)
	local layout = SettingsPanel:GetLayout(category)
	local initializer = CreateSettingsButtonInitializer(
		"Highlight color",
		"Choose color",
		OpenColorPicker,
		tooltip,
		true
	)
	layout:AddInitializer(initializer)
	return initializer
end

function ns.OpenSettings()
	if not ns.settingsCategory then
		ns.InitOptions()
	end
	if not ns.settingsCategory then
		ns.Print("Couldn't open settings.")
		return
	end
	Settings.OpenToCategory(ns.settingsCategory:GetID())
end

function ns.InitOptions()
	if ns.settingsCategory then
		return
	end
	local category = Settings.RegisterVerticalLayoutCategory("Five Second Overlay")
	ns.settingsCategory = category

	local enableSetting = Settings.RegisterAddOnSetting(
		category,
		"FSO_ENABLED",
		"enabled",
		ns.db,
		Settings.VarType.Boolean,
		"Enable Five Second Overlay",
		true
	)
	enableSetting:SetValueChangedCallback(function()
		ns.SetEnabled()
	end)
	local enableCheckbox = Settings.CreateCheckbox(
		category,
		enableSetting,
		"Highlight on your mana bar during the 5-second rule. It shrinks from the right."
	)

	local minimapSetting = Settings.RegisterAddOnSetting(
		category,
		"FSO_SHOW_MINIMAP",
		"showMinimapButton",
		ns.db,
		Settings.VarType.Boolean,
		"Minimap button",
		true
	)
	minimapSetting:SetValueChangedCallback(function()
		ns.UpdateMinimapButton()
	end)
	local minimapCheckbox = Settings.CreateCheckbox(
		category,
		minimapSetting,
		"Button on the minimap. Opens settings. Ellesmere puts it with the other addon buttons."
	)

	local alphaSetting = Settings.RegisterAddOnSetting(
		category,
		"FSO_ALPHA",
		"a",
		ns.db,
		Settings.VarType.Number,
		"Highlight opacity",
		ns.defaults.a
	)
	alphaSetting:SetValueChangedCallback(function()
		ns.db.a = Clamp01(ns.db.a, ns.defaults.a)
		ns.Refresh()
	end)
	local alphaOptions = Settings.CreateSliderOptions(0.05, 0.60, 0.01)
	alphaOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return string.format("%.0f%%", value * 100)
	end)
	local alphaSlider = Settings.CreateSlider(category, alphaSetting, alphaOptions, "How strong the highlight is.")

	local insetSetting = Settings.RegisterAddOnSetting(
		category,
		"FSO_INSET",
		"inset",
		ns.db,
		Settings.VarType.Number,
		"Edge gap",
		ns.defaults.inset
	)
	insetSetting:SetValueChangedCallback(function()
		ns.db.inset = math.floor(ns.db.inset + 0.5)
		ns.Refresh()
	end)
	local insetOptions = Settings.CreateSliderOptions(0, 4, 1)
	insetOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return string.format("%.0f px", value)
	end)
	local insetSlider = Settings.CreateSlider(category, insetSetting, insetOptions, "Space between the highlight and the edge of the bar.")

	local colorButton = AddColorButton(category, "Color of the highlight. White is the default.")

	local function Enabled()
		return enableSetting:GetValue()
	end
	for _, control in ipairs({ minimapCheckbox, alphaSlider, insetSlider, colorButton }) do
		control:SetParentInitializer(enableCheckbox, Enabled)
	end

	Settings.RegisterAddOnCategory(category)
end

-- Addon compartment, named by the TOC.
function _G.FiveSecondOverlay_OnAddonCompartmentClick()
	ns.OpenSettings()
end

function _G.FiveSecondOverlay_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	GameTooltip:AddLine("Five Second Overlay")
	GameTooltip:AddLine("Click for settings.", 1, 1, 1)
	GameTooltip:Show()
end

function _G.FiveSecondOverlay_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

_G.SLASH_FSO1 = "/fso"
_G.SLASH_FSO2 = "/fivesecond"
_G.SlashCmdList.FSO = ns.OpenSettings
