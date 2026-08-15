local _, Addon = ...
local L = Addon.L

local NO_FLAGS = ""
local NONE_ID = "none"

---@class FontFlags
local FontFlags = {}

---@type PreferenceChoice[]
FontFlags.Choices = {
	{ id = NONE_ID, label = L.FONT_FLAG_NONE },
	{ id = "OUTLINE", label = L.FONT_FLAG_OUTLINE },
	{ id = "THICKOUTLINE", label = L.FONT_FLAG_THICK_OUTLINE },
	{ id = "MONOCHROME", label = L.FONT_FLAG_MONOCHROME },
	{ id = "MONOCHROME,OUTLINE", label = L.FONT_FLAG_MONOCHROME_OUTLINE },
}

---@param id string
---@return string
function FontFlags.Resolve(id)
	if id == NONE_ID then
		return NO_FLAGS
	end

	return id
end

Addon.FontFlags = FontFlags
