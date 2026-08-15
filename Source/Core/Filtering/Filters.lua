local _, Addon = ...

local Ids = Addon.QuestFilterIds
local L = Addon.L

--- Every filter the addon offers, in the order the player sees them.
--- Each one is a predicate over the Quest structure, so none of them knows the
--- game exists and all of them are testable without it.
---@type QuestFilter[]
local QuestFilters = {
	{
		id = Ids.ALL,
		label = L.FILTER_ALL,
		matches = function()
			return true
		end,
	},
	{
		id = Ids.ZONE,
		label = L.FILTER_ZONE,
		matches = function(quest)
			return quest.isOnCurrentMap
		end,
	},
	{
		id = Ids.CAMPAIGN,
		label = L.FILTER_CAMPAIGN,
		matches = function(quest)
			return quest.isCampaign
		end,
	},
	{
		id = Ids.RECURRING,
		label = L.FILTER_RECURRING,
		matches = function(quest)
			return quest.isRecurring
		end,
	},
	{
		id = Ids.INSTANCE,
		label = L.FILTER_INSTANCE,
		matches = function(quest)
			return quest.isInstance
		end,
	},
	{
		id = Ids.UNFINISHED,
		label = L.FILTER_INCOMPLETE,
		matches = function(quest)
			return not quest.isComplete
		end,
	},
	{
		id = Ids.COMPLETE,
		label = L.FILTER_COMPLETE,
		matches = function(quest)
			return quest.isComplete
		end,
	},
}

Addon.QuestFilters = QuestFilters
