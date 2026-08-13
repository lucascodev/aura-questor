local _, Addon = ...

local SHADOW_OFFSET_X = 1
local SHADOW_OFFSET_Y = -1
local NO_SHADOW_OFFSET = 0
local SHADOW_COLOR = { red = 0, green = 0, blue = 0, alpha = 1 }

---@class FontStyler
local FontStyler = {}

---@param fontString table
---@param style TrackerFontStyle
---@param sizeDelta number
function FontStyler.Apply(fontString, style, sizeDelta)
	fontString:SetFont(style.path, style.size + sizeDelta, style.flags)
	fontString:SetWordWrap(style.wrapsLongText)

	fontString:SetShadowColor(
		SHADOW_COLOR.red,
		SHADOW_COLOR.green,
		SHADOW_COLOR.blue,
		SHADOW_COLOR.alpha
	)
	fontString:SetShadowOffset(
		style.hasShadow and SHADOW_OFFSET_X or NO_SHADOW_OFFSET,
		style.hasShadow and SHADOW_OFFSET_Y or NO_SHADOW_OFFSET
	)
end

Addon.FontStyler = FontStyler
