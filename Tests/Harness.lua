--- Loads Core/ the way the game does and reports what passed.
---
--- Plain Lua on purpose: Core has no dependencies, so its tests should not
--- either. Any Lua binary runs this, with nothing to install first.

local ADDON_NAME = "AuraQuestor"

--- Locale.lua asks the client which locale to keep. Outside the game there is
--- no client, so the harness answers for it and the tests read enUS.
GetLocale = GetLocale or function()
	return "enUS"
end

local LOCALE_FILES = {
	"Locale",
	"enUS",
	"ptBR",
}

--- The order the .toc uses, which matters because a few files read each other
--- at file scope.
local CORE_FILES = {
	"HexColor",
	"WowheadLink",
	"ToggleSet",
	"Profiles",
	"LegacyDatabase",
	"QuestRecency",
	"Preferences/Keys",
	"Preferences/FontFlags",
	"Preferences/SortModes",
	"Preferences/SoundChannels",
	"Preferences/ProgressBarStyles",
	"Preferences/WorldQuestScopes",
	"Preferences/Catalog",
	"Preferences/Store",
	"Preferences/Lookup",
	"Preferences/Bounds",
	"Filtering/FilterIds",
	"Filtering/Filters",
	"Filtering/Filtering",
	"Tracker/Place",
	"Tracker/SectionOrder",
	"Tracker/SectionArrangement",
	"Tracker/ChallengeCollapse",
	"Tracker/Content",
	"Tracker/Display",
	"Tracker/CompletionWatcher",
	"Tracker/AchievementCategories",
	"Commands/Status",
	"Commands/Help",
	"Commands/Startup",
	"Integration/WaypointSync",
}

--- Arquivos de UI/ sem API do jogo no escopo do arquivo.
local UI_FILES = {
	"Entry/Text",
}

--- Arquivos de Options/ sem nenhuma API do jogo, carregáveis por Lua puro.
--- Um global do cliente tocado aqui estoura como nil no interpretador.
local OPTIONS_FILES = {
	"Components/Theme",
	"Components/Schematic",
	"SectionOrderCard",
}

local Harness = {}

---@return table addon The namespace Core built.
function Harness.LoadCore()
	local addon = {}

	---@param path string
	local function Load(path)
		local chunk, failure = loadfile(path)

		if not chunk then
			error(("could not load %s: %s"):format(path, failure))
		end

		chunk(ADDON_NAME, addon)
	end

	for _, name in ipairs(LOCALE_FILES) do
		Load("Locales/" .. name .. ".lua")
	end

	for _, name in ipairs(CORE_FILES) do
		Load("Source/Core/" .. name .. ".lua")
	end

	for _, name in ipairs(UI_FILES) do
		Load("Source/UI/" .. name .. ".lua")
	end

	for _, name in ipairs(OPTIONS_FILES) do
		Load("Source/Options/" .. name .. ".lua")
	end

	return addon
end

local passed = 0
local failures = {}
local currentSuite = "?"

---@param name string
---@param body fun()
function Harness.Suite(name, body)
	currentSuite = name
	body()
end

---@param name string
---@param body fun()
function Harness.Test(name, body)
	local ok, failure = pcall(body)

	if ok then
		passed = passed + 1
		return
	end

	table.insert(failures, ("%s / %s\n    %s"):format(currentSuite, name, failure))
end

---@param condition any
---@param message string
function Harness.IsTrue(condition, message)
	if not condition then
		error(message or "expected true", 2)
	end
end

---@param actual any
---@param expected any
---@param message string?
function Harness.Equals(actual, expected, message)
	if actual ~= expected then
		error(
			("%sexpected %s, got %s"):format(
				message and (message .. ": ") or "",
				tostring(expected),
				tostring(actual)
			),
			2
		)
	end
end

---@param actual number
---@param expected number
---@param tolerance number
---@param message string?
function Harness.Near(actual, expected, tolerance, message)
	if math.abs(actual - expected) > tolerance then
		error(
			("%sexpected %s within %s of %s"):format(
				message and (message .. ": ") or "",
				tostring(actual),
				tostring(tolerance),
				tostring(expected)
			),
			2
		)
	end
end

--- Every Lua file the game loads, read off the .toc so the list cannot drift
--- from what actually ships.
---@return string[]
function Harness.RuntimeFiles()
	local paths = {}
	local toc = assert(io.open("AuraQuestor.toc", "r"))

	for line in toc:lines() do
		local path = line:match("^%s*(%S.-%.lua)%s*$")

		if path and not path:match("^Libs") then
			table.insert(paths, (path:gsub("\\", "/")))
		end
	end

	toc:close()

	return paths
end

---@return number exitCode
function Harness.Report()
	if #failures == 0 then
		print(("%d testes, todos passaram"):format(passed))
		return 0
	end

	print(("%d passaram, %d falharam"):format(passed, #failures))

	for _, failure in ipairs(failures) do
		print("  " .. failure)
	end

	return 1
end

return Harness
