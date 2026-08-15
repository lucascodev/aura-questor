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
	C_SuperTrack.SetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI, entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function EventEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_SHOW_QUEST_MAP,
			run = function()
				self:OpenDetails(entry)
			end,
		},
	}
end

Addon.EventEntryActions = EventEntryActions
