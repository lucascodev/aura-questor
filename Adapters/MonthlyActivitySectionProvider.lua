local _, Addon = ...

local ENTRY_KIND = "monthlyActivity"
local SECTION_ORDER = 70

--- SectionProvider for tracked Traveler's Log activities.
---@class MonthlyActivitySectionProvider : SectionProvider
local MonthlyActivitySectionProvider = {}
MonthlyActivitySectionProvider.__index = MonthlyActivitySectionProvider

---@return MonthlyActivitySectionProvider
function MonthlyActivitySectionProvider.New()
	return setmetatable({}, MonthlyActivitySectionProvider)
end

---@param activityID number
---@return TrackerEntry?
local function ReadEntry(activityID)
	local activityInfo = C_PerksActivities.GetPerksActivityInfo(activityID)
	if not activityInfo or not activityInfo.activityName then
		return nil
	end

	return {
		id = activityID,
		kind = ENTRY_KIND,
		title = activityInfo.activityName,
		objectives = Addon.RequirementReader.Read(activityInfo.requirementsList),
		isComplete = activityInfo.completed == true,
		canFindGroup = false,
	}
end

---@return TrackerSection[]
function MonthlyActivitySectionProvider:Collect()
	local entries = {}
	local tracked = C_PerksActivities.GetTrackedPerksActivities()

	for _, activityID in ipairs(tracked and tracked.trackedIDs or {}) do
		local entry = ReadEntry(activityID)
		if entry then
			table.insert(entries, entry)
		end
	end

	return {
		{
			id = "monthlyActivities",
			title = TRACKER_HEADER_MONTHLY_ACTIVITIES,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.MonthlyActivitySectionProvider = MonthlyActivitySectionProvider
