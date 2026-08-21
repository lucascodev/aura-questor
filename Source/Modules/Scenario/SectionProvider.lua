local _, Addon = ...

local ENTRY_KIND = "scenario"

--- Above everything else: a scenario is what the player is doing right now.

local SECONDS_PER_MINUTE = 60
local REMAINING_LABEL = Addon.L.SCENARIO_REMAINING
local OVERTIME_LABEL = Addon.L.SCENARIO_OVERTIME
local KEYSTONE_LABEL = Addon.L.SCENARIO_KEYSTONE
local DEATHS_LABEL = Addon.L.SCENARIO_DEATHS
local AFFIXES_SEPARATOR = ", "
local DUNGEON_INSTANCE_TYPE = "party"
local WIDGET_SET_RETURN = 12
local TEXTURE_KIT_RETURN = 12
local DELVE_WIDGET_TYPE = Enum.UIWidgetVisualizationType
	and Enum.UIWidgetVisualizationType.ScenarioHeaderDelves
local DEFAULT_TEXTURE_KIT = "evergreen-scenario"
local HEADER_ATLAS_SUFFIX = "-trackerheader"
local FALLBACK_HEADER_ATLAS = "ScenarioTrackerToast"

--- SectionProvider for scenarios, including Mythic+ dungeons.
---@class ScenarioSectionProvider : SectionProvider
local ScenarioSectionProvider = {}
ScenarioSectionProvider.__index = ScenarioSectionProvider

---@return ScenarioSectionProvider
function ScenarioSectionProvider.New()
	return setmetatable({}, ScenarioSectionProvider)
end

--- Pre-formatted criteria already read as sentences; the rest are bare counts
--- that need the numbers put in front of them.
---@param criteria table
---@return string
local function FormatCriteria(criteria)
	if criteria.isFormatted then
		return criteria.description
	end

	return ("%d/%d %s"):format(criteria.quantity, criteria.totalQuantity, criteria.description)
end

--- Weighted progress is a share of the whole: the quantity is already the
--- percentage, and it belongs in a bar.
---@param criteria table
---@return TrackerObjective
local function AsObjective(criteria)
	if criteria.isWeightedProgress then
		return {
			text = criteria.description,
			percent = criteria.quantity,
			isComplete = criteria.completed == true,
		}
	end

	return { text = FormatCriteria(criteria), isComplete = criteria.completed == true }
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
			table.insert(objectives, AsObjective(criteria))
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

--- Each scenario declares its own art kit and the block background follows it
--- by name. When the atlas is missing on that client the card falls back to the
--- plain box instead of disappearing.
---@return string?
local function ReadHeaderAtlas()
	local textureKit = select(TEXTURE_KIT_RETURN, C_Scenario.GetInfo()) or DEFAULT_TEXTURE_KIT

	local candidates = {
		textureKit .. HEADER_ATLAS_SUFFIX,
		DEFAULT_TEXTURE_KIT .. HEADER_ATLAS_SUFFIX,
		FALLBACK_HEADER_ATLAS,
	}

	for _, atlas in ipairs(candidates) do
		if C_Texture.GetAtlasInfo(atlas) then
			return atlas
		end
	end

	return nil
end

--- Mythic+ is no test: a normal dungeon is a dungeon too, and only the instance
--- type tells it from an outdoor scenario.
---@return boolean
local function IsInDungeon()
	local _, instanceType = IsInInstance()

	return instanceType == DUNGEON_INSTANCE_TYPE
end

---@param stageName string
---@param currentStage number
---@param numStages number
---@return string
local function FormatStage(stageName, currentStage, numStages)
	if numStages <= 1 then
		return stageName
	end

	return ("%s (%d/%d)"):format(stageName, currentStage, numStages)
end

--- The step can publish a widget set: the wave timer, the delve header with
--- tier, lives and modifiers. When it exists the game draws that block itself.
---@return number?
---@return boolean isDelve
local function ReadWidgetSet()
	local widgetSetID = select(WIDGET_SET_RETURN, C_Scenario.GetStepInfo())

	if not widgetSetID or widgetSetID == 0 then
		return nil, false
	end

	local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetID)

	if not widgets or #widgets == 0 then
		return nil, false
	end

	for _, widget in ipairs(widgets) do
		if widget.widgetType == DELVE_WIDGET_TYPE then
			return widgetSetID, true
		end
	end

	return widgetSetID, false
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

	-- In a dungeon the stage is the dungeon itself, so the card becomes the
	-- title instead of sitting under it.
	local hasOwnStage = stageName and stageName ~= "" and stageName ~= scenarioName
	local stageLabel = hasOwnStage and FormatStage(stageName, currentStage, numStages)
		or scenarioName

	local widgetSetID, isDelve = ReadWidgetSet()

	if widgetSetID then
		table.insert(objectives, {
			text = stageLabel,
			widgetSetID = widgetSetID,
			isComplete = false,
		})
	else
		local highlight = hasOwnStage and stageName or scenarioName
		local caption

		if hasOwnStage and numStages > 1 then
			highlight = currentStage == numStages and SCENARIO_STAGE_FINAL
				or SCENARIO_STAGE:format(currentStage)
			caption = stageName
		end

		table.insert(objectives, {
			text = stageLabel,
			card = {
				highlight = highlight,
				caption = caption,
				atlas = ReadHeaderAtlas(),
			},
			isComplete = false,
		})
	end

	if stageDescription and stageDescription ~= "" then
		table.insert(objectives, { text = stageDescription, isComplete = false })
	end

	AddCriteria(objectives)
	AddChallengeInfo(objectives)

	-- In a delve the scenario name is the category itself, already translated,
	-- and the widget carries the delve name. Promoted to section title, nothing
	-- is left for the title line to say.
	local title = TRACKER_HEADER_SCENARIO

	if isDelve then
		title = scenarioName
	elseif IsInDungeon() then
		title = TRACKER_HEADER_DUNGEON
	end

	return {
		{
			id = "scenario",
			title = title,
			order = Addon.SectionOrder.scenario,
			entries = {
				{
					id = scenarioName,
					kind = ENTRY_KIND,
					title = scenarioName,
					hidesTitle = not hasOwnStage or isDelve,
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
