local _, Addon = ...

local QUEST_KIND = "quest"
local WORLD_QUEST_KIND = "worldQuest"

--- Works out where a quest is in the world, for the navigation arrow.
---@class WaypointReader
local WaypointReader = {}

---@param questID number
---@param mapID number?
---@return number? x
---@return number? y
local function PositionOnMap(questID, mapID)
	if not mapID or mapID == 0 then
		return nil, nil
	end

	for _, info in ipairs(C_QuestLog.GetQuestsOnMap(mapID) or {}) do
		if info.questID == questID then
			return info.x, info.y
		end
	end

	return nil, nil
end

---@param questID number
---@param mapID number?
---@return number? x
---@return number? y
local function TaskPositionOnMap(questID, mapID)
	if not mapID or mapID == 0 then
		return nil, nil
	end

	for _, info in ipairs(C_TaskQuest.GetQuestsOnMap(mapID) or {}) do
		if info.questID == questID then
			return info.x, info.y
		end
	end

	return nil, nil
end

---@param questID number
---@return WaypointTarget
local function ReadTaskQuest(questID)
	local mapID = C_TaskQuest.GetQuestZoneID(questID)
	local x, y = TaskPositionOnMap(questID, mapID)
	local title = C_TaskQuest.GetQuestInfoByQuestID(questID)

	return {
		id = questID,
		kind = WORLD_QUEST_KIND,
		uiMapID = mapID,
		x = x,
		y = y,
		title = title,
	}
end

---@param questID number
---@return WaypointTarget
local function ReadLogQuest(questID)
	local mapID, x, y = C_QuestLog.GetNextWaypoint(questID)

	if not x then
		mapID = GetQuestUiMapID(questID)
		x, y = PositionOnMap(questID, mapID)
	end

	return {
		id = questID,
		kind = QUEST_KIND,
		uiMapID = mapID,
		x = x,
		y = y,
		title = C_QuestLog.GetTitleForQuestID(questID),
	}
end

---@param questID number
---@param kind string
---@return WaypointTarget?
function WaypointReader.ForQuest(questID, kind)
	if not questID or questID == 0 then
		return nil
	end

	if kind == QUEST_KIND then
		return ReadLogQuest(questID)
	end

	return ReadTaskQuest(questID)
end

--- The target being tracked right now, when it is a quest. Other kinds of
--- supertrack (pins de evento, conquistas) ficam de fora: devolver nil faz a
--- target make the arrow clear instead of pointing at the previous quest.
---@return WaypointTarget?
function WaypointReader.Current()
	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	if not questID or questID == 0 then
		return nil
	end

	local isTask = C_QuestLog.IsWorldQuest(questID) or C_QuestLog.IsQuestTask(questID)

	return WaypointReader.ForQuest(questID, isTask and WORLD_QUEST_KIND or QUEST_KIND)
end

Addon.WaypointReader = WaypointReader
