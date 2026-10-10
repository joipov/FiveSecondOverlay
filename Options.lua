local _, ns = ...

local Settings = Settings

local function Clamp01(value, fallback)
	value = tonumber(value)
	if not value then
		return fallback
	end
	if value < 0 then
		return 0
	end
	if value > 1 then
		return 1
	end
	return value
end

function ns.SetColor(r, g, b)
	local db = ns.db
	if not db then
		return
	end
	local defaults = ns.defaults or {}
	db.r = Clamp01(r, defaults.r or 1)
	db.g = Clamp01(g, defaults.g or 1)
	db.b = Clamp01(b, defaults.b or 1)
	if ns.Refresh then
		ns.Refresh()
	end
	return db.r, db.g, db.b
end

function ns.OpenColorPicker()
	local db = ns.db
	if not db or not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then
		return
	end
	local prevR, prevG, prevB = db.r, db.g, db.b
	ColorPickerFrame:SetupColorPickerAndShow({
		r = prevR,
		g = prevG,
		b = prevB,
		hasOpacity = false,
		swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			ns.SetColor(r, g, b)
		end,
		cancelFunc = function()
			ns.SetColor(prevR, prevG, prevB)
		end,
	})
end

local function AddColorButton(category, tooltip)
	if not (SettingsPanel and SettingsPanel.GetLayout and CreateSettingsButtonInitializer) then
		return
	end
	local layout = SettingsPanel:GetLayout(category)
	if not (layout and layout.AddInitializer) then
		return
	end
	layout:AddInitializer(CreateSettingsButtonInitializer(
		"Overlay color",
		"Pick color",
		function()
			ns.OpenColorPicker()
		end,
		tooltip,
		true
	))
end

function ns.SetAlpha(a)
	local db = ns.db
	if not db then
		return
	end
	local fallback = (ns.defaults and ns.defaults.a) or 0.35
	a = tonumber(a) or fallback
	if a < 0.05 then
		a = 0.05
	elseif a > 0.60 then
		a = 0.60
	end
	db.a = a
	ns.Refresh()
	return a
end

function ns.OpenSettings()
	if not ns.settingsCategory then
		ns.InitOptions()
	end
	if not ns.settingsCategory then
		ns.Print("Settings UI unavailable.")
		return
	end
	Settings.OpenToCategory(ns.settingsCategory:GetID())
end

function _G.FiveSecondOverlay_OnAddonCompartmentClick()
	ns.OpenSettings()
end

function ns.InitOptions()
	if ns.settingsCategory or not ns.db or not Settings then
		return
	end

	local ok, err = pcall(function()
		local category = Settings.RegisterVerticalLayoutCategory("Five Second Overlay")
		ns.settingsCategory = category

		local enableSetting = Settings.RegisterAddOnSetting(
			category,
			"FSO_ENABLED",
			"enabled",
			ns.db,
			Settings.VarType.Boolean,
			"Enable overlay",
			true
		)
		enableSetting:SetValueChangedCallback(function()
			ns.SetEnabled(ns.db.enabled)
		end)
		Settings.CreateCheckbox(
			category,
			enableSetting,
			"Show the subtle 5-second rule highlight on your mana bar."
		)

		local minimapSetting = Settings.RegisterAddOnSetting(
			category,
			"FSO_SHOW_MINIMAP",
			"showMinimapButton",
			ns.db,
			Settings.VarType.Boolean,
			"Show minimap button",
			false
		)
		minimapSetting:SetValueChangedCallback(function()
			if ns.UpdateMinimapButton then
				ns.UpdateMinimapButton()
			end
		end)
		Settings.CreateCheckbox(
			category,
			minimapSetting,
			"Show a minimap button that opens these settings. Off by default."
		)

		if Settings.CreateSliderOptions and Settings.CreateSlider then
			local alphaSetting = Settings.RegisterAddOnSetting(
				category,
				"FSO_ALPHA",
				"a",
				ns.db,
				Settings.VarType.Number,
				"Highlight opacity",
				(ns.defaults and ns.defaults.a) or 0.35
			)
			alphaSetting:SetValueChangedCallback(function()
				ns.SetAlpha(ns.db.a)
			end)
			local alphaOpts = Settings.CreateSliderOptions(0.05, 0.60, 0.01)
			if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
				alphaOpts:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
					return string.format("%.0f%%", value * 100)
				end)
			end
			Settings.CreateSlider(category, alphaSetting, alphaOpts, "How strong the mana-bar highlight appears.")

			local insetSetting = Settings.RegisterAddOnSetting(
				category,
				"FSO_INSET",
				"inset",
				ns.db,
				Settings.VarType.Number,
				"Inside padding",
				1
			)
			insetSetting:SetValueChangedCallback(function()
				local v = tonumber(ns.db.inset) or 1
				v = math.floor(v + 0.5)
				if v < 0 then
					v = 0
				elseif v > 4 then
					v = 4
				end
				ns.db.inset = v
				ns.Refresh()
			end)
			local insetOpts = Settings.CreateSliderOptions(0, 4, 1)
			if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
				insetOpts:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
					return tostring(math.floor(value + 0.5)) .. " px"
				end)
			end
			Settings.CreateSlider(
				category,
				insetSetting,
				insetOpts,
				"Shrinks the highlight inside the mana bar on all sides (keeps it off the 1px border; higher = shorter)."
			)
		end

		AddColorButton(category, "Color of the mana-bar highlight. Default is white. It shrinks from the right toward the left.")

		Settings.RegisterAddOnCategory(category)
	end)

	if not ok then
		ns.settingsCategory = nil
		ns.Print("options panel failed: " .. tostring(err))
	end
end

_G.SLASH_FSO1 = "/fso"
_G.SLASH_FSO2 = "/fivesecond"
_G.SlashCmdList.FSO = function()
	ns.OpenSettings()
end
