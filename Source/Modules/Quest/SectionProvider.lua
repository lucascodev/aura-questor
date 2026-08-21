local _, Addon = ...

local ENTRY_KIND = "quest"
local COMPLETE_POPUP = "COMPLETE"

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
--- turn it in" wording, which is the only thing left to act on. A quest that
--- turns in from here says so, in the two lines Blizzard's tracker uses.
---@param questID number
---@param questLogIndex number
---@return TrackerObjective[]
local function ReadCompletion(questID, questLogIndex)
	if Addon.QuestPopupSource.CanComplete(questID) then
		return {
			{ text = QUEST_WATCH_QUEST_COMPLETE, isComplete = true },
			{ text = QUEST_WATCH_CLICK_TO_COMPLETE, isComplete = true },
		}
	end

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
	local objectives = isComplete and ReadCompletion(questID, questLogIndex)
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
		rewardsQuestID = questID,
	}

	return entry, info.campaignID ~= nil
end

--- Uma missão oferecida à distância ainda não está no diário, então a entrada
--- se resume ao aviso da própria Blizzard.
---@param questID number
---@return TrackerEntry?
local function ReadOfferEntry(questID)
	local title = C_QuestLog.GetTitleForQuestID(questID)

	if not title or title == "" then
		return nil
	end

	return {
		id = questID,
		kind = ENTRY_KIND,
		title = title,
		objectives = { { text = QUEST_WATCH_POPUP_QUEST_DISCOVERED, isComplete = false } },
		isComplete = false,
		canFindGroup = false,
		pinStyle = "normal",
	}
end

--- Missões com aviso pendente aparecem mesmo fora da lista de observadas: o
--- jogador precisa vê-las para poder completar dali.
---@param campaign TrackerSection
---@param quests TrackerSection
---@param groupNames table<number, string>
---@return table<number, boolean> handled
local function AddPopupEntries(campaign, quests, groupNames)
	local handled = {}

	for _, popup in ipairs(Addon.QuestPopupSource.ReadAll()) do
		if popup.popUpType == COMPLETE_POPUP then
			local entry, isCampaign = ReadEntry(popup.questID, groupNames)

			if entry and entry.isComplete then
				handled[popup.questID] = true
				table.insert(isCampaign and campaign.entries or quests.entries, entry)
			end
		elseif not C_QuestLog.GetLogIndexForQuestID(popup.questID) then
			local entry = ReadOfferEntry(popup.questID)

			if entry then
				handled[popup.questID] = true
				table.insert(quests.entries, entry)
			end
		end
	end

	return handled
end

---@return TrackerSection[]
function QuestSectionProvider:Collect()
	local campaign = {
		id = "campaign",
		title = TRACKER_HEADER_CAMPAIGN_QUESTS,
		order = Addon.SectionOrder.campaign,
		entries = {},
	}
	local quests = {
		id = "quests",
		title = TRACKER_HEADER_QUESTS,
		order = Addon.SectionOrder.quests,
		entries = {},
	}

	local groupNames = Addon.QuestGroupReader.ReadAll()
	local handled = AddPopupEntries(campaign, quests, groupNames)

	for index = 1, C_QuestLog.GetNumQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
		if questID and not handled[questID] then
			local entry, isCampaign = ReadEntry(questID, groupNames)
			if entry then
				table.insert(isCampaign and campaign.entries or quests.entries, entry)
			end
		end
	end

	return { campaign, quests }
end

Addon.QuestSectionProvider = QuestSectionProvider
