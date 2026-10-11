-- Unit tests for the pure parts of Five Second Overlay.
--   luajit tests/run.lua
--   lua5.1 tests/run.lua
-- Files that create frames (Core.lua, Options.lua, MinimapButton.lua) are not
-- loaded. Database.lua is plain Lua.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\]") or "."

local ns = {}
local function load(file)
	local chunk, err = loadfile(root .. "/" .. file)
	assert(chunk, err)
	chunk("FiveSecondOverlay", ns)
end

load("Database.lua")

local passed, failed = 0, 0

local function eq(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

test("LoadDB fills defaults", function()
	local db = ns.LoadDB(nil)
	eq(db.enabled, true, "enabled")
	eq(db.showMinimapButton, true, "showMinimapButton")
	eq(db.a, 0.35, "a")
	eq(db.inset, 1, "inset")
	eq(db.r, 1, "r")
	eq(db.g, 1, "g")
	eq(db.b, 1, "b")
	eq(db.version, ns.DB_VERSION, "version")
	eq(type(db.minimapIcon), "table", "minimapIcon")
end)

test("LoadDB keeps an explicit disabled state", function()
	local db = ns.LoadDB({ enabled = false })
	eq(db.enabled, false)
end)

test("LoadDB clamps opacity and inset", function()
	local db = ns.LoadDB({ a = 2, inset = 9 })
	eq(db.a, 0.60, "a")
	eq(db.inset, 4, "inset")
end)

test("LoadDB migrates the old faint alpha and stale color", function()
	local db = ns.LoadDB({ version = 1, a = 0.22, r = 0.5, g = 0.5, b = 0.5 })
	eq(db.a, 0.35, "a")
	eq(db.r, 1, "r")
	eq(db.g, 1, "g")
	eq(db.b, 1, "b")
end)

test("LoadDB turns the minimap button on once for old saves", function()
	local db = ns.LoadDB({ version = 6, showMinimapButton = false })
	eq(db.showMinimapButton, true)
end)

test("LoadDB keeps a current minimap choice", function()
	local db = ns.LoadDB({ version = ns.DB_VERSION, showMinimapButton = false })
	eq(db.showMinimapButton, false)
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
