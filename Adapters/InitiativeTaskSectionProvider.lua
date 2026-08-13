local _, Addon = ...

local ENTRY_KIND = "initiativeTask"
local SECTION_ORDER = 90

--- SectionProvider for tracked neighbourhood initiative tasks.
---@class InitiativeTaskSectionProvider : SectionProvider
local InitiativeTaskSectionProvider = {}
InitiativeTaskSectionProvider.__index = InitiativeTaskSectionProvider

---@return InitiativeTaskSectionProvider
function InitiativeTaskSectionProvider.New()
	return setmetatable({}, InitiativeTaskSectionProvider)
end

---@param taskID number
---@return TrackerEntry?
local function ReadEntry(taskID)
	local taskInfo = C_NeighborhoodInitiative.GetInitiativeTaskInfo(taskID)
	if not taskInfo or not taskInfo.taskName then
		return nil
	end

	return {
		id = taskID,
		kind = ENTRY_KIND,
		title = taskInfo.taskName,
		objectives = Addon.RequirementReader.Read(taskInfo.requirementsList),
		isComplete = taskInfo.completed == true,
		canFindGroup = false,
	}
end

---@return TrackerSection[]
function InitiativeTaskSectionProvider:Collect()
	local entries = {}
	local tracked = C_NeighborhoodInitiative.GetTrackedInitiativeTasks()

	for _, taskID in ipairs(tracked and tracked.trackedIDs or {}) do
		local entry = ReadEntry(taskID)
		if entry then
			table.insert(entries, entry)
		end
	end

	return {
		{
			id = "initiativeTasks",
			title = TRACKER_HEADER_INITIATIVE_TASKS,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.InitiativeTaskSectionProvider = InitiativeTaskSectionProvider
