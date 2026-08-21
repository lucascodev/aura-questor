local _, Addon = ...
local L = Addon.L

--- How far a world quest can be and still be listed.
---@class WorldQuestScopes
local WorldQuestScopes = {}

WorldQuestScopes.ALL = "all"
WorldQuestScopes.MAP = "map"
WorldQuestScopes.AREA = "area"

---@type PreferenceChoice[]
WorldQuestScopes.Choices = {
	{ id = WorldQuestScopes.ALL, label = L.WORLD_QUEST_SCOPE_ALL },
	{ id = WorldQuestScopes.MAP, label = L.WORLD_QUEST_SCOPE_MAP },
	{ id = WorldQuestScopes.AREA, label = L.WORLD_QUEST_SCOPE_AREA },
}

Addon.WorldQuestScopes = WorldQuestScopes
