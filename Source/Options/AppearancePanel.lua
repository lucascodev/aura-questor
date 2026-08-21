local _, Addon = ...

local Keys = Addon.PreferenceKeys

---@class AppearancePanel
local AppearancePanel = {}

---@param category table
---@param catalog Preference[]
---@param preferences Preferences
---@return table subcategory
function AppearancePanel.Register(category, catalog, preferences)
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_APPEARANCE,
		subtitle = Addon.L.PAGE_APPEARANCE_HINT,
	})

	local height = Addon.PreferenceLookup.Find(catalog, Keys.TRACKER_HEIGHT)

	--- Measured when the page shows, not at load: the interface scale only
	--- applies later, and before that the screen reports another size.
	local function HeightCeiling()
		return Addon.PreferenceBounds.Maximum(height, GetScreenHeight())
	end

	page:Mount({
		{
			title = Addon.L.SECTION_WINDOW,
			rows = {
				{
					{ key = Keys.TRACKER_WIDTH },
					{ key = Keys.TRACKER_HEIGHT, maximum = HeightCeiling },
				},
				{
					{ key = Keys.TRACKER_SCALE, suffix = "%" },
					{ key = Keys.PANEL_OPACITY, suffix = "%" },
				},
				{
					{ key = Keys.AUTO_HEIGHT, span = 2 },
				},
				"divider",
				{
					{ key = Keys.EDIT_MODE, span = 2 },
				},
			},
		},
		{
			title = Addon.L.SECTION_TEXT,
			rows = {
				{
					{ key = Keys.FONT_NAME, choices = Addon.MediaLibrary.FontChoices },
					{ key = Keys.FONT_SIZE },
				},
				{
					{ key = Keys.FONT_FLAG },
					{ key = Keys.FONT_SHADOW },
				},
				{
					{ key = Keys.WRAP_LONG_TEXT },
				},
			},
		},
	}, { catalog = catalog, preferences = preferences })

	return page:RegisterUnder(category)
end

Addon.AppearancePanel = AppearancePanel
