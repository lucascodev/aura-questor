local _, Addon = ...

local Keys = Addon.PreferenceKeys

---@class FramePanel
local FramePanel = {}

---@param category table
---@param catalog Preference[]
---@param preferences Preferences
---@return table subcategory
function FramePanel.Register(category, catalog, preferences)
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_FRAME,
		subtitle = Addon.L.PAGE_FRAME_HINT,
	})

	page:Mount({
		{
			title = Addon.L.SECTION_BACKGROUND,
			rows = {
				{
					{ key = Keys.BACKGROUND_TEXTURE, choices = Addon.MediaLibrary.BackgroundChoices },
					{ key = Keys.BACKGROUND_COLOR },
				},
				{
					{ key = Keys.BACKGROUND_INSET },
				},
			},
		},
		{
			title = Addon.L.SECTION_BORDER,
			rows = {
				{
					{ key = Keys.BORDER_TEXTURE, choices = Addon.MediaLibrary.BorderChoices },
					{ key = Keys.BORDER_COLOR },
				},
				{
					{ key = Keys.BORDER_THICKNESS },
					{ key = Keys.BORDER_OPACITY, suffix = "%" },
				},
				"divider",
				{
					{ key = Keys.BORDER_CLASS_COLOR, span = 2 },
				},
			},
		},
		{
			title = Addon.L.SECTION_PROGRESS_BAR,
			rows = {
				{
					{ key = Keys.PROGRESS_BAR_TEXTURE, choices = Addon.MediaLibrary.ProgressBarChoices },
					{ key = Keys.PROGRESS_BAR_HEIGHT },
				},
			},
		},
	}, { catalog = catalog, preferences = preferences })

	return page:RegisterUnder(category)
end

Addon.FramePanel = FramePanel
