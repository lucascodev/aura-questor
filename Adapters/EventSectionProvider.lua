local _, Addon = ...

local Keys = Addon.PreferenceKeys

local ENTRY_KIND = "event"
local SECONDS_PER_MINUTE = 60

--- SectionProvider for world events, read from the event scheduler.
---
--- The scheduler answers in two lists and both are needed: scheduled events,
--- which run between a start and an end and therefore show a countdown, and
--- ongoing ones, which simply are.
---@class EventSectionProvider : SectionProvider
---@field private preferences Preferences
local EventSectionProvider = {}
EventSectionProvider.__index = EventSectionProvider

---@param preferences Preferences
---@return EventSectionProvider
function EventSectionProvider.New(preferences)
	return setmetatable({ preferences = preferences }, EventSectionProvider)
end

--- Stand-in for events that have no art of their own, and for the one legacy
--- icon the game still hands back for events nobody updated.
local FALLBACK_ATLAS = "UI-EventPoi-Horn-big"
local LEGACY_GENERIC_ATLAS = "minimap-genericevent-hornicon"

---@param poiInfo table
---@return string
local function ReadPinAtlas(poiInfo)
	if not poiInfo.isCurrentEvent or not poiInfo.atlasName then
		return FALLBACK_ATLAS
	end

	if poiInfo.atlasName == LEGACY_GENERIC_ATLAS then
		return FALLBACK_ATLAS
	end

	return poiInfo.atlasName
end

---@param eventInfo table
---@param secondsLeft number?
---@return TrackerEntry?
local function ReadEntry(eventInfo, secondsLeft)
	local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(nil, eventInfo.areaPoiID)
	if not poiInfo or not poiInfo.name then
		return nil
	end

	local objectives = {}
	local zoneName = C_EventScheduler.GetEventZoneName(eventInfo.areaPoiID)
	if zoneName then
		table.insert(objectives, { text = zoneName, isComplete = false })
	end

	local _, superTrackedPoiID = C_SuperTrack.GetSuperTrackedMapPin(Enum.SuperTrackingMapPinType.AreaPOI)

	return {
		id = eventInfo.areaPoiID,
		kind = ENTRY_KIND,
		title = poiInfo.name,
		objectives = objectives,
		isComplete = false,
		canFindGroup = false,
		pinAtlas = ReadPinAtlas(poiInfo),
		isSuperTrackable = true,
		isSuperTracked = superTrackedPoiID == eventInfo.areaPoiID,
		timeLeftMinutes = secondsLeft and math.floor(secondsLeft / SECONDS_PER_MINUTE) or nil,
	}
end

--- Scheduled events arrive ordered by start time, so the first one still in the
--- future ends the part of the list worth reading.
---@param entries TrackerEntry[]
local function CollectScheduled(entries)
	local scheduledEvents = C_EventScheduler.GetScheduledEvents()
	if not scheduledEvents then
		return
	end

	local now = time()

	for _, eventInfo in ipairs(scheduledEvents) do
		if not eventInfo.rewardsClaimed then
			if eventInfo.startTime > now then
				break
			end

			if eventInfo.endTime > now then
				local entry = ReadEntry(eventInfo, eventInfo.endTime - now)
				if entry then
					table.insert(entries, entry)
				end
			end
		end
	end
end

---@param entries TrackerEntry[]
local function CollectOngoing(entries)
	local ongoingEvents = C_EventScheduler.GetOngoingEvents()
	if not ongoingEvents then
		return
	end

	for _, eventInfo in ipairs(ongoingEvents) do
		if not eventInfo.rewardsClaimed then
			local entry = ReadEntry(eventInfo, nil)
			if entry then
				table.insert(entries, entry)
			end
		end
	end
end

---@return TrackerSection[]
function EventSectionProvider:Collect()
	if not self.preferences:Get(Keys.EVENTS_ENABLED) then
		return {}
	end

	if not C_EventScheduler.CanShowEvents() then
		return {}
	end

	-- The scheduler loads on demand. Asking now means EVENT_SCHEDULER_UPDATE
	-- brings us back with data instead of us guessing at nothing.
	if not C_EventScheduler.HasData() then
		C_EventScheduler.RequestEvents()
		return {}
	end

	local entries = {}
	CollectScheduled(entries)
	CollectOngoing(entries)

	return {
		{
			id = "events",
			title = EVENTS_LABEL,
			order = Addon.SectionOrder.events,
			entries = entries,
		},
	}
end

Addon.EventSectionProvider = EventSectionProvider
