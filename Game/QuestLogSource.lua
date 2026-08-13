local _, Addon = ...

--- QuestSource port backed by the quest log API.
---
--- Watching and unwatching is the whole mechanism: the tracker rebuilds itself
--- from the watch list, so filtering never touches a frame and never taints.
---@class QuestLogSource : QuestSource
local QuestLogSource = {}
QuestLogSource.__index = QuestLogSource

---@return QuestLogSource
function QuestLogSource.New()
	return setmetatable({}, QuestLogSource)
end

--- What the game calls instance content, by its own quest tags.
local INSTANCE_TAGS = {
	[Enum.QuestTag.Dungeon] = true,
	[Enum.QuestTag.Heroic] = true,
	[Enum.QuestTag.Raid] = true,
	[Enum.QuestTag.Raid10] = true,
	[Enum.QuestTag.Raid25] = true,
	[Enum.QuestTag.Delve] = true,
}

---@param questID number
---@return boolean
local function IsInstanceQuest(questID)
	local tagInfo = C_QuestLog.GetQuestTagInfo(questID)

	return tagInfo ~= nil and INSTANCE_TAGS[tagInfo.tagID] == true
end

---@param info table Quest log entry as the game reports it.
---@param groupNames table<number, string>
---@return Quest
local function ToQuest(info, groupNames)
	return {
		questID = info.questID,
		title = info.title,
		isCampaign = info.campaignID ~= nil,
		isRecurring = info.frequency ~= nil and info.frequency ~= Enum.QuestFrequency.Default,
		isComplete = C_QuestLog.IsComplete(info.questID),
		isOnCurrentMap = info.isOnMap,
		isInstance = IsInstanceQuest(info.questID),
		groupName = groupNames[info.questID],
	}
end

--- Headers, tasks and hidden entries are not quests the player can track, so
--- they never reach the filters.
---@param info table
---@return boolean
local function IsTrackable(info)
	return not info.isHeader and not info.isTask and not info.isHidden
end

---@return Quest[]
function QuestLogSource:ListAll()
	local quests = {}
	local groupNames = Addon.QuestGroupReader.ReadAll()

	for index = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(index)
		if info and IsTrackable(info) then
			table.insert(quests, ToQuest(info, groupNames))
		end
	end

	return quests
end

---@param questID number
---@param isWatched boolean
---@return boolean applied
function QuestLogSource:SetWatched(questID, isWatched)
	local isWatchedNow = C_QuestLog.GetQuestWatchType(questID) ~= nil
	if isWatchedNow == isWatched then
		return true
	end

	if not isWatched then
		if not QuestUtil.CanRemoveQuestWatch() then
			return false
		end

		C_QuestLog.RemoveQuestWatch(questID)
		return true
	end

	if C_QuestLog.GetNumQuestWatches() >= Constants.QuestWatchConsts.MAX_QUEST_WATCHES then
		return false
	end

	C_QuestLog.AddQuestWatch(questID)
	return true
end

Addon.QuestLogSource = QuestLogSource
