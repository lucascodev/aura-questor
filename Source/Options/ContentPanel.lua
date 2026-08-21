local _, Addon = ...

local Keys = Addon.PreferenceKeys

---@class ContentPanel
local ContentPanel = {}

---@param category table
---@param catalog Preference[]
---@param preferences Preferences
---@param commands table Reading and arranging the tracker's sections.
---@return table subcategory
function ContentPanel.Register(category, catalog, preferences, commands)
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_CONTENT,
		subtitle = Addon.L.PAGE_CONTENT_HINT,
	})

	page:Mount({
		{
			title = Addon.L.SECTION_LIST,
			rows = {
				{
					{ key = Keys.SORT_MODE, style = "dropdownRow", span = 2 },
				},
				"divider",
				{
					{ key = Keys.COMPLETED_AT_TOP },
					{ key = Keys.EVENTS_ENABLED },
				},
				{
					{ key = Keys.WORLD_QUESTS_ENABLED },
					{ key = Keys.BONUS_ZONE_WIDE },
				},
				{
					{ key = Keys.WORLD_QUEST_SCOPE },
				},
				{
					{ key = Keys.INSTANCE_FOCUS },
					{ key = Keys.HIDE_WHEN_EMPTY },
				},
				{
					{ key = Keys.AUTO_EXPAND },
				},
			},
		},
		{
			title = Addon.L.PREF_SECTION_ORDER,
			rows = {
				{
					{ build = Addon.OptionsSectionList.Cell(commands), span = 2 },
				},
			},
		},
		{
			title = Addon.L.SECTION_BUTTONS,
			rows = {
				{
					{ key = Keys.SHOW_FILTER_BUTTON },
					{ key = Keys.SHOW_ACHIEVEMENT_BUTTON },
				},
				{
					{ key = Keys.SHOW_INTEGRATION_BUTTON },
					{ key = Keys.SHOW_MINIMAP_BUTTON },
				},
				{
					{ key = Keys.SHOW_ITEM_BUTTONS },
				},
			},
		},
		{
			title = Addon.L.SECTION_SOUND,
			rows = {
				{
					{ key = Keys.SOUND_ENABLED, span = 2 },
				},
				{
					{ key = Keys.SOUND_QUEST_COMPLETE, choices = Addon.SoundLibrary.Choices },
					{ key = Keys.SOUND_CHANNEL },
				},
			},
		},
	}, { catalog = catalog, preferences = preferences })

	return page:RegisterUnder(category)
end

Addon.ContentPanel = ContentPanel
