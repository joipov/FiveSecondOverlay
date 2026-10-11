local _, ns = ...

-- Saved variables: defaults, migrations, validation. Plain Lua, so the tests
-- can load it without a client.

local DB_VERSION = 8
local MINIMAP_POS = 220

-- Scalars only. Tables are built fresh in EnsureTables.
local defaults = {
	enabled = true,
	showMinimapButton = true,
	a = 0.35,
	inset = 1,
	r = 1,
	g = 1,
	b = 1,
}

local function ClampNumber(value, lo, hi, fallback)
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	if value < lo then
		return lo
	end
	if value > hi then
		return hi
	end
	return value
end

local function EnsureTables(db)
	if type(db.minimapIcon) ~= "table" then
		db.minimapIcon = {}
	end
	db.minimapIcon.minimapPos = ClampNumber(db.minimapIcon.minimapPos, 0, 360, MINIMAP_POS)
end

local function CopyDefaults(db)
	for key, value in pairs(defaults) do
		if type(db[key]) ~= type(value) then
			db[key] = value
		end
	end
	EnsureTables(db)
end

local function Validate(db)
	db.a = ClampNumber(db.a, 0.05, 0.60, defaults.a)
	db.r = ClampNumber(db.r, 0, 1, defaults.r)
	db.g = ClampNumber(db.g, 0, 1, defaults.g)
	db.b = ClampNumber(db.b, 0, 1, defaults.b)
	db.inset = math.floor(ClampNumber(db.inset, 0, 4, defaults.inset) + 0.5)
end

local function Near(value, target)
	return type(value) == "number" and math.abs(value - target) < 0.02
end

local function MigrateDB(db)
	local version = type(db.version) == "number" and db.version or 0
	if version < 2 then
		-- Bump the very faint first default once. Those builds stored a color
		-- they never drew, so drop it.
		if db.a == 0.22 then
			db.a = defaults.a
		end
		db.r, db.g, db.b = nil, nil, nil
	end
	if version < 3 then
		-- The old default inset of 0 covered the bar's 1 px border.
		if db.inset == nil or db.inset == 0 then
			db.inset = defaults.inset
		end
	end
	if version < 4 then
		db.regenTimer = nil
	end
	if version < 6 then
		-- Version 5 defaulted to light blue. White is the default again; a
		-- color the user picked stays.
		if db.r == nil or (Near(db.r, 0.70) and Near(db.g, 0.88) and Near(db.b, 1)) then
			db.r, db.g, db.b = nil, nil, nil
		end
	end
	if version < 7 then
		-- The button used to default off and that false was saved. Turn it on
		-- once; a later choice stays.
		db.showMinimapButton = true
	end
	if version < 8 then
		-- The built-in button kept its own angle. LibDBIcon's table holds it now.
		if type(db.minimapIcon) ~= "table" then
			db.minimapIcon = {}
		end
		if type(db.minimapIcon.minimapPos) ~= "number" and type(db.minimapAngle) == "number" then
			db.minimapIcon.minimapPos = db.minimapAngle % 360
		end
		db.minimapAngle = nil
	end
	db.version = DB_VERSION
end

function ns.LoadDB(saved)
	ns.firstRun = type(saved) ~= "table"
	local db = ns.firstRun and {} or saved
	MigrateDB(db)
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.defaults = defaults
ns.DB_VERSION = DB_VERSION
