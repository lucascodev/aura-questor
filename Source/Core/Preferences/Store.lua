local _, Addon = ...

--- Current value of every preference.
--- Holds a plain table injected by the composition root, so it has no idea the
--- values happen to come from SavedVariables.
---@class Preferences
---@field private catalog Preference[]
---@field private values table<string, boolean|number>
---@field private onChanged fun(changedKey: string)
local Preferences = {}
Preferences.__index = Preferences

---@param catalog Preference[]
---@param values table<string, boolean|number>
---@param onChanged fun(changedKey: string)
---@return Preferences
function Preferences.New(catalog, values, onChanged)
	local preferences = setmetatable({
		catalog = catalog,
		values = values,
		onChanged = onChanged,
	}, Preferences)
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
	if self.values[key] == value then
		return
	end

	self.values[key] = value
	self.onChanged(key)
end

--- Devolve ao padrão de fábrica só as chaves pedidas. Cada uma é anunciada
--- como qualquer outra mudança, para quem escuta não precisar saber que a mão
--- que mexeu foi a de um botão de restaurar.
---@param keys string[]
function Preferences:Reset(keys)
	local wanted = {}

	for _, key in ipairs(keys) do
		wanted[key] = true
	end

	for _, preference in ipairs(self.catalog) do
		if wanted[preference.key] then
			self:Set(preference.key, preference.default)
		end
	end
end

--- Announces a change the Settings API already wrote into the values table on
--- its own, so a native control and a hand-built one reach the same place.
---@param key string
function Preferences:Notify(key)
	self.onChanged(key)
end

--- The raw table, for the Settings API to write into directly.
---@return table<string, boolean|number>
function Preferences:Values()
	return self.values
end

Addon.Preferences = Preferences
