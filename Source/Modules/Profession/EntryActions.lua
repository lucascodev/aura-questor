local _, Addon = ...

local RECRAFT_KIND = "recraft"

local IS_TRACKED = false

--- EntryActions for tracked profession recipes, plain and recraft alike.
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

--- The game keeps plain and recraft in separate lists, and only the one named
--- here lets go of the recipe: the same recipe may still sit in the other.
---@param entry TrackerEntry
function ProfessionEntryActions:Untrack(entry)
	C_TradeSkillUI.SetRecipeTracked(entry.id, IS_TRACKED, entry.kind == RECRAFT_KIND)
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
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.ProfessionEntryActions = ProfessionEntryActions
