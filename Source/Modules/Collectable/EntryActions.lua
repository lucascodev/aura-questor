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

--- Opening it needs a profession this character actually knows, and the game
--- has its own wording for when that is not the case.
---@param recipeID number
local function OpenProfession(recipeID)
	if ProfessionsUtil.OpenProfessionFrameToRecipe(recipeID) then
		return
	end

	UIErrorsFrame:AddExternalErrorMessage(ADVENTURE_TRACKING_OPEN_PROFESSION_ERROR_TEXT)
end

--- Where a click lands is decided by what the game says the collectable comes
--- from, not by the collectable itself: an achievement opens the achievement, a
--- recipe opens the profession, and a vendor, a boss or a house decor chest is
--- a place, so the map opens on it. Sending every one of them to the collections
--- journal instead is what made housing decor look unclickable.
---@param entry TrackerEntry
function CollectableEntryActions:OpenDetails(entry)
	local trackingType = TRACKING_TYPE_BY_KIND[entry.kind]

	if trackingType == Enum.ContentTrackingType.Appearance and IsModifiedClick("DRESSUP") then
		DressUpVisual(entry.id)
		return
	end

	local targetType, targetID = C_ContentTracking.GetCurrentTrackingTarget(trackingType, entry.id)

	if targetType == Enum.ContentTrackingTargetType.Achievement then
		Addon.AchievementPanel.OpenTo(targetID)
		return
	end

	if targetType == Enum.ContentTrackingTargetType.Profession then
		OpenProfession(targetID)
		return
	end

	ContentTrackingUtil.OpenMapToTrackable(trackingType, entry.id)
end

--- Content tracking has its own super-tracked slot, separate from the quest
--- one, so the arrow is pointed through the content call.
---@param entry TrackerEntry
function CollectableEntryActions:SuperTrack(entry)
	Addon.SuperTracking.SetContent(TRACKING_TYPE_BY_KIND[entry.kind], entry.id)
end

--- The game builds the link for both kinds and checks the modifier and the chat
--- box itself, reporting whether it took the click.
---@param entry TrackerEntry
---@return boolean
function CollectableEntryActions:InsertChatLink(entry)
	return ContentTrackingUtil.ProcessChatLink(TRACKING_TYPE_BY_KIND[entry.kind], entry.id) == true
end

---@param entry TrackerEntry
function CollectableEntryActions:Untrack(entry)
	C_ContentTracking.StopTracking(
		TRACKING_TYPE_BY_KIND[entry.kind],
		entry.id,
		Enum.ContentTrackingStopType.Manual
	)
end

--- Only an appearance has a page of its own to open: decor lives in the housing
--- catalog, which the map already takes the player to.
---@param entry TrackerEntry
---@return EntryMenuItem[]
function CollectableEntryActions:MenuItems(entry)
	local items = {}

	if TRACKING_TYPE_BY_KIND[entry.kind] == Enum.ContentTrackingType.Appearance then
		table.insert(items, {
			label = CONTENT_TRACKING_OPEN_JOURNAL_OPTION,
			run = function()
				TransmogUtil.OpenCollectionToItem(entry.id)
			end,
		})
	end

	table.insert(items, {
		label = OBJECTIVES_STOP_TRACKING,
		run = function()
			self:Untrack(entry)
		end,
	})

	return items
end

Addon.CollectableEntryActions = CollectableEntryActions
