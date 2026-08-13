local _, Addon = ...

--- Takes the world map to a place and points at what matters there.
---
--- Opening the quest log with a map id is not the same thing: it shows the log,
--- leaving the map wherever the player already was. OpenWorldMap moves the map,
--- the display mode decides which list the side panel shows, and the ping is
--- what makes the destination obvious once it arrives. Skipping the display mode
--- is why clicking an event did nothing.
---@class MapNavigator
local MapNavigator = {}

---@param uiMapID number?
---@param displayMode number One of QuestLogDisplayMode.
---@return boolean opened
function MapNavigator.Open(uiMapID, displayMode)
	if not uiMapID or uiMapID <= 0 then
		return false
	end

	QuestMapFrame:SetDisplayMode(displayMode)
	C_Map.OpenWorldMap(uiMapID)

	return true
end

---@param questID number
function MapNavigator.PingQuest(questID)
	EventRegistry:TriggerEvent("MapCanvas.PingQuestID", questID)
end

---@param areaPoiID number
function MapNavigator.PingAreaPoi(areaPoiID)
	EventRegistry:TriggerEvent("PingAreaPOIEvent", areaPoiID)
end

Addon.MapNavigator = MapNavigator
