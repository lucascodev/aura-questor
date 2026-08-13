local _, Addon = ...

local Ids = Addon.QuestFilterIds

--- Every filter the addon offers, in the order the player sees them.
--- Each one is a predicate over the Quest structure, so none of them knows the
--- game exists and all of them are testable without it.
---@type QuestFilter[]
local QuestFilters = {
	{
		id = Ids.ALL,
		label = "Todas",
		matches = function()
			return true
		end,
	},
	{
		id = Ids.ZONE,
		label = "Zona atual",
		matches = function(quest)
			return quest.isOnCurrentMap
		end,
	},
	{
		id = Ids.CAMPAIGN,
		label = "Campanha",
		matches = function(quest)
			return quest.isCampaign
		end,
	},
	{
		id = Ids.RECURRING,
		label = "Diárias e semanais",
		matches = function(quest)
			return quest.isRecurring
		end,
	},
	{
		id = Ids.INSTANCE,
		label = "Masmorra e raide",
		matches = function(quest)
			return quest.isInstance
		end,
	},
	{
		id = Ids.UNFINISHED,
		label = "Não concluídas",
		matches = function(quest)
			return not quest.isComplete
		end,
	},
	{
		id = Ids.COMPLETE,
		label = "Concluídas",
		matches = function(quest)
			return quest.isComplete
		end,
	},
}

Addon.QuestFilters = QuestFilters
