local ADDON_NAME, Addon = ...

--- Reads the .toc metadata so version and title live in exactly one place.
---@class AddonMetadata
local AddonMetadata = {}

---@param field string
---@param fallback string
---@return string
local function ReadField(field, fallback)
	local value = C_AddOns.GetAddOnMetadata(ADDON_NAME, field)
	if not value or value == "" then
		return fallback
	end
	return value
end

---@return AddonInfo
function AddonMetadata.Read()
	return {
		title = ReadField("Title", ADDON_NAME),
		version = ReadField("Version", "0.0.0"),
	}
end

Addon.AddonMetadata = AddonMetadata
