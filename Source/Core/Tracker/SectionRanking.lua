local _, Addon = ...

--- The order the sections come out in, when the player has arranged them.
---
--- A saved arrangement is a list of section ids. Anything missing from it, like
--- a section added by a newer version, keeps the order it was born with, after
--- the arranged ones.
---@class SectionRanking
local SectionRanking = {}

--- Room for every arranged section to rank below any unarranged one without the
--- two ever tying.
local UNARRANGED_BASE = 1000

---@param order string[]
---@param sectionID string
---@return number?
local function PositionIn(order, sectionID)
	for index, id in ipairs(order) do
		if id == sectionID then
			return index
		end
	end
end

---@param order string[]
---@param sectionID string
---@param bornAt number The order the section declares for itself.
---@return number
function SectionRanking.Rank(order, sectionID, bornAt)
	local position = PositionIn(order, sectionID)

	if position then
		return position
	end

	return UNARRANGED_BASE + bornAt
end

--- Moves one section up or down, and answers whether anything changed: at the
--- ends of the list there is nowhere to go.
---@param order string[]
---@param sectionID string
---@param step number -1 up, 1 down.
---@return boolean moved
function SectionRanking.Move(order, sectionID, step)
	local position = PositionIn(order, sectionID)
	local target = position and position + step

	if not target or target < 1 or target > #order then
		return false
	end

	order[position], order[target] = order[target], order[position]

	return true
end

--- The arrangement to start from, which is the order the sections declare for
--- themselves. Without it there is nothing to move around.
---@param defaults table<string, number>
---@return string[]
function SectionRanking.FromDefaults(defaults)
	local order = {}

	for sectionID in pairs(defaults) do
		table.insert(order, sectionID)
	end

	table.sort(order, function(left, right)
		return defaults[left] < defaults[right]
	end)

	return order
end

Addon.SectionRanking = SectionRanking
