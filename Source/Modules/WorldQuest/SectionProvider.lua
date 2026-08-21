local _, Addon = ...

local Keys = Addon.PreferenceKeys

local ENTRY_KIND = "worldQuest"

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
---@return number[]
local function CollectQuestIDs()
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

---@return TrackerSection[]
function WorldQuestSectionProvider:Collect()
	if not self.preferences:Get(Keys.WORLD_QUESTS_ENABLED) then
		return {}
	end

	local entries = {}

	for _, questID in ipairs(CollectQuestIDs()) do
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
