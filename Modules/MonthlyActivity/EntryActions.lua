local _, Addon = ...

--- EntryActions for Traveler's Log activities.
---@class MonthlyActivityEntryActions : EntryActions
local MonthlyActivityEntryActions = {}
MonthlyActivityEntryActions.__index = MonthlyActivityEntryActions

---@return MonthlyActivityEntryActions
function MonthlyActivityEntryActions.New()
	return setmetatable({}, MonthlyActivityEntryActions)
end

--- The Traveler's Log lives inside the Adventure Guide, which is load-on-demand
--- like the achievement panel.
---@param entry TrackerEntry
function MonthlyActivityEntryActions:OpenDetails(entry)
	if not EncounterJournal then
		EncounterJournal_LoadUI()
	end

	MonthlyActivitiesFrame_OpenFrameToActivity(entry.id)
end

---@param entry TrackerEntry
function MonthlyActivityEntryActions:Untrack(entry)
	C_PerksActivities.RemoveTrackedPerksActivity(entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function MonthlyActivityEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_VIEW_IN_TRAVELERS_LOG,
			run = function()
				self:OpenDetails(entry)
			end,
		},
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.MonthlyActivityEntryActions = MonthlyActivityEntryActions
