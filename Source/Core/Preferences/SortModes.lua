local _, Addon = ...
local L = Addon.L

--- How the entries inside a section may be ordered.
---
--- Each mode is a comparator over the tracker's own entry structure, so none of
--- them knows the game exists and all of them are testable without it. The
--- default keeps whatever order the source handed over, which for quests is the
--- order the player tracked them in.
---@class SortMode
---@field id string
---@field label string
---@field compare? fun(left: TrackerEntry, right: TrackerEntry): boolean

---@type SortMode[]
local SortModes = {
	{
		id = "none",
		label = L.SORT_NONE,
	},
	{
		id = "level",
		label = L.SORT_LEVEL,
		compare = function(left, right)
			return (left.level or 0) < (right.level or 0)
		end,
	},
	{
		id = "group",
		label = L.SORT_GROUP,
		compare = function(left, right)
			return (left.groupName or "") < (right.groupName or "")
		end,
	},
	{
		id = "title",
		label = L.SORT_TITLE,
		compare = function(left, right)
			return left.title < right.title
		end,
	},
	{
		id = "recent",
		label = L.SORT_RECENT,
		-- Only quests carry an arrival, so every other kind of entry settles at
		-- the bottom of its own section, in whatever order the source gave.
		compare = function(left, right)
			return (left.arrival or 0) > (right.arrival or 0)
		end,
	},
}

Addon.SortModes = SortModes
