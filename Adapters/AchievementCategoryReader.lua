local _, Addon = ...

--- Categories the achievement panel groups everything under.
---
--- The list is a flat set of ids linked by parent, so the top level is whatever
--- has no parent, and finding an achievement's top level means walking up until
--- there is nowhere left to go.
---@class AchievementCategoryReader
local AchievementCategoryReader = {}

local NO_PARENT = -1

--- Every category's parent, read once so callers can walk the tree without
--- asking the game again per achievement.
---@return table<number, number>
function AchievementCategoryReader.ReadParents()
	local parents = {}

	for _, categoryID in ipairs(GetCategoryList()) do
		local _, parentID = GetCategoryInfo(categoryID)
		parents[categoryID] = parentID
	end

	return parents
end

---@return { id: number, name: string }[]
function AchievementCategoryReader.ListTopLevel()
	local categories = {}

	for _, categoryID in ipairs(GetCategoryList()) do
		local name, parentID = GetCategoryInfo(categoryID)

		if name and parentID == NO_PARENT then
			table.insert(categories, { id = categoryID, name = name })
		end
	end

	return categories
end

---@param parents table<number, number>
---@param achievementID number
---@return number?
function AchievementCategoryReader.TopLevelOf(parents, achievementID)
	local categoryID = GetAchievementCategory(achievementID)

	while categoryID and parents[categoryID] and parents[categoryID] ~= NO_PARENT do
		categoryID = parents[categoryID]
	end

	return categoryID
end

Addon.AchievementCategoryReader = AchievementCategoryReader
