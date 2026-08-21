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

--- A field written by an addon becomes tainted, and Blizzard's map shortcut
--- reads the display mode: writing the value already there would taint it for
--- nothing.
---@param displayMode number
---@return boolean
local function IsDisplayMode(displayMode)
	local current = QuestMapFrame.displayMode

	if current == nil and QuestMapFrame.GetDisplayMode then
		current = QuestMapFrame:GetDisplayMode()
	end

	return current == displayMode
end

---@param uiMapID number?
---@param displayMode number One of QuestLogDisplayMode.
---@return boolean opened
function MapNavigator.Open(uiMapID, displayMode)
	if not uiMapID or uiMapID <= 0 then
		return false
	end

	if not IsDisplayMode(displayMode) then
		QuestMapFrame:SetDisplayMode(displayMode)
	end

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
