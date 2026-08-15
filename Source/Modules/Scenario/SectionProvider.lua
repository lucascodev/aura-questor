local _, Addon = ...

local ENTRY_KIND = "scenario"

--- Above everything else: a scenario is what the player is doing right now,
--- and the quests can wait until they are out of it.

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

--- Weighted progress is a share of the whole, not a count of things: the
--- quantity is already the percentage, and it belongs in a bar.
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

--- Cada cenário declara o seu conjunto de arte, e o fundo do bloco segue dele
--- por nome. Quando o atlas não existe naquela versão do cliente, o card volta
--- para a caixa lisa em vez de sumir.
---@return string?
local function ReadHeaderAtlas()
	local textureKit = select(TEXTURE_KIT_RETURN, C_Scenario.GetInfo()) or DEFAULT_TEXTURE_KIT
	local atlas = textureKit .. HEADER_ATLAS_SUFFIX

	if not C_Texture.GetAtlasInfo(atlas) then
		return nil
	end

	return atlas
end

--- Mítica+ não serve de teste: uma masmorra normal também é masmorra, e só o
--- tipo da instância separa isso de um cenário a céu aberto.
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

--- O passo pode publicar um conjunto de widgets: o cronômetro de onda, o
--- cabeçalho de Imersão com nível, vidas e modificadores. Quando existe, o
--- próprio jogo desenha esse bloco, e correr atrás de cada temporada com
--- desenho nosso deixa de ser necessário.
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

	-- Numa masmorra o estágio é a própria masmorra: não há nome a repetir, e o
	-- card passa a ser o título em vez de vir abaixo dele.
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
		table.insert(objectives, {
			text = stageLabel,
			card = { highlight = stageLabel, atlas = ReadHeaderAtlas() },
			isComplete = false,
		})
	end

	if stageDescription and stageDescription ~= "" then
		table.insert(objectives, { text = stageDescription, isComplete = false })
	end

	AddCriteria(objectives)
	AddChallengeInfo(objectives)

	-- Numa Imersão o nome do cenário é a própria categoria, já localizado pelo
	-- jogo, e o widget carrega o nome da Delve. Promovido a título da seção,
	-- nada sobra para a linha de título dizer.
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
