--[[
  Five Second Overlay — a subtle 5-second-rule highlight on the player mana bar.

  The highlight starts when a mana spell finishes, or when a channel begins. A
  cast that is still winding up does not start it. It shrinks from the right
  toward the left over five seconds, then clears.

  Host, in order: a custom resource bar, a custom unit-frame power bar, then the
  default player mana bar.
]]

local ADDON_NAME, ns = ...

local FSR_DURATION = 5
local HOST_RECHECK_INTERVAL = 0.5

local GetTime = GetTime
local C_Timer = C_Timer
local C_Spell = C_Spell

local frame = CreateFrame("Frame")
local overlay
local hostBar
local hostOuter
local lastSpend = 0
local active = false
local attachTicker
local hostRecheckAt = 0
local hostAttached = false
local watchingForeignAddons = true
local playerUsesMana = true
local placedBar
local placedInset

local function Print(message)
	print("|cff8b5cf6Joipov|r Five Second Overlay: " .. tostring(message or ""))
end

ns.Print = Print

function ns.Debug(...)
	if not (ns.db and ns.db.debug) then
		return
	end
	local count = select("#", ...)
	local parts = {}
	for i = 1, count do
		parts[i] = tostring(select(i, ...))
	end
	Print(table.concat(parts, " "))
end

-- Name and version come from the TOC, so they never drift.
function ns.Welcome()
	local title = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Five Second Overlay"
	local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
	print(string.format("|cff8b5cf6Joipov|r %s (|cff22d3eev%s|r). Type |cffffffff/fso|r to open settings.", title, version))
end

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function ReadableNumber(value)
	if SecretBlocked(value) then
		return nil
	end
	if type(value) ~= "number" then
		return nil
	end
	return value
end

local function FrameUsable(host)
	if not (host and host.GetWidth and host.IsVisible) then
		return false
	end
	local width = host:GetWidth()
	return width > 1 and host:IsVisible()
end

local function ReadManaPower()
	local powerType = UnitPowerType("player")
	if SecretBlocked(powerType) then
		return true
	end
	return powerType == Enum.PowerType.Mana
end

local function RefreshManaPower()
	playerUsesMana = ReadManaPower()
end

-- true, false, or nil when the cost cannot be read (Forever secrets).
-- Only true arms the highlight; nil is not treated as a spend.
local function SpellCostsMana(spellID)
	if not spellID or spellID == 0 or SecretBlocked(spellID) then
		return nil
	end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if SecretBlocked(costs) or type(costs) ~= "table" then
		return nil
	end
	local mana = Enum.PowerType.Mana
	for i = 1, #costs do
		local entry = costs[i]
		if not SecretBlocked(entry) then
			local cost = ReadableNumber(entry.cost)
			if cost then
				if cost > 0 and entry.type == mana then
					return true
				end
			elseif SecretBlocked(entry.cost) then
				return nil
			end
		end
	end
	return false
end

-- Returns the bar to attach to, and the bar whose border must be raised.
local function ResolveHostBar()
	local erb = _G.ERB_PrimaryBar
	if FrameUsable(erb) then
		if FrameUsable(erb._sb) then
			return erb._sb, erb
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
	local player = _G.PlayerFrame
	if player then
		if FrameUsable(player.manabar) then
			return player.manabar, player.manabar
		end
		if FrameUsable(player.ManaBar) then
			return player.ManaBar, player.ManaBar
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
	local db = ns.db
	overlay.tex:SetColorTexture(db.r, db.g, db.b, db.a)
end

local function Layout(remaining)
	local db = ns.db
	local inset = db.inset
	local width = hostBar:GetWidth()
	if width <= 0 then
		return
	end
	local frac = remaining / FSR_DURATION
	if frac < 0 then
		frac = 0
	elseif frac > 1 then
		frac = 1
	end
	local innerWidth = width - inset * 2
	local drawWidth = innerWidth * frac

	if placedBar ~= hostBar or placedInset ~= inset then
		overlay:ClearAllPoints()
		overlay:SetPoint("TOPLEFT", hostBar, "TOPLEFT", inset, -inset)
		overlay:SetPoint("BOTTOMLEFT", hostBar, "BOTTOMLEFT", inset, inset)
		placedBar = hostBar
		placedInset = inset
		RaiseHostBorder()
	end
	overlay:SetWidth(drawWidth > 0.5 and drawWidth or 0.01)
	local show = frac > 0 and drawWidth > 0.5
	if overlay:IsShown() ~= show then
		overlay:SetShown(show)
		if show then
			RaiseHostBorder()
		end
	end
end

local function Stop()
	active = false
	if overlay then
		overlay:Hide()
	end
	frame:SetScript("OnUpdate", nil)
end

