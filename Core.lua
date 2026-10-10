--[[
  FiveSecondOverlay — subtle Classic 5-second-rule highlight on the player mana bar.

  Prefer EllesmereUI Resource Bars (ERB_PrimaryBar). Fall back to unit-frame Power,
  then Blizzard.

  The highlight starts when a mana spell successfully completes (or a channel
  begins), not when a cast-time spell starts.
]]

local ADDON_NAME, ns = ...

local FSR_DURATION = 5
local HOST_RECHECK_INTERVAL = 0.5

local driver = CreateFrame("Frame")
local overlay
local hostBar
local hostOuter
local lastSpend = 0
local fsrActive = false
local attachAttempts = 0
local attachTicker
local hostRecheckAt = 0
local hostAttached = false
local watchingForeignAddons = true

local GetTime = GetTime
local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue
local issecrettable = issecrettable
local canaccesstable = canaccesstable

local OnUpdate

local function Print(msg)
	print("|cffc4b5fdJoipov|r Five Second Overlay: " .. tostring(msg or ""))
end

ns.Print = Print

local function DB()
	return ns.db
end

local function SecretBlocked(value)
	return issecretvalue and issecretvalue(value) and not (canaccessvalue and canaccessvalue(value))
end

local function CanIndex(value)
	if value == nil or SecretBlocked(value) then
		return false
	end
	if issecrettable and issecrettable(value) and not (canaccesstable and canaccesstable(value)) then
		return false
	end
	return true
end

local function ReadableNumber(value)
	if type(value) ~= "number" or SecretBlocked(value) then
		return nil
	end
	return value
end

local function FrameUsable(frame)
	if not (frame and frame.GetWidth and frame.IsVisible) then
		return false
	end
	local width = frame:GetWidth()
	return width and width > 1 and frame:IsVisible()
end

local function IsManaPower()
	local powerType = UnitPowerType("player")
	if SecretBlocked(powerType) then
		return true
	end
	local mana = Enum and Enum.PowerType and Enum.PowerType.Mana
	if mana ~= nil then
		return powerType == mana
	end
	return powerType == 0
end

-- true / false / nil (nil = could not read cost — Forever secrets).
-- Only `true` arms the FSR (CQ-002: do not treat nil as a spend).
local function SpellCostsMana(spellID)
	if not spellID or spellID == 0 then
		return false
	end
	if SecretBlocked(spellID) then
		return nil
	end
	if not (C_Spell and C_Spell.GetSpellPowerCost) then
		return nil
	end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if not CanIndex(costs) then
		return nil
	end
	local manaType = Enum and Enum.PowerType and Enum.PowerType.Mana
	local sawReadable = false
	for i = 1, #costs do
		local entry = costs[i]
		if CanIndex(entry) then
			local costType = entry.type
			local cost = ReadableNumber(entry.cost)
			if cost ~= nil then
				sawReadable = true
				if cost > 0 and (manaType == nil or SecretBlocked(costType) or costType == manaType) then
					return true
				end
			elseif SecretBlocked(entry.cost) then
				return nil
			end
		end
	end
	if sawReadable then
		return false
	end
	return nil
end

-- Returns attachBar (fill / status bar), outerBar (for border raise).
local function ResolveHostBar()
	local erb = _G.ERB_PrimaryBar
	if FrameUsable(erb) then
		local attach = erb._sb
		if FrameUsable(attach) then
			return attach, erb
		end
		return erb, erb
	end

	local eui = _G.EllesmereUIUnitFrames_Player
	if eui and FrameUsable(eui.Power) then
		return eui.Power, eui.Power
	end

	if FrameUsable(_G.PlayerFrameManaBar) then
		return _G.PlayerFrameManaBar, _G.PlayerFrameManaBar
	end
	local pf = _G.PlayerFrame
	if pf then
		if FrameUsable(pf.manabar) then
			return pf.manabar, pf.manabar
		end
		if FrameUsable(pf.ManaBar) then
			return pf.ManaBar, pf.ManaBar
		end
	end

	return nil, nil
end

local function RaiseHostBorder()
	if hostOuter and hostOuter.RaiseBorderAbove and overlay then
		hostOuter:RaiseBorderAbove(overlay:GetFrameLevel(), false)
	end
end

