local _, Addon = ...

local Keys = Addon.PreferenceKeys

local ENTRY_KIND = "worldQuest"
local PLAYER_UNIT = "player"

--- SectionProvider for world quests.
---
--- They live in their own watch list, separate from the quest log's, which is
--- why this cannot be folded into the quest provider.
---@class WorldQuestSectionProvider : SectionProvider
---@field private preferences Preferences
local WorldQuestSectionProvider = {}
WorldQuestSectionProvider.__index = WorldQuestSectionProvider

---@param preferences Preferences
---@return WorldQuestSectionProvider
function WorldQuestSectionProvider.New(preferences)
	return setmetatable({ preferences = preferences }, WorldQuestSectionProvider)
end

--- The art the map draws inside a world quest pin, with the size Blizzard
--- reports for it: these are not all square.
---@param questID number
---@return TrackerPinIcon?
local function ReadPinIcon(questID)
	local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
	if not tagInfo then
		return nil
	end

	local atlas, width, height = QuestUtil.GetWorldQuestAtlasInfo(questID, tagInfo, false)
	if not atlas then
		return nil
	end

	return { atlas = atlas, width = width, height = height }
end

--- A quest tracked from the map may not have its text loaded yet; asking for
--- it brings QUEST_DATA_LOAD_RESULT, and the refresh that follows draws it.
---@param questID number
---@return string?
local function ReadTitle(questID)
	local title = C_TaskQuest.GetQuestInfoByQuestID(questID) or C_QuestLog.GetTitleForQuestID(questID)

	if not title or title == "" then
		C_QuestLog.RequestLoadQuestByID(questID)
		return nil
	end

	return title
end

---@param questID number
---@return TrackerEntry?
local function ReadEntry(questID)
	local title = ReadTitle(questID)
	if not title then
		return nil
	end

	local _, _, tagAtlas = QuestUtil.GetQuestTypeDetails(questID)

	return {
		id = questID,
		kind = ENTRY_KIND,
		title = title,
		objectives = Addon.QuestObjectiveReader.Read(questID),
		isComplete = C_QuestLog.IsComplete(questID),
		canFindGroup = QuestUtil.CanCreateQuestGroup(questID),
		tagAtlas = tagAtlas,
		pinStyle = "worldQuest",
		pinIcon = ReadPinIcon(questID),
		isSuperTrackable = true,
		isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == questID,
		rewardsQuestID = questID,
		timeLeftSeconds = C_TaskQuest.GetQuestTimeLeftSeconds(questID),
	}
end

--- Two lists, the same order Blizzard's tracker uses: the world quests whose
--- area the player is standing in come first, then the ones tracked from the
--- map, wherever they are. Reading only the first was why a quest tracked from
--- another zone never showed up.
--- Two lists, the same order Blizzard's tracker uses: the world quests whose
--- area the player is standing in come first, then the ones tracked from the
--- map, wherever they are.
---@return number[]
local function TrackedQuestIDs()
	local questIDs = {}
	local seen = {}

	local function Add(questID)
		if not seen[questID] then
			seen[questID] = true
			table.insert(questIDs, questID)
		end
	end

	for _, questID in ipairs(GetTasksTable()) do
		if QuestUtils_IsQuestWorldQuest(questID) then
			Add(questID)
		end
	end

	for index = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(index)

		if questID then
			Add(questID)
		end
	end

	return questIDs
end

--- Every world quest the map of the zone the player is in has to offer, tracked
--- or not. With the area scope, only the ones the game says the player is
--- standing in.
---@param isAreaOnly boolean
---@return number[]
local function QuestIDsOnMap(isAreaOnly)
	local uiMapID = C_Map.GetBestMapForUnit(PLAYER_UNIT)

	if not uiMapID then
		return {}
	end

	local questIDs = {}

	for _, poi in ipairs(C_TaskQuest.GetQuestsOnMap(uiMapID) or {}) do
		local isInArea = GetTaskInfo(poi.questID)

		if QuestUtils_IsQuestWorldQuest(poi.questID) and (not isAreaOnly or isInArea) then
			table.insert(questIDs, poi.questID)
		end
	end

	return questIDs
end

---@param scope string
---@return number[]
local function CollectQuestIDs(scope)
	if scope == Addon.WorldQuestScopes.ALL then
		return TrackedQuestIDs()
	end

	return QuestIDsOnMap(scope == Addon.WorldQuestScopes.AREA)
end

---@return TrackerSection[]
function WorldQuestSectionProvider:Collect()
	if not self.preferences:Get(Keys.WORLD_QUESTS_ENABLED) then
		return {}
	end

	local entries = {}

	for _, questID in ipairs(CollectQuestIDs(self.preferences:Get(Keys.WORLD_QUEST_SCOPE))) do
		local entry = ReadEntry(questID)

		if entry then
			table.insert(entries, entry)
		end
	end

	return {
		{
			id = "worldQuests",
			title = TRACKER_HEADER_WORLD_QUESTS,
			order = Addon.SectionOrder.worldQuests,
			entries = entries,
		},
	}
end

Addon.WorldQuestSectionProvider = WorldQuestSectionProvider