local function EnsureOverlay(bar, outer)
	outer = outer or bar
	if overlay and hostBar == bar and hostOuter == outer then
		return
	end
	if not overlay then
		overlay = CreateFrame("Frame", "FiveSecondOverlayHighlight", bar)
		overlay:EnableMouse(false)
		local texture = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
		texture:SetAllPoints(overlay)
		texture:SetColorTexture(1, 1, 1, 1)
		overlay.tex = texture
	elseif overlay:GetParent() ~= bar then
		overlay:SetParent(bar)
	end
	hostBar = bar
	hostOuter = outer
	placedBar = nil
	overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
	ApplyAppearance()
	overlay:Hide()
end

local function MarkAttached()
	hostAttached = true
	watchingForeignAddons = false
end

local function TryAttach()
	local bar, outer = ResolveHostBar()
	if not bar then
		return false
	end
	EnsureOverlay(bar, outer)
	MarkAttached()
	return true
end

local function EnsureHost(now)
	if hostBar and FrameUsable(hostBar) then
		if now < hostRecheckAt then
			return true
		end
		hostRecheckAt = now + HOST_RECHECK_INTERVAL
		local bar, outer = ResolveHostBar()
		if bar and bar ~= hostBar then
			EnsureOverlay(bar, outer)
		end
		return bar ~= nil
	end
	local bar, outer = ResolveHostBar()
	if not bar then
		return false
	end
	EnsureOverlay(bar, outer)
	MarkAttached()
	hostRecheckAt = now + HOST_RECHECK_INTERVAL
	return true
end

local function OnUpdate()
	if not ns.db.enabled then
		Stop()
		return
	end
	local now = GetTime()
	if not EnsureHost(now) then
		return
	end
	if not active then
		return
	end
	if not playerUsesMana then
		Stop()
		return
	end
	local remaining = FSR_DURATION - (now - lastSpend)
	if remaining <= 0 then
		Stop()
		return
	end
	Layout(remaining)
end

local function StartOrReset()
	if not ns.db.enabled or not playerUsesMana then
		return
	end
	local bar, outer = ResolveHostBar()
	if not bar then
		return
	end
	EnsureOverlay(bar, outer)
	MarkAttached()
	lastSpend = GetTime()
	active = true
	Layout(FSR_DURATION)
	frame:SetScript("OnUpdate", OnUpdate)
end

local function ScheduleAttachRetries()
	if hostAttached and hostBar and FrameUsable(hostBar) then
		return
	end
	if attachTicker then
		attachTicker:Cancel()
		attachTicker = nil
	end
	-- The host bar may load after us; retry for a few seconds.
	local attempts = 0
	attachTicker = C_Timer.NewTicker(0.5, function()
		attempts = attempts + 1
		if TryAttach() or attempts >= 30 then
			attachTicker:Cancel()
			attachTicker = nil
		end
	end)
end

local function ShouldReattach(name)
	return name == "EllesmereUIResourceBars"
		or name == "EllesmereUIUnitFrames"
		or name == "EllesmereUI"
end

local function OnPlayerCast(unit, spellID)
	if unit ~= "player" then
		return
	end
	if C_Spell.IsAutoRepeatSpell(spellID) then
		return
	end
	if SpellCostsMana(spellID) == true then
		StartOrReset()
	end
end

local function OnEnterWorld(isLogin)
	RefreshManaPower()
	if isLogin then
		ns.Welcome()
	end
	TryAttach()
	ScheduleAttachRetries()
	ns.CreateMinimapButton()
	if not ns.db.enabled then
		Stop()
	end
end

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name == ADDON_NAME then
		_G.FiveSecondOverlayDB = ns.LoadDB(_G.FiveSecondOverlayDB)
		ns.db = _G.FiveSecondOverlayDB
		ns.InitOptions()
		return
	end
	if watchingForeignAddons and ShouldReattach(name) then
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

handlers.UNIT_DISPLAYPOWER = function()
	RefreshManaPower()
	if not playerUsesMana then
		Stop()
	end
end

handlers.UNIT_SPELLCAST_SUCCEEDED = function(unit, _, spellID)
	OnPlayerCast(unit, spellID)
end

handlers.UNIT_SPELLCAST_CHANNEL_START = function(unit, _, spellID)
	OnPlayerCast(unit, spellID)
end

frame:SetScript("OnEvent", function(_, event, ...)
	handlers[event](...)
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")

function ns.SetEnabled()
	if not ns.db.enabled then
		Stop()
	end
end

function ns.Refresh()
	ApplyAppearance()
	if active then
		local remaining = FSR_DURATION - (GetTime() - lastSpend)
		if remaining > 0 then
			Layout(remaining)
		else
			Stop()
		end
	end
end
