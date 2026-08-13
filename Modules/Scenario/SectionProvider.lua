local _, Addon = ...
local L = Addon.L

local ENTRY_KIND = "scenario"

--- Above everything else: a scenario is what the player is doing right now,
--- and the quests can wait until they are out of it.

local SECONDS_PER_MINUTE = 60
local REMAINING_LABEL = Addon.L.SCENARIO_REMAINING
local OVERTIME_LABEL = Addon.L.SCENARIO_OVERTIME
local KEYSTONE_LABEL = Addon.L.SCENARIO_KEYSTONE
local DEATHS_LABEL = Addon.L.SCENARIO_DEATHS
local AFFIXES_SEPARATOR = ", "

--- SectionProvider for scenarios, including Mythic+ dungeons.
---@class ScenarioSectionProvider : SectionProvider
local ScenarioSectionProvider = {}
ScenarioSectionProvider.__index = ScenarioSectionProvider

---@return ScenarioSectionProvider
function ScenarioSectionProvider.New()
	return setmetatable({}, ScenarioSectionProvider)
end

--- Weighted and pre-formatted criteria already read as sentences; the rest are
--- bare counts that need the numbers put in front of them.
---@param criteria table
---@return string
local function FormatCriteria(criteria)
	if criteria.isWeightedProgress or criteria.isFormatted then
		return criteria.description
	end

	return ("%d/%d %s"):format(criteria.quantity, criteria.totalQuantity, criteria.description)
end

---@param objectives TrackerObjective[]
local function AddCriteria(objectives)
	local _, _, numCriteria = C_Scenario.GetStepInfo()

	if not C_Scenario.ShouldShowCriteria() then
		return
	end

	for index = 1, numCriteria or 0 do
		local criteria = C_ScenarioInfo.GetCriteriaInfo(index)

		if criteria then
			table.insert(objectives, {
				text = FormatCriteria(criteria),
				isComplete = criteria.completed == true,
			})
		end
	end
end

---@param affixIDs number[]?
---@return string?
local function FormatAffixes(affixIDs)
	local names = {}

	for _, affixID in ipairs(affixIDs or {}) do
		local name = C_ChallengeMode.GetAffixInfo(affixID)
		if name then
			table.insert(names, name)
		end
	end

	if #names == 0 then
		return nil
	end

	return table.concat(names, AFFIXES_SEPARATOR)
end

--- The keystone level, the affixes and the death count are what a Mythic+ run
--- is judged on, so they belong beside the objectives rather than in a separate
--- panel the player has to go looking for.
--- The elapsed time lives with the world state timers, not with the challenge
--- API, and has to be picked out of them by type.
---@return number?
local function ReadElapsedSeconds()
	for _, timerID in ipairs({ GetWorldElapsedTimers() }) do
		local _, elapsed, timerType = GetWorldElapsedTime(timerID)

		if timerType == Enum.WorldElapsedTimerTypes.ChallengeMode then
			return elapsed
		end
	end

	return nil
end

---@param seconds number
---@return string
local function FormatClock(seconds)
	return ("%d:%02d"):format(math.floor(seconds / SECONDS_PER_MINUTE), seconds % SECONDS_PER_MINUTE)
end

---@param objectives TrackerObjective[]
---@param mapID number
local function AddTimer(objectives, mapID)
	local elapsed = ReadElapsedSeconds()
	if not elapsed then
		return
	end

	local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)

	if not timeLimit or timeLimit == 0 then
		table.insert(objectives, { text = FormatClock(elapsed), isComplete = false })
		return
	end

	-- Over the limit the run is no longer timed, so the clock keeps counting up
	-- rather than showing a negative remainder.
	local remaining = timeLimit - elapsed
	local text = remaining >= 0 and REMAINING_LABEL:format(FormatClock(remaining))
		or OVERTIME_LABEL:format(FormatClock(elapsed))

	table.insert(objectives, { text = text, isComplete = false })
end

---@param objectives TrackerObjective[]
local function AddChallengeInfo(objectives)
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()

	if not mapID then
		return
	end

	AddTimer(objectives, mapID)

	local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()

	if level and level > 0 then
		table.insert(objectives, { text = KEYSTONE_LABEL:format(level), isComplete = false })
	end

	local affixes = FormatAffixes(affixIDs)
	if affixes then
		table.insert(objectives, { text = affixes, isComplete = false })
	end

	table.insert(objectives, {
		text = DEATHS_LABEL:format(C_ChallengeMode.GetDeathCount() or 0),
		isComplete = false,
	})
end

---@param stageName string
---@param currentStage number
---@param numStages number
---@return string
local function FormatTitle(stageName, currentStage, numStages)
	if numStages <= 1 then
		return stageName
	end

	return ("%s (%d/%d)"):format(stageName, currentStage, numStages)
end

---@return TrackerSection[]
function ScenarioSectionProvider:Collect()
	local scenarioName, currentStage, numStages = C_Scenario.GetInfo()

	-- No scenario running: the API answers with nothing rather than an error.
	if not scenarioName or not numStages or numStages == 0 then
		return {}
	end

	local stageName, stageDescription = C_Scenario.GetStepInfo()
	local objectives = {}

	if stageDescription and stageDescription ~= "" then
		table.insert(objectives, { text = stageDescription, isComplete = false })
	end

	AddCriteria(objectives)
	AddChallengeInfo(objectives)

	local isDungeon = C_ChallengeMode.GetActiveChallengeMapID() ~= nil

	return {
		{
			id = "scenario",
			title = isDungeon and TRACKER_HEADER_DUNGEON or TRACKER_HEADER_SCENARIO,
			order = Addon.SectionOrder.scenario,
			entries = {
				{
					id = scenarioName,
					kind = ENTRY_KIND,
					title = FormatTitle(stageName or scenarioName, currentStage, numStages),
					objectives = objectives,
					isComplete = false,
					canFindGroup = false,
					-- Nothing to click: the player is already inside it.
					pinStyle = "none",
				},
			},
		},
	}
end

Addon.ScenarioSectionProvider = ScenarioSectionProvider
