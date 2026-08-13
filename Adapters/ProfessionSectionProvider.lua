local _, Addon = ...

local ENTRY_KIND = "recipe"
local SECTION_ORDER = 60

local IS_RECRAFT = true

--- SectionProvider for tracked profession recipes.
---
--- Recipes are tracked in two independent lists, plain and recraft, and the same
--- recipe can be in both, which is why the recraft ones carry the game's own
--- "Recrafting" wording rather than appearing as a duplicate.
---
---@class ProfessionSectionProvider : SectionProvider
local ProfessionSectionProvider = {}
ProfessionSectionProvider.__index = ProfessionSectionProvider

---@return ProfessionSectionProvider
function ProfessionSectionProvider.New()
	return setmetatable({}, ProfessionSectionProvider)
end

---@param recipeID number
---@param isRecraft boolean
---@return TrackerEntry?
local function ReadEntry(recipeID, isRecraft)
	local schematic = ProfessionsUtil.GetRecipeSchematic(recipeID, isRecraft)
	if not schematic or not schematic.name then
		return nil
	end

	local title = schematic.name
	if isRecraft then
		title = PROFESSIONS_CRAFTING_FORM_RECRAFTING_HEADER:format(title)
	end

	return {
		id = recipeID,
		kind = ENTRY_KIND,
		title = title,
		objectives = Addon.ReagentReader.Read(schematic),
		isComplete = false,
		canFindGroup = false,
	}
end

---@param entries TrackerEntry[]
---@param isRecraft boolean
local function CollectTracked(entries, isRecraft)
	for _, recipeID in ipairs(C_TradeSkillUI.GetRecipesTracked(isRecraft) or {}) do
		local entry = ReadEntry(recipeID, isRecraft)
		if entry then
			table.insert(entries, entry)
		end
	end
end

---@return TrackerSection[]
function ProfessionSectionProvider:Collect()
	local entries = {}

	CollectTracked(entries, not IS_RECRAFT)
	CollectTracked(entries, IS_RECRAFT)

	return {
		{
			id = "recipes",
			title = PROFESSIONS_TRACKER_HEADER_PROFESSION,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.ProfessionSectionProvider = ProfessionSectionProvider
