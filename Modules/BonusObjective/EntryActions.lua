local _, Addon = ...

--- EntryActions for bonus objectives.
---
--- A bonus objective is a task the world hands out on arrival: it has no page in
--- the quest log and the player never chose to track it, so opening details and
--- untracking are not offered. Only the map is.
---@class BonusEntryActions : EntryActions
local BonusEntryActions = {}
BonusEntryActions.__index = BonusEntryActions

---@return BonusEntryActions
function BonusEntryActions.New()
	return setmetatable({}, BonusEntryActions)
end

--- A task reports its zone through the task API first; the quest log's answer is
--- only a fallback, since these are not really quest log entries.
---@param entry TrackerEntry
function BonusEntryActions:OpenDetails(entry)
	local uiMapID = C_TaskQuest.GetQuestZoneID(entry.id) or GetQuestUiMapID(entry.id)

	if Addon.MapNavigator.Open(uiMapID, QuestLogDisplayMode.Quests) then
		Addon.MapNavigator.PingQuest(entry.id)
	end
end

---@param entry TrackerEntry
function BonusEntryActions:SuperTrack(entry)
	C_SuperTrack.SetSuperTrackedQuestID(entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function BonusEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_SHOW_QUEST_MAP,
			run = function()
				self:OpenDetails(entry)
			end,
		},
	}
end

Addon.BonusEntryActions = BonusEntryActions
