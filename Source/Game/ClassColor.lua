local _, Addon = ...

local PLAYER = "player"

---@class ClassColor
local ClassColor = {}

---@return TrackerColor
function ClassColor.Current()
	local _, classFile = UnitClass(PLAYER)
	local color = RAID_CLASS_COLORS[classFile]

	return { red = color.r, green = color.g, blue = color.b }
end

Addon.ClassColor = ClassColor
