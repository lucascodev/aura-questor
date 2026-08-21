local _, Addon = ...

--- The order the player dragged the sections into, on top of the default one.
---
--- Kept as a comma separated string rather than a list, because that is what
--- the preference store can hold safely: `Preferences:Set` compares the new
--- value with `==`, which no two tables ever satisfy, and `Preferences:Reset`
--- hands back `preference.default` by reference, which would let a reset alias
--- the catalog's own table and a later edit corrupt the default for everyone.
--- A string has neither problem and survives SavedVariables unchanged.
---@class SectionArrangement
local SectionArrangement = {}

local SEPARATOR = ","

---@param text string?
---@return string[]
function SectionArrangement.Parse(text)
	local ids = {}

	if type(text) ~= "string" then
		return ids
	end

	local seen = {}

	for id in text:gmatch("[^" .. SEPARATOR .. "]+") do
		local trimmed = id:match("^%s*(.-)%s*$")

		if trimmed ~= "" and not seen[trimmed] then
			seen[trimmed] = true
			table.insert(ids, trimmed)
		end
	end

	return ids
end

---@param ids string[]
---@return string
function SectionArrangement.Serialize(ids)
	return table.concat(ids, SEPARATOR)
end

--- The default ids, lowest position first. Sorted by name on a tie so the
--- result never depends on `pairs` iteration order.
---@param defaults table<string, number>
---@return string[]
function SectionArrangement.Defaults(defaults)
	local ids = {}

	for id in pairs(defaults) do
		table.insert(ids, id)
	end

	table.sort(ids, function(left, right)
		if defaults[left] == defaults[right] then
			return left < right
		end

		return defaults[left] < defaults[right]
	end)

	return ids
end

--- Where a section the stored list never heard of belongs.
---
--- Just past the last section that comes before it by default, reading the
--- arranged list in the order the player left it. Anchoring to a neighbour
--- instead of to an absolute position is what keeps a rearranged list
--- rearranged: with achievements dragged to the top, a newly added "world
--- quests" still lands after quests, where its default position says it
--- belongs, rather than seizing first place because the section now sitting
--- there happens to outrank it.
---
--- Reading position, not default rank, is the part that matters. Picking the
--- highest-ranked lower neighbour instead would wedge the new section between
--- two the player had deliberately left side by side.
---@param sequence string[]
---@param defaults table<string, number>
---@param id string
---@return number
local function InsertionPoint(sequence, defaults, id)
	for index = #sequence, 1, -1 do
		if defaults[sequence[index]] < defaults[id] then
			return index + 1
		end
	end

	-- Nothing that precedes it is on screen yet, so it opens the list, ahead of
	-- the first section it should come before.
	for index, current in ipairs(sequence) do
		if defaults[current] > defaults[id] then
			return index
		end
	end

	return #sequence + 1
end

--- Every known section, once, in the order to draw them.
---
--- Two cases have to survive an update. A stored id the addon no longer knows
--- is dropped, so removing a content type cannot leave a hole. A known id the
--- stored list is missing, which is what a section added by a new version looks
--- like, is placed next to its default neighbour. Landing "Delves" at the
--- bottom of a list the player carefully arranged reads as a bug even though
--- nothing was lost.
---@param defaults table<string, number>
---@param stored string[]?
---@return string[]
function SectionArrangement.Sequence(defaults, stored)
	local sequence = {}
	local placed = {}

	for _, id in ipairs(stored or {}) do
		if defaults[id] ~= nil and not placed[id] then
			placed[id] = true
			table.insert(sequence, id)
		end
	end

	for _, id in ipairs(SectionArrangement.Defaults(defaults)) do
		if not placed[id] then
			placed[id] = true
			table.insert(sequence, InsertionPoint(sequence, defaults, id), id)
		end
	end

	return sequence
end

--- Position of each section, for the renderer to sort by.
---@param defaults table<string, number>
---@param stored string[]?
---@return table<string, number>
function SectionArrangement.Resolve(defaults, stored)
	local ranks = {}

	for index, id in ipairs(SectionArrangement.Sequence(defaults, stored)) do
		ranks[id] = index
	end

	return ranks
end

--- Moves one section by `delta` places, clamped at both ends so the caller can
--- hand a button press straight through without checking first.
---@param ids string[]
---@param id string
---@param delta number
---@return string[] moved A new list; the argument is left alone.
---@return boolean changed
function SectionArrangement.Move(ids, id, delta)
	local copy = {}
	local from

	for index, current in ipairs(ids) do
		copy[index] = current

		if current == id then
			from = index
		end
	end

	if not from then
		return copy, false
	end

	local to = from + delta

	if to < 1 or to > #copy or delta == 0 then
		return copy, false
	end

	table.remove(copy, from)
	table.insert(copy, to, id)

	return copy, true
end

--- True while the player has not moved anything, which is what lets the options
--- panel grey out "restore order" instead of offering a no-op.
---@param defaults table<string, number>
---@param ids string[]?
---@return boolean
function SectionArrangement.IsDefault(defaults, ids)
	local wanted = SectionArrangement.Defaults(defaults)
	local current = SectionArrangement.Sequence(defaults, ids)

	for index, id in ipairs(wanted) do
		if current[index] ~= id then
			return false
		end
	end

	return true
end

Addon.SectionArrangement = SectionArrangement
