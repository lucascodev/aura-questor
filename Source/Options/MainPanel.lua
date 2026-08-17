local _, Addon = ...

---@class MainPanel
local MainPanel = {}

---@param catalog Preference[]
---@return (SchematicCell[]|string)[]
local function SwitchRows(catalog)
	local rows = {}

	for index, preference in ipairs(Addon.PreferenceLookup.Roots(catalog)) do
		if index > 1 then
			table.insert(rows, "divider")
		end

		table.insert(rows, { { key = preference.key, span = 2 } })
	end

	return rows
end

---@param entries { label: string, value: string }[]
---@return SchematicCell[][]
local function FactRows(entries)
	local rows = {}

	for _, entry in ipairs(entries) do
		table.insert(rows, { { style = "fact", label = entry.label, value = entry.value, span = 2 } })
	end

	return rows
end

---@param addonInfo AddonInfo
---@param catalog Preference[]
---@param preferences Preferences
---@param entries { label: string, value: string }[]
---@return table category
function MainPanel.Register(addonInfo, catalog, preferences, entries)
	local page = Addon.OptionsPage.New({
		title = addonInfo.title,
		subtitle = Addon.L.INFO_SUBTITLE,
	})

	page:Mount({
		{ title = Addon.L.SECTION_GENERAL, rows = SwitchRows(catalog) },
		{ title = Addon.L.SECTION_ABOUT, rows = FactRows(entries) },
	}, { catalog = catalog, preferences = preferences })

	return page:RegisterAsRoot(addonInfo.brand)
end

Addon.MainPanel = MainPanel
