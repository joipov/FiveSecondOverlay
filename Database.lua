local _, ns = ...

-- SavedVariables: defaults, migrations, validation.
-- Plain Lua so logic stays testable without a client.

local DB_VERSION = 7

-- Scalar defaults only. Tables are constructed fresh in EnsureTables.
-- The highlight stays white and shrinks from the right toward the left.
local defaults = {
	enabled = true,
	showMinimapButton = true,
	minimapAngle = 220,
	a = 0.35,
	inset = 1,
	r = 1,
	g = 1,
	b = 1,
}

local function ClampNumber(value, lo, hi, fallback)
	if type(value) ~= "number" then
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
end

local function CopyDefaults(db)
	for key, value in pairs(defaults) do
		if type(db[key]) ~= type(value) then
			db[key] = value
		end
	end
	EnsureTables(db)
	return db
end

local function Validate(db)
	db.enabled = db.enabled ~= false
	db.showMinimapButton = db.showMinimapButton == true
	db.a = ClampNumber(db.a, 0.05, 0.60, defaults.a)
	db.r = ClampNumber(db.r, 0, 1, defaults.r)
	db.g = ClampNumber(db.g, 0, 1, defaults.g)
	db.b = ClampNumber(db.b, 0, 1, defaults.b)
	db.inset = ClampNumber(db.inset, 0, 4, defaults.inset)
	db.inset = math.floor(db.inset + 0.5)
	db.minimapAngle = ClampNumber(db.minimapAngle, -360, 360, defaults.minimapAngle)
	EnsureTables(db)
end

local function MigrateDB(db)
	local version = type(db.version) == "number" and db.version or 0
	if version < 2 then
		-- Former one-shot: bump very faint default alpha once.
		if db.a == 0.22 then
			db.a = defaults.a
		end
		-- Those builds stored color but never applied it. Drop it so later
		-- defaults apply instead of a stale unused value.
		db.r = nil
		db.g = nil
		db.b = nil
	end
	if version < 3 then
		-- Highlight inside borders: previous default inset was 0 (covered 1px outlines).
		if db.inset == nil or db.inset == 0 then
			db.inset = defaults.inset
		end
	end
	if version < 4 then
		db.regenTimer = nil
	end
	if version < 6 then
		-- Version 5 defaulted to light blue. White is the default again.
		-- A color the user picked is left alone.
		local oldBlue = type(db.r) == "number" and type(db.g) == "number" and type(db.b) == "number"
			and math.abs(db.r - 0.70) < 0.02
			and math.abs(db.g - 0.88) < 0.02
			and math.abs(db.b - 1) < 0.02
		if db.r == nil or oldBlue then
			db.r = nil
			db.g = nil
			db.b = nil
		end
	end
	if version < 7 then
		-- The button used to default off, and that false was written into
		-- saved variables. Turn it on once. A later choice stays put.
		db.showMinimapButton = true
	end
	db.version = DB_VERSION
end

function ns.LoadDB(saved)
	local db = type(saved) == "table" and saved or {}
	MigrateDB(db)
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.DB_DEFAULTS = defaults
ns.DB_VERSION = DB_VERSION
ns.defaults = defaults
