local _, Addon = ...

--- EntryActions for the running scenario.
---
--- A scenario has no page to open and cannot be untracked, the player is
--- simply in it. Both members are here to satisfy the contract, and the empty
--- menu means right-clicking shows nothing rather than dead options.
---@class ScenarioEntryActions : EntryActions
local ScenarioEntryActions = {}
ScenarioEntryActions.__index = ScenarioEntryActions

---@return ScenarioEntryActions
function ScenarioEntryActions.New()
	return setmetatable({}, ScenarioEntryActions)
end

---@param entry TrackerEntry
function ScenarioEntryActions:OpenDetails(entry) end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function ScenarioEntryActions:MenuItems(entry)
	return {}
end

Addon.ScenarioEntryActions = ScenarioEntryActions
