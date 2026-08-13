local _, Addon = ...

--- EntryActions for neighbourhood initiative tasks.
---@class InitiativeTaskEntryActions : EntryActions
local InitiativeTaskEntryActions = {}
InitiativeTaskEntryActions.__index = InitiativeTaskEntryActions

---@return InitiativeTaskEntryActions
function InitiativeTaskEntryActions.New()
	return setmetatable({}, InitiativeTaskEntryActions)
end

--- Deliberately does nothing: an initiative task has no panel of its own to
--- open. Left-clicking one is a no-op, and the menu carries what it can do.
---@param entry TrackerEntry
function InitiativeTaskEntryActions:OpenDetails(entry) end

---@param entry TrackerEntry
function InitiativeTaskEntryActions:Untrack(entry)
	C_NeighborhoodInitiative.RemoveTrackedInitiativeTask(entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function InitiativeTaskEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.InitiativeTaskEntryActions = InitiativeTaskEntryActions
