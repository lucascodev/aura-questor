local _, Addon = ...

local SECTION_ORDER = 80

--- The kinds double as the tracking type, so the actions can untrack an entry
--- without the generic entry structure having to carry a type field.
local KINDS = {
	{ kind = "appearance", trackingType = Enum.ContentTrackingType.Appearance },
	{ kind = "decor", trackingType = Enum.ContentTrackingType.Decor },
}

--- SectionProvider for tracked collectables — appearances and decor.
---@class CollectableSectionProvider : SectionProvider
local CollectableSectionProvider = {}
CollectableSectionProvider.__index = CollectableSectionProvider

---@return CollectableSectionProvider
function CollectableSectionProvider.New()
	return setmetatable({}, CollectableSectionProvider)
end

---@param trackingType number
---@param trackableID number
---@param kind string
---@return TrackerEntry?
local function ReadEntry(trackingType, trackableID, kind)
	local title = C_ContentTracking.GetTitle(trackingType, trackableID)
	if not title then
		return nil
	end

	local objectives = {}
	local objectiveText = C_ContentTracking.GetObjectiveText(trackingType, trackableID)
	if objectiveText and objectiveText ~= "" then
		table.insert(objectives, { text = objectiveText, isComplete = false })
	end

	return {
		id = trackableID,
		kind = kind,
		title = title,
		objectives = objectives,
		isComplete = false,
		canFindGroup = false,
	}
end

---@return TrackerSection[]
function CollectableSectionProvider:Collect()
	local entries = {}

	for _, tracked in ipairs(KINDS) do
		local trackableIDs = C_ContentTracking.GetTrackedIDs(tracked.trackingType)

		for _, trackableID in ipairs(trackableIDs or {}) do
			local entry = ReadEntry(tracked.trackingType, trackableID, tracked.kind)
			if entry then
				table.insert(entries, entry)
			end
		end
	end

	return {
		{
			id = "collectables",
			title = ADVENTURE_TRACKING_MODULE_HEADER_TEXT,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.CollectableSectionProvider = CollectableSectionProvider
