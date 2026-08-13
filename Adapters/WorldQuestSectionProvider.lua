local _, Addon = ...

local ENTRY_KIND = "worldQuest"
local SECTION_ORDER = 30

--- SectionProvider for world quests.
---
--- They live in their own watch list, separate from the quest log's, which is
--- why this cannot be folded into the quest provider.
---@class WorldQuestSectionProvider : SectionProvider
local WorldQuestSectionProvider = {}
WorldQuestSectionProvider.__index = WorldQuestSectionProvider

---@return WorldQuestSectionProvider
function WorldQuestSectionProvider.New()
	return setmetatable({}, WorldQuestSectionProvider)
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

---@param questID number
---@return TrackerEntry?
local function ReadEntry(questID)
	local title = C_TaskQuest.GetQuestInfoByQuestID(questID)
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
		timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID),
	}
end

--- World quests belong to the zone they are in, and the task table is exactly
--- that list, tracked ones included.
---@return number[]
local function CollectQuestIDs()
	local questIDs = {}

	for _, questID in ipairs(GetTasksTable()) do
		if QuestUtils_IsQuestWorldQuest(questID) then
			table.insert(questIDs, questID)
		end
	end

	return questIDs
end

---@return TrackerSection[]
function WorldQuestSectionProvider:Collect()
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
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.WorldQuestSectionProvider = WorldQuestSectionProvider
