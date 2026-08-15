local _, Addon = ...

local SHADOW_OFFSET_X = 1
local SHADOW_OFFSET_Y = -1
local NO_SHADOW_OFFSET = 0
local SHADOW_COLOR = { red = 0, green = 0, blue = 0, alpha = 1 }

local MONO_PATH = [[Interface\AddOns\AuraTrackerQuestor\Media\Fonts\JetBrainsMono-Regular.ttf]]

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

--- Números alinham em mono; o resto do estilo acompanha a fonte escolhida.
---@param fontString table
---@param style TrackerFontStyle
---@param sizeDelta number
function FontStyler.ApplyMono(fontString, style, sizeDelta)
	FontStyler.Apply(fontString, style, sizeDelta)
	fontString:SetFont(MONO_PATH, style.size + sizeDelta, style.flags)
end

Addon.FontStyler = FontStyler
