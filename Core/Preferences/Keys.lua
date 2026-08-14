local _, Addon = ...

--- Stable identifiers for every preference.
--- They double as SavedVariables keys, so renaming one silently discards the
--- value the player had saved.
local PreferenceKeys = {
	ANNOUNCE_ON_LOAD = "announceOnLoad",
	SOUND_ENABLED = "soundEnabled",
	SOUND_QUEST_COMPLETE = "soundQuestComplete",
	SOUND_CHANNEL = "soundChannel",
	OWN_TRACKER_ENABLED = "ownTrackerEnabled",
	KEEP_BLIZZARD_TRACKER = "keepBlizzardTracker",
	BONUS_ZONE_WIDE = "bonusZoneWide",
	EVENTS_ENABLED = "eventsEnabled",
	SORT_MODE = "sortMode",
	COMPLETED_AT_TOP = "completedAtTop",
	TRACKER_WIDTH = "trackerWidth",
	TRACKER_HEIGHT = "trackerHeight",
	PANEL_OPACITY = "panelOpacity",
	TRACKER_SCALE = "trackerScale",
	EDIT_MODE = "editMode",
	FONT_NAME = "fontName",
	FONT_SIZE = "fontSize",
	FONT_FLAG = "fontFlag",
	FONT_SHADOW = "fontShadow",
	WRAP_LONG_TEXT = "wrapLongText",
	BACKGROUND_TEXTURE = "backgroundTexture",
	BACKGROUND_COLOR = "backgroundColor",
	BACKGROUND_INSET = "backgroundInset",
	BORDER_TEXTURE = "borderTexture",
	BORDER_COLOR = "borderColor",
	BORDER_CLASS_COLOR = "borderClassColor",
	BORDER_OPACITY = "borderOpacity",
	BORDER_THICKNESS = "borderThickness",
	PROGRESS_BAR_TEXTURE = "progressBarTexture",
	SHOW_FILTER_BUTTON = "showFilterButton",
	SHOW_ACHIEVEMENT_BUTTON = "showAchievementButton",
	SHOW_MINIMAP_BUTTON = "showMinimapButton",
	SHOW_ITEM_BUTTONS = "showItemButtons",
}

Addon.PreferenceKeys = PreferenceKeys
