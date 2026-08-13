local _, Addon = ...

local CHANNEL_MAXIMUM = 255
local HEX_FORMAT = "%02X%02X%02X"
local HEX_BASE = 16

---@class HexColor
local HexColor = {}

---@param hex string
---@return number red
---@return number green
---@return number blue
function HexColor.ToRGB(hex)
	local red = tonumber(hex:sub(1, 2), HEX_BASE) or 0
	local green = tonumber(hex:sub(3, 4), HEX_BASE) or 0
	local blue = tonumber(hex:sub(5, 6), HEX_BASE) or 0

	return red / CHANNEL_MAXIMUM, green / CHANNEL_MAXIMUM, blue / CHANNEL_MAXIMUM
end

---@param red number
---@param green number
---@param blue number
---@return string
function HexColor.FromRGB(red, green, blue)
	return HEX_FORMAT:format(
		red * CHANNEL_MAXIMUM,
		green * CHANNEL_MAXIMUM,
		blue * CHANNEL_MAXIMUM
	)
end

Addon.HexColor = HexColor
