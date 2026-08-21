local _, Addon = ...

local ANCHOR = "TOPLEFT"
local SCREEN_ANCHOR = "BOTTOMLEFT"

local FACTORY_RIGHT_MARGIN = 120

--- Where the tracker window sits, as a top left corner measured from the bottom
--- left of the screen.
---
--- One corner and one pair of numbers, so a window that changes height grows
--- downwards and leaves the header where the player put it.
local TrackerPlace = {
	anchor = ANCHOR,
	screenAnchor = SCREEN_ANCHOR,
}

---@class TrackerSize
---@field width number
---@field height number

--- Against the right edge, halfway up, written as a corner like every other
--- place instead of as a different kind of anchor.
---@param window TrackerSize
---@param screen TrackerSize
---@return number left, number top
function TrackerPlace.Factory(window, screen)
	return screen.width - FACTORY_RIGHT_MARGIN - window.width, (screen.height + window.height) / 2
end

--- A place saved by a version that anchored the window some other way is
--- dropped: read as a top left corner it would land somewhere the player never
--- chose, and the factory place is at least a place they can see.
---@param saved table
---@param window TrackerSize
---@param screen TrackerSize
---@return number left, number top
function TrackerPlace.Resolve(saved, window, screen)
	local isCorner = saved.point == ANCHOR and saved.relativePoint == SCREEN_ANCHOR

	if isCorner and type(saved.x) == "number" and type(saved.y) == "number" then
		return saved.x, saved.y
	end

	return TrackerPlace.Factory(window, screen)
end

Addon.TrackerPlace = TrackerPlace
