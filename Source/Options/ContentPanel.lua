local _, Addon = ...

local Keys = Addon.PreferenceKeys

---@class ContentPanel
local ContentPanel = {}

---@param category table
---@param catalog Preference[]
---@param preferences Preferences
---@return table subcategory
function ContentPanel.Register(category, catalog, preferences)
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_CONTENT,
		subtitle = Addon.L.PAGE_CONTENT_HINT,
	})

	page:Mount({
		{
			title = Addon.L.SECTION_ORDER,
			rows = {
				{
					{
						key = Keys.SECTION_ARRANGEMENT,
						span = 2,
						build = Addon.SectionOrderCard.Cell,
					},
				},
			},
		},
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
					{ key = Keys.COLLAPSE_IN_CHALLENGE },
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
