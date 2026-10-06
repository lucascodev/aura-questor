local _, Addon = ...

--- The kinds double as the tracking type, so the actions can untrack an entry
--- without the generic entry structure having to carry a type field.
local KINDS = {
	{ kind = "appearance", trackingType = Enum.ContentTrackingType.Appearance },
	{ kind = "decor", trackingType = Enum.ContentTrackingType.Decor },
}

--- SectionProvider for tracked collectables, appearances and decor.
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

	-- A tracked collectable says nothing about itself: what it costs, who sells
	-- it and where it drops all belong to the target the game currently points
	-- at. Reading the objective off the collectable instead of off that target
	-- is why the line under the name came back empty.
	--
	-- The target arrives after the entry does, so an entry without one yet is
	-- kept on screen carrying the game's own wording for the wait: dropping it
	-- would make the section blink out between the click that tracked it and
	-- the answer about where it comes from.
	local targetType, targetID = C_ContentTracking.GetCurrentTrackingTarget(trackingType, trackableID)
	local objectiveText = targetType and C_ContentTracking.GetObjectiveText(targetType, targetID)
	local objectives = {
		{ text = objectiveText or CONTENT_TRACKING_RETRIEVING_INFO, isComplete = false },
	}

	local superTrackedType, superTrackedID = C_SuperTrack.GetSuperTrackedContent()

	return {
		id = trackableID,
		kind = kind,
		title = title,
		objectives = objectives,
		isComplete = false,
		canFindGroup = false,
		pinStyle = "contentTracking",
		isSuperTrackable = true,
		isSuperTracked = superTrackedType == trackingType and superTrackedID == trackableID,
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
			order = Addon.SectionOrder.collectables,
			entries = entries,
		},
	}
end

Addon.CollectableSectionProvider = CollectableSectionProvider
