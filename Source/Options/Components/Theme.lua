local _, Addon = ...

local CARD_PADDING = 16
local COLUMN_WIDTH = 280
local COLUMN_GUTTER = 24

---@class OptionsTheme
local OptionsTheme = {
	PADDING = 20,
	CARD_PADDING = CARD_PADDING,
	CARD_GAP = 16,
	CARD_TOP = 6,
	SCROLL_TOP = 78,
	CARD_TITLE_BLOCK = 26,
	ROW_GAP = 12,
	COLUMN_WIDTH = COLUMN_WIDTH,
	COLUMN_GUTTER = COLUMN_GUTTER,
	COLUMN_OFFSET = COLUMN_WIDTH + COLUMN_GUTTER,
	HEADER_TOP = 20,
	HEADER_SUBTITLE_GAP = 44,
	HEADER_RULE_GAP = 66,
	HEADER_ACCENT_WIDTH = 60,
	RULE_THICKNESS = 1,
	SWITCH_WIDTH = 26,
	SWITCH_HEIGHT = 26,
	INPUT_HEIGHT = 28,
	FACT_LABEL_WIDTH = 88,
	FACT_LINE_HEIGHT = 20,

	PAGE_COLOR = { red = 0.02, green = 0.02, blue = 0.035, alpha = 1 },
	CARD_BACKGROUND_COLOR = { red = 0.055, green = 0.055, blue = 0.09, alpha = 1 },
	INPUT_COLOR = { red = 0.08, green = 0.08, blue = 0.12, alpha = 1 },
	BORDER_COLOR = { red = 0.26, green = 0.24, blue = 0.2, alpha = 0.9 },
	BORDER_STRONG_COLOR = { red = 0.36, green = 0.33, blue = 0.27, alpha = 1 },
	DIVIDER_COLOR = { red = 0.14, green = 0.13, blue = 0.11, alpha = 1 },
	TEXT_COLOR = { red = 0.92, green = 0.9, blue = 0.85 },
	MUTED_COLOR = { red = 0.66, green = 0.63, blue = 0.57 },
	HINT_COLOR = { red = 0.55, green = 0.53, blue = 0.48 },
	FAINT_COLOR = { red = 0.35, green = 0.34, blue = 0.3 },
	ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 },
	SECONDARY_COLOR = { red = 0.45, green = 0.65, blue = 0.9, alpha = 1 },
	DANGER_COLOR = { red = 0.937, green = 0.267, blue = 0.267, alpha = 1 },
}

Addon.OptionsTheme = OptionsTheme
