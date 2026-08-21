local _, Addon = ...

--- Questions about the preference catalog.
---@class PreferenceLookup
local PreferenceLookup = {}

---@param catalog Preference[]
---@param key string
---@return Preference
function PreferenceLookup.Find(catalog, key)
	for _, preference in ipairs(catalog) do
		if preference.key == key then
			return preference
		end
	end

	error(Addon.L.PREF_UNKNOWN:format(key))
end

--- Preferences with no page and no panel are the general ones, and live at the
--- root.
---@param catalog Preference[]
---@return Preference[]
function PreferenceLookup.Roots(catalog)
	local roots = {}

	for _, preference in ipairs(catalog) do
		if not preference.page and not preference.panel then
			table.insert(roots, preference)
		end
	end

	return roots
end

Addon.PreferenceLookup = PreferenceLookup