local function ApplyAppearance()
	if not overlay then
		return
	end
	local db = DB()
	local r = (db and db.r) or 1
	local g = (db and db.g) or 1
	local b = (db and db.b) or 1
	local a = (db and db.a) or 0.35
	overlay.tex:SetColorTexture(r, g, b, a)
end

local function UpdateDriverScript()
	if fsrActive then
		driver:SetScript("OnUpdate", OnUpdate)
	else
		driver:SetScript("OnUpdate", nil)
	end
end

local function EnsureOverlay(bar, outer)
	outer = outer or bar
	if overlay and hostBar == bar and hostOuter == outer then
		overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
		RaiseHostBorder()
		return overlay
	end

	if overlay then
		overlay:Hide()
		overlay:SetParent(bar)
	else
		overlay = CreateFrame("Frame", "FiveSecondOverlayHighlight", bar)
		overlay:EnableMouse(false)
		local tex = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
		tex:SetAllPoints(overlay)
		tex:SetColorTexture(1, 1, 1, 1)
		overlay.tex = tex
	end

	hostBar = bar
	hostOuter = outer
	if overlay:GetParent() ~= bar then
		overlay:SetParent(bar)
	end

	overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
	RaiseHostBorder()

	ApplyAppearance()
	overlay:Hide()
	return overlay
end

local function StopFSR()
	fsrActive = false
	if overlay then
		overlay:Hide()
	end
end

local function LayoutOverlay(remaining)
	if not overlay or not hostBar then
		return
	end
	local db = DB()
	local inset = (db and db.inset) or 1
	if inset < 0 then
		inset = 0
	end
	local width = hostBar:GetWidth()
	if not width or width <= 0 then
		return
	end

	local frac = remaining / FSR_DURATION
	if frac < 0 then
		frac = 0
	elseif frac > 1 then
		frac = 1
	end

	local innerW = width - (inset * 2)
	if innerW < 1 then
		innerW = 1
	end
	local drawW = innerW * frac

	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", hostBar, "TOPLEFT", inset, -inset)
	overlay:SetPoint("BOTTOMLEFT", hostBar, "BOTTOMLEFT", inset, inset)
	overlay:SetWidth(math.max(drawW, 0.01))
	if drawW > 0.5 and frac > 0 then
		overlay:Show()
		RaiseHostBorder()
	else
		overlay:Hide()
	end
end

local function MarkHostAttached(ok)
	hostAttached = ok and true or false
	if hostAttached then
		watchingForeignAddons = false
	end
end

local function TryAttach()
	local bar, outer = ResolveHostBar()
	if bar then
		EnsureOverlay(bar, outer)
		attachAttempts = 0
		MarkHostAttached(true)
		return true
	end
	MarkHostAttached(false)
	return false
end

ns.TryAttach = TryAttach

local function EnsureHostForUpdate(now)
	if hostBar and FrameUsable(hostBar) then
		if now < hostRecheckAt then
			return true
		end
		hostRecheckAt = now + HOST_RECHECK_INTERVAL
		local bar, outer = ResolveHostBar()
		if bar and bar == hostBar then
			return true
		end
		if bar then
			EnsureOverlay(bar, outer)
			MarkHostAttached(true)
			return true
		end
		return false
	end

	local bar, outer = ResolveHostBar()
	if not bar then
		return false
	end
	EnsureOverlay(bar, outer)
	MarkHostAttached(true)
	hostRecheckAt = now + HOST_RECHECK_INTERVAL
	return true
end

OnUpdate = function()
	local db = DB()
	if not db or not db.enabled then
		StopFSR()
		driver:SetScript("OnUpdate", nil)
		return
	end

	local now = GetTime()
	if not EnsureHostForUpdate(now) then
		return
	end

	if fsrActive then
		if not IsManaPower() then
			StopFSR()
			UpdateDriverScript()
		else
			local remaining = FSR_DURATION - (now - lastSpend)
			if remaining <= 0 then
				StopFSR()
				UpdateDriverScript()
			else
				LayoutOverlay(remaining)
			end
		end
	end
end

local function StartOrReset()
	local db = DB()
	if not db or not db.enabled then
		return
	end
	if not IsManaPower() then
		return
	end

	local bar, outer = ResolveHostBar()
	if not bar then
		return
	end

	EnsureOverlay(bar, outer)
	MarkHostAttached(true)
	lastSpend = GetTime()
	fsrActive = true
	LayoutOverlay(FSR_DURATION)
	UpdateDriverScript()
