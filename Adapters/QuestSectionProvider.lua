local _, Addon = ...

local ENTRY_KIND = "quest"

local CAMPAIGN_ORDER = 10
local QUEST_ORDER = 20

--- SectionProvider for the quest log.
---
--- Reads only what is being watched, which is what a tracker shows, and splits
--- it the same way Blizzard does: campaign first, everything else after. The
--- section titles come from the game's own globals, so they arrive translated.
---@class QuestSectionProvider : SectionProvider
local QuestSectionProvider = {}
QuestSectionProvider.__index = QuestSectionProvider

---@return QuestSectionProvider
function QuestSectionProvider.New()
	return setmetatable({}, QuestSectionProvider)
end

--- What a finished quest shows instead of its objectives: the game's own "go
--- turn it in" wording, which is the only thing left to act on.
---@param questLogIndex number
---@return TrackerObjective[]
local function ReadCompletion(questLogIndex)
	local completionText = GetQuestLogCompletionText(questLogIndex) or QUEST_WATCH_QUEST_READY

	return { { text = completionText, isComplete = true } }
end

--- How the game classifies a quest decides which pin family the map draws it
--- with; the tracker follows the same table so the two agree. A calling looks
--- like campaign content because that is what it is.
local PIN_STYLE_BY_CLASSIFICATION = {
	[Enum.QuestClassification.Legendary] = "legendary",
	[Enum.QuestClassification.Campaign] = "campaign",
	[Enum.QuestClassification.Calling] = "campaign",
	[Enum.QuestClassification.Recurring] = "recurring",
	[Enum.QuestClassification.Important] = "important",
	[Enum.QuestClassification.Meta] = "meta",
}

--- A quest ready to hand in keeps the pin of its own kind and shows the turn-in
--- mark where the number was, so a finished campaign quest still reads as
--- campaign content.
local TURN_IN_BY_CLASSIFICATION = {
	[Enum.QuestClassification.Legendary] = "UI-QuestPoiLegendary-QuestBangTurnIn",
	[Enum.QuestClassification.Campaign] = "UI-QuestPoiCampaign-QuestBangTurnIn",
	[Enum.QuestClassification.Calling] = "UI-DailyQuestPoiCampaign-QuestBangTurnIn",
	[Enum.QuestClassification.Recurring] = "UI-QuestPoiRecurring-QuestBangTurnIn",
	[Enum.QuestClassification.Important] = "UI-QuestPoiImportant-QuestBangTurnIn",
	[Enum.QuestClassification.Meta] = "UI-QuestPoiWrapper-QuestBangTurnIn",
}

local DEFAULT_TURN_IN_ATLAS = "UI-QuestPoi-QuestBangTurnIn"

--- The log entry usually carries the classification, but not always; asking the
--- quest info system directly covers the gap, and without it those quests fell
--- back to the plain pin and looked wrong beside their own kind.
---@param info table
---@param questID number
---@return number?
local function ReadClassification(info, questID)
	return info.questClassification or C_QuestInfoSystem.GetQuestClassification(questID)
end

---@param classification number?
---@return TrackerPinIcon
local function TurnInIcon(classification)
	return { atlas = TURN_IN_BY_CLASSIFICATION[classification] or DEFAULT_TURN_IN_ATLAS }
end

---@param questID number
---@param groupNames table<number, string>
---@return TrackerEntry?, boolean isCampaign
local function ReadEntry(questID, groupNames)
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	if not questLogIndex then
		return nil, false
	end

	local info = C_QuestLog.GetInfo(questLogIndex)
	if not info then
		return nil, false
	end

	local isComplete = C_QuestLog.IsComplete(questID)

	-- One call gives the tag and the art for it, the same pairing the quest log
	-- shows beside a name.
	local _, _, tagAtlas = QuestUtil.GetQuestTypeDetails(questID)

	-- Finished objectives step aside entirely, the way Blizzard's tracker does
	-- it. A quest that says "100/100" is telling the player nothing they can act
	-- on; where to hand it in is.
	local objectives = isComplete and ReadCompletion(questLogIndex)
		or Addon.QuestObjectiveReader.Read(questID)

	local classification = ReadClassification(info, questID)

	local entry = {
		id = questID,
		kind = ENTRY_KIND,
		title = info.title,
		groupName = groupNames[questID],
		level = info.level,
		objectives = objectives,
		isComplete = isComplete,
		canFindGroup = QuestUtil.CanCreateQuestGroup(questID),
		tagAtlas = tagAtlas,
		pinStyle = PIN_STYLE_BY_CLASSIFICATION[classification] or "normal",
		pinIcon = isComplete and TurnInIcon(classification) or nil,
		isSuperTrackable = true,
		isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == questID,
	}

	return entry, info.campaignID ~= nil
end

---@return TrackerSection[]
function QuestSectionProvider:Collect()
	local campaign = {
		id = "campaign",
		title = TRACKER_HEADER_CAMPAIGN_QUESTS,
		order = CAMPAIGN_ORDER,
		entries = {},
	}
	local quests = {
		id = "quests",
		title = TRACKER_HEADER_QUESTS,
		order = QUEST_ORDER,
		entries = {},
	}

	local groupNames = Addon.QuestGroupReader.ReadAll()

	for index = 1, C_QuestLog.GetNumQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
		if questID then
			local entry, isCampaign = ReadEntry(questID, groupNames)
			if entry then
				table.insert(isCampaign and campaign.entries or quests.entries, entry)
			end
		end
	end

	return { campaign, quests }
end

Addon.QuestSectionProvider = QuestSectionProvider
