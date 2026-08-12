local ADDON_NAME, Addon = ...

--- Reads the .toc metadata so version and title live in exactly one place.
---@class AddonMetadata
local AddonMetadata = {}

---@param field string
---@param fallback string
---@return string
local function ReadMetadata(field, fallback)
	local value = C_AddOns.GetAddOnMetadata(ADDON_NAME, field)
	if not value or value == "" then
		return fallback
	end
	return value
end

---@return string
function AddonMetadata.GetTitle()
	return ReadMetadata("Title", ADDON_NAME)
end

---@return string
function AddonMetadata.GetVersion()
	return ReadMetadata("Version", "0.0.0")
end

Addon.AddonMetadata = AddonMetadata