end

ns.StartOrReset = StartOrReset
ns.StopOverlay = function()
	StopFSR()
	UpdateDriverScript()
end
ns.ApplyAppearance = ApplyAppearance
ns.IsActive = function()
	return fsrActive
end

local function IsWandOrAutoRepeat(spellID)
	if spellID and IsAutoRepeatSpell and IsAutoRepeatSpell(spellID) then
		return true
	end
	if spellID and C_Spell and C_Spell.GetSpellName then
		local name = C_Spell.GetSpellName(spellID)
		if type(name) == "string" and not SecretBlocked(name) then
			if name == "Shoot"
				or name == "Schießen"
				or name == "Tir"
				or name == "Disparo"
				or name == "Tiro"
				or name == "射击"
				or name == "射擊" then
				return true
			end
		end
	end
	return false
end

local function OnPlayerCast(_, event, unit, _, spellID)
	if unit ~= "player" then
		return
	end
	if event ~= "UNIT_SPELLCAST_SUCCEEDED" and event ~= "UNIT_SPELLCAST_CHANNEL_START" then
		return
	end

	if IsWandOrAutoRepeat(spellID) then
		return
	end

	if SpellCostsMana(spellID) == true then
		StartOrReset()
	end
end

local function ScheduleAttachRetries()
	if hostAttached and hostBar and FrameUsable(hostBar) then
		return
	end
	attachAttempts = 0
	if attachTicker then
		attachTicker:Cancel()
		attachTicker = nil
	end
	if not C_Timer or not C_Timer.NewTicker then
		TryAttach()
		return
	end
	attachTicker = C_Timer.NewTicker(0.5, function()
		attachAttempts = attachAttempts + 1
		if TryAttach() or attachAttempts >= 30 then
			if attachTicker then
				attachTicker:Cancel()
				attachTicker = nil
			end
		end
	end)
end

local function ShouldReattachAddon(name)
	return name == "EllesmereUIResourceBars"
		or name == "EllesmereUIUnitFrames"
		or name == "EllesmereUI"
end

local function OnEnterWorld(isLogin)
	if isLogin then
		Print("Type |cffffffff/fso|r to open settings.")
	end
	TryAttach()
	ScheduleAttachRetries()
	if ns.CreateMinimapButton then
		ns.CreateMinimapButton()
	end
	if not DB().enabled then
		StopFSR()
		UpdateDriverScript()
	end
end

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name == ADDON_NAME then
		_G.FiveSecondOverlayDB = ns.LoadDB(_G.FiveSecondOverlayDB)
		ns.db = _G.FiveSecondOverlayDB
		if ns.InitOptions then
			ns.InitOptions()
		end
		return
	end
	if watchingForeignAddons and ShouldReattachAddon(name) then
		TryAttach()
		ScheduleAttachRetries()
	end
end

function handlers.PLAYER_LOGIN()
	OnEnterWorld(true)
end

function handlers.PLAYER_ENTERING_WORLD()
	OnEnterWorld(false)
end

function handlers.UNIT_DISPLAYPOWER()
	if not IsManaPower() then
		StopFSR()
		UpdateDriverScript()
	end
end

function handlers.UNIT_SPELLCAST_SUCCEEDED(unit, ...)
	OnPlayerCast(nil, "UNIT_SPELLCAST_SUCCEEDED", unit, ...)
end

function handlers.UNIT_SPELLCAST_CHANNEL_START(unit, ...)
	OnPlayerCast(nil, "UNIT_SPELLCAST_CHANNEL_START", unit, ...)
end

driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
driver:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
driver:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
driver:SetScript("OnEvent", function(_, event, arg1, ...)
	local handler = handlers[event]
	if handler then
		handler(arg1, ...)
	end
end)

function ns.SetEnabled(on)
	local db = DB()
	if not db then
		return
	end
	db.enabled = on and true or false
	if not db.enabled then
		StopFSR()
		UpdateDriverScript()
	end
end

function ns.Refresh()
	ApplyAppearance()
	if fsrActive then
		local remaining = FSR_DURATION - (GetTime() - lastSpend)
		if remaining > 0 then
			LayoutOverlay(remaining)
		else
			StopFSR()
			UpdateDriverScript()
		end
	end
end
