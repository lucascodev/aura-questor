local _, Addon = ...

--- EntryActions for world events.
---
--- An event is a point on the map, not something the player accepted, so the
--- map is the only thing worth offering.
---@class EventEntryActions : EntryActions
local EventEntryActions = {}
EventEntryActions.__index = EventEntryActions

---@return EventEntryActions
function EventEntryActions.New()
	return setmetatable({}, EventEntryActions)
end

---@param entry TrackerEntry
function EventEntryActions:OpenDetails(entry)
	local uiMapID = C_EventScheduler.GetEventUiMapID(entry.id)

	if Addon.MapNavigator.Open(uiMapID, QuestLogDisplayMode.Events) then
		Addon.MapNavigator.PingAreaPoi(entry.id)
	end
end

--- An event is a map pin rather than a quest, so it drives the arrow through the
--- pin API instead.
---@param entry TrackerEntry
function EventEntryActions:SuperTrack(entry)
	Addon.SuperTracking.SetMapPin(Enum.SuperTrackingMapPinType.AreaPOI, entry.id)
end

---@param entry TrackerEntry
--- Following an event is already a click on its icon, but nothing on screen
--- says so, and the same pair of labels is what the map pin offers.
---@return EntryMenuItem[]
function EventEntryActions:MenuItems(entry)
	return {
		{
			label = entry.isSuperTracked and POI_REMOVE_FOCUS or POI_FOCUS,
			run = function()
				if entry.isSuperTracked then
					Addon.SuperTracking.Clear()

					return
				end

				self:SuperTrack(entry)
			end,
		},
		{
			label = OBJECTIVES_SHOW_QUEST_MAP,
			run = function()
				self:OpenDetails(entry)
			end,
		},
	}
end

Addon.EventEntryActions = EventEntryActions
