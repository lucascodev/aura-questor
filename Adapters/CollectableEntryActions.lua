local _, Addon = ...

--- Each collectable kind maps to the tracking type the game filed it under.
--- Carrying it here keeps the generic entry structure free of a type field only
--- collectables would ever use.
local TRACKING_TYPE_BY_KIND = {
	appearance = Enum.ContentTrackingType.Appearance,
	decor = Enum.ContentTrackingType.Decor,
}

--- EntryActions for tracked collectables.
---@class CollectableEntryActions : EntryActions
local CollectableEntryActions = {}
CollectableEntryActions.__index = CollectableEntryActions

---@return CollectableEntryActions
function CollectableEntryActions.New()
	return setmetatable({}, CollectableEntryActions)
end

---@param entry TrackerEntry
function CollectableEntryActions:OpenDetails(entry)
	ToggleCollectionsJournal()
end

---@param entry TrackerEntry
function CollectableEntryActions:Untrack(entry)
	C_ContentTracking.StopTracking(
		TRACKING_TYPE_BY_KIND[entry.kind],
		entry.id,
		Enum.ContentTrackingStopType.Manual
	)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function CollectableEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.CollectableEntryActions = CollectableEntryActions
