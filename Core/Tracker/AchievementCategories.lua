local _, Addon = ...

--- Which achievement categories the tracker shows.
---
--- The list itself comes from the game, so it is injected; what belongs here is
--- the rule that a hidden category is the exception worth saving.
---@class AchievementCategories
---@field private hidden table<number, boolean>
---@field private listAll fun(): { id: number, name: string }[]
---@field private onChanged fun()
local AchievementCategories = {}
AchievementCategories.__index = AchievementCategories

---@param hidden table<number, boolean> Persisted across sessions.
---@param listAll fun(): { id: number, name: string }[]
---@param onChanged fun()
---@return AchievementCategories
function AchievementCategories.New(hidden, listAll, onChanged)
	return setmetatable({
		hidden = hidden,
		listAll = listAll,
		onChanged = onChanged,
	}, AchievementCategories)
end

---@return { id: number, name: string }[]
function AchievementCategories:List()
	return self.listAll()
end

---@param categoryID number
---@return boolean
function AchievementCategories:IsShown(categoryID)
	return not self.hidden[categoryID]
end

---@param categoryID number
function AchievementCategories:Toggle(categoryID)
	Addon.ToggleSet.Toggle(self.hidden, categoryID)
	self.onChanged()
end

---@param isShown boolean
function AchievementCategories:ShowAll(isShown)
	Addon.ToggleSet.Clear(self.hidden)

	if not isShown then
		for _, category in ipairs(self.listAll()) do
			self.hidden[category.id] = true
		end
	end

	self.onChanged()
end

Addon.AchievementCategories = AchievementCategories
