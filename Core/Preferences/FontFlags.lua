local _, Addon = ...

local NO_FLAGS = ""
local NONE_ID = "none"

---@class FontFlags
local FontFlags = {}

---@type PreferenceChoice[]
FontFlags.Choices = {
	{ id = NONE_ID, label = "Nenhum" },
	{ id = "OUTLINE", label = "Contorno" },
	{ id = "THICKOUTLINE", label = "Contorno grosso" },
	{ id = "MONOCHROME", label = "Sem suavização" },
	{ id = "MONOCHROME,OUTLINE", label = "Sem suavização, com contorno" },
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
