local _, Addon = ...

local REWARD_ICON_SIZE = 14

--- The game reports a choice as either an item or a currency, and each is read
--- through a different call.
local CHOICE_LOOT_CURRENCY = 1
local CHOICE_HEADING = "Escolha uma:"

--- EntryActions for quests, including world quests, both live in the quest log
--- and answer to the same calls.
---@class QuestEntryActions : EntryActions
local QuestEntryActions = {}
QuestEntryActions.__index = QuestEntryActions

---@return QuestEntryActions
function QuestEntryActions.New()
	return setmetatable({}, QuestEntryActions)
end

---@param entry TrackerEntry
function QuestEntryActions:OpenDetails(entry)
	QuestMapFrame_OpenToQuestDetails(entry.id)
end

--- Waypoints would send the map to the next hop rather than to the objective,
--- so they are ignored when asking where this quest lives.
local IGNORE_WAYPOINTS = true

--- Takes the map to the quest's zone and pings it there. A quest with no map of
--- its own reports zero, and then nothing is moved.
---@param entry TrackerEntry
function QuestEntryActions:ShowOnMap(entry)
	local uiMapID = GetQuestUiMapID(entry.id, IGNORE_WAYPOINTS)

	if Addon.MapNavigator.Open(uiMapID, QuestLogDisplayMode.Quests) then
		Addon.MapNavigator.PingQuest(entry.id)
	end
end

--- Points the on-screen arrow and the map waypoint at this quest.
---@param entry TrackerEntry
function QuestEntryActions:SuperTrack(entry)
	C_SuperTrack.SetSuperTrackedQuestID(entry.id)
end

--- Opens the group finder already searching for this quest.
---@param entry TrackerEntry
function QuestEntryActions:FindGroup(entry)
	LFGListUtil_FindQuestGroup(entry.id)
end

---@param entry TrackerEntry
function QuestEntryActions:Untrack(entry)
	if not QuestUtil.CanRemoveQuestWatch() then
		return
	end

	C_QuestLog.RemoveQuestWatch(entry.id)
end

--- The quest's own briefing text.
---
--- Reading it means selecting the quest, and the selection is global state the
--- quest log reads too, so whatever was selected is put back. Skipping that
--- would make hovering the tracker quietly change what the quest log shows.
---@param entry TrackerEntry
---@return string?
function QuestEntryActions:Describe(entry)
	local previous = C_QuestLog.GetSelectedQuest()

	C_QuestLog.SetSelectedQuest(entry.id)
	local description = GetQuestLogQuestText()

	if previous then
		C_QuestLog.SetSelectedQuest(previous)
	end

	return description
end

---@param texture string|number|nil
---@param count number?
---@param name string
---@return string
local function FormatReward(texture, count, name)
	local icon = texture and ("|T%s:%d|t "):format(texture, REWARD_ICON_SIZE) or ""
	local amount = count and count > 1 and ("%dx "):format(count) or ""

	return icon .. amount .. name
end

---@param rewards string[]
---@param questID number
local function AddGuaranteed(rewards, questID)
	local money = GetQuestLogRewardMoney(questID)

	if money and money > 0 then
		-- Already carries its own coin icons.
		table.insert(rewards, GetCoinTextureString(money))
	end

	for index = 1, GetNumQuestLogRewards(questID) do
		local name, texture, count = GetQuestLogRewardInfo(index, questID)

		if name then
			table.insert(rewards, FormatReward(texture, count, name))
		end
	end
end

--- Rewards the player picks between, which are a separate list from the
--- guaranteed ones, reading only the latter is why a quest paying four
--- reputation choices looked like it paid nothing.
---@param rewards string[]
---@param questID number
local function AddChoices(rewards, questID)
	local numChoices = GetNumQuestLogChoices(questID, true)

	if numChoices == 0 then
		return
	end

	table.insert(rewards, CHOICE_HEADING)

	for index = 1, numChoices do
		if GetQuestLogChoiceInfoLootType(index) == CHOICE_LOOT_CURRENCY then
			local info = C_QuestLog.GetQuestRewardCurrencyInfo(questID, index, true)

			if info and info.name then
				table.insert(rewards, FormatReward(info.texture, info.totalRewardAmount, info.name))
			end
		else
			local name, texture, count = GetQuestLogChoiceInfo(index)

			if name then
				table.insert(rewards, FormatReward(texture, count, name))
			end
		end
	end
end

--- What the quest pays out, ready to print.
---
--- Icons are inlined because a reward you recognise at a glance is the whole
--- point of showing it here instead of just naming it. Selecting the quest is
--- required (the choice API reads the selected one) and the previous
--- selection goes back, since the quest log shares that state.
---@param entry TrackerEntry
---@return string[]
function QuestEntryActions:Rewards(entry)
	local rewards = {}
	local previous = C_QuestLog.GetSelectedQuest()

	C_QuestLog.SetSelectedQuest(entry.id)
	AddGuaranteed(rewards, entry.id)
	AddChoices(rewards, entry.id)

	if previous then
		C_QuestLog.SetSelectedQuest(previous)
	end

	return rewards
end

--- Blizzard's own strings, so the menu arrives translated.
---@param entry TrackerEntry
---@return EntryMenuItem[]
function QuestEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_VIEW_IN_QUESTLOG,
			run = function()
				self:OpenDetails(entry)
			end,
		},
		{
			label = OBJECTIVES_SHOW_QUEST_MAP,
			run = function()
				self:ShowOnMap(entry)
			end,
		},
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.QuestEntryActions = QuestEntryActions
