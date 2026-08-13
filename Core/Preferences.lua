local _, Addon = ...

--- Current value of every preference.
--- Holds a plain table injected by the composition root, so it has no idea the
--- values happen to come from SavedVariables.
---@class Preferences
---@field private catalog Preference[]
---@field private values table<string, boolean|number>
local Preferences = {}
Preferences.__index = Preferences

---@param catalog Preference[]
---@param values table<string, boolean|number>
---@return Preferences
function Preferences.New(catalog, values)
	local preferences = setmetatable({ catalog = catalog, values = values }, Preferences)
	preferences:FillGapsWithDefaults()

	return preferences
end

--- A fresh install, or a preference added by a newer version, arrives with the
--- key missing. Filling it here means nothing downstream has to handle nil.
function Preferences:FillGapsWithDefaults()
	for _, preference in ipairs(self.catalog) do
		if self.values[preference.key] == nil then
			self.values[preference.key] = preference.default
		end
	end
end

---@param key string
---@return boolean|number|string
function Preferences:Get(key)
	return self.values[key]
end

---@param key string
---@param value boolean|number|string
function Preferences:Set(key, value)
	self.values[key] = value
end

--- The raw table, for the Settings API to write into directly.
---@return table<string, boolean|number>
function Preferences:Values()
	return self.values
end

Addon.Preferences = Preferences
