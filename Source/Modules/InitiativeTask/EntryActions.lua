local _, Addon = ...

--- The housing dashboard is load-on-demand, and the call that brings it up is
--- the same one that scrolls to the task: the first click only gets as far as
--- opening it, so the request is made again once it exists.
local OPEN_RETRY_DELAY = 0.1

--- EntryActions for neighbourhood initiative tasks.
---@class InitiativeTaskEntryActions : EntryActions
local InitiativeTaskEntryActions = {}
InitiativeTaskEntryActions.__index = InitiativeTaskEntryActions

---@return InitiativeTaskEntryActions
function InitiativeTaskEntryActions.New()
	return setmetatable({}, InitiativeTaskEntryActions)
end

--- A task does have a page of its own: the Endeavors tab of the housing
--- dashboard, which is where the game's own tracker sends a click.
---@param entry TrackerEntry
function InitiativeTaskEntryActions:OpenDetails(entry)
	HousingFramesUtil.OpenFrameToTaskID(entry.id)

	C_Timer.After(OPEN_RETRY_DELAY, function()
		HousingFramesUtil.OpenFrameToTaskID(entry.id)
	end)
end

--- The game builds the link, but not the decision to insert it: the modifier
--- and an open chat box are checked here, as the achievement link does.
---@param entry TrackerEntry
---@return boolean
function InitiativeTaskEntryActions:InsertChatLink(entry)
	if not IsModifiedClick("CHATLINK") or not ChatFrameUtil.GetActiveWindow() then
		return false
	end

	local link = C_NeighborhoodInitiative.GetInitiativeTaskChatLink(entry.id)

	if not link then
		return false
	end

	ChatFrameUtil.InsertLink(link)

	return true
end

---@param entry TrackerEntry
function InitiativeTaskEntryActions:Untrack(entry)
	C_NeighborhoodInitiative.RemoveTrackedInitiativeTask(entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function InitiativeTaskEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_VIEW_IN_ENDEAVORS_TAB,
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

Addon.InitiativeTaskEntryActions = InitiativeTaskEntryActions
