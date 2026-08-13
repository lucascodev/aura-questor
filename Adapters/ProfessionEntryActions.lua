local _, Addon = ...

--- EntryActions for tracked profession recipes.
---@class ProfessionEntryActions : EntryActions
local ProfessionEntryActions = {}
ProfessionEntryActions.__index = ProfessionEntryActions

---@return ProfessionEntryActions
function ProfessionEntryActions.New()
	return setmetatable({}, ProfessionEntryActions)
end

---@param entry TrackerEntry
function ProfessionEntryActions:OpenDetails(entry)
	C_TradeSkillUI.OpenRecipe(entry.id)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function ProfessionEntryActions:MenuItems(entry)
	return {
		{
			label = PROFESSIONS_TRACKER_HEADER_PROFESSION,
			run = function()
				self:OpenDetails(entry)
			end,
		},
	}
end

Addon.ProfessionEntryActions = ProfessionEntryActions
