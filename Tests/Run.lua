--- Roda as suítes do Core.
---
--- Uso: lua Tests/Run.lua [filtro]
--- O filtro é comparado com o caminho da suíte, então `lua Tests/Run.lua Tracker`
--- roda só as de Tests/Core/Tracker/.

local Harness = dofile("Tests/Harness.lua")
local Support = dofile("Tests/Support.lua")

--- Espelha a estrutura do projeto, na mesma ordem em que as camadas dependem
--- umas das outras.
local SUITES = {
	"Core/HexColor",
	"Core/ToggleSet",
	"Core/Profiles",
	"Core/Preferences/Catalog",
	"Core/Preferences/Choices",
	"Core/Preferences/Store",
	"Core/Filtering/Filters",
	"Core/Filtering/Filtering",
	"Core/Tracker/SectionOrder",
	"Core/Tracker/Content",
	"Core/Tracker/Display",
	"Core/Tracker/CompletionWatcher",
	"Core/Tracker/AchievementCategories",
	"Core/Commands",
	"Core/Integration/WaypointSync",
	"Locales",
}

local filter = ...
local Addon = Harness.LoadCore()
local ran = 0

for _, name in ipairs(SUITES) do
	if not filter or name:find(filter, 1, true) then
		local path = "Tests/" .. name .. ".lua"
		local chunk, failure = loadfile(path)

		if not chunk then
			error(("could not load %s: %s"):format(path, failure))
		end

		chunk()(Addon, Harness, Support, Harness)
		ran = ran + 1
	end
end

if ran == 0 then
	print(("nenhuma suite casa com %q"):format(tostring(filter)))
	os.exit(1)
end

os.exit(Harness.Report())
