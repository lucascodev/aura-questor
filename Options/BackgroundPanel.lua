local _, Addon = ...
local L = Addon.L

local Keys = Addon.PreferenceKeys

local PAGE_NAME = Addon.L.PAGE_BACKGROUND

local PADDING = 20
local TITLE_GAP = 56
local LABEL_ROW_GAP = 22
local ROW_GAP = 60
local COLUMN_GAP = 250

local RULE_THICKNESS = 1
local RULE_WIDTH = 420
local ACCENT_WIDTH = 60
local RULE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }

--- Background and border, drawn by hand: two of these are colours, and the
--- Settings API has no colour control to register them with.
---@class BackgroundPanel
local BackgroundPanel = {}

---@param frame table
---@param color table
---@param width number
---@param offset number
local function AddRule(frame, color, width, offset)
	local rule = frame:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	rule:SetSize(width, RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", PADDING, offset)
end

---@param preferences Preferences
---@param key string
---@return table
local function ColorAccess(preferences, key)
	return {
		get = function()
			return Addon.HexColor.ToRGB(preferences:Get(key))
		end,
		set = function(red, green, blue)
			preferences:Set(key, Addon.HexColor.FromRGB(red, green, blue))
		end,
	}
end

---@param preferences Preferences
---@param key string
---@return table
local function ValueAccess(preferences, key)
	return {
		get = function()
			return preferences:Get(key)
		end,
		set = function(value)
			preferences:Set(key, value)
		end,
	}
end

---@param catalog Preference[]
---@param key string
---@return Preference
local function Find(catalog, key)
	for _, preference in ipairs(catalog) do
		if preference.key == key then
			return preference
		end
	end

	error((Addon.L.PREF_UNKNOWN):format(key))
end

---@param context table
---@param key string
---@param choices fun(): PreferenceChoice[]
---@return table
local function Dropdown(context, key, choices)
	local preference = Find(context.catalog, key)
	local access = ValueAccess(context.preferences, key)

	return Addon.PanelControls.Dropdown(context.frame, {
		label = preference.label,
		choices = choices,
		get = access.get,
		set = access.set,
	})
end

---@param context table
---@param key string
---@return table
local function Swatch(context, key)
	local preference = Find(context.catalog, key)
	local access = ColorAccess(context.preferences, key)

	return Addon.PanelControls.ColorSwatch(context.frame, {
		label = preference.label,
		get = access.get,
		set = access.set,
	})
end

---@param context table
---@param key string
---@return table
local function Checkbox(context, key)
	local preference = Find(context.catalog, key)
	local access = ValueAccess(context.preferences, key)

	return Addon.PanelControls.Checkbox(context.frame, {
		label = preference.label,
		get = access.get,
		set = access.set,
	})
end

---@param context table
---@param key string
---@return table
local function Slider(context, key)
	local preference = Find(context.catalog, key)
	local access = ValueAccess(context.preferences, key)

	return Addon.PanelControls.Slider(context.frame, {
		label = preference.label,
		minimum = preference.minimum,
		maximum = preference.maximum,
		step = preference.step,
		get = access.get,
		set = access.set,
	})
end

---@param frame table
---@param controls table[]
local function RefreshOnShow(frame, controls)
	frame:SetScript("OnShow", function()
		for _, control in ipairs(controls) do
			control:Refresh()
		end
	end)
end

---@param category table Parent category the page hangs under.
---@param catalog Preference[]
---@param preferences Preferences
function BackgroundPanel.Register(category, catalog, preferences)
	local frame = CreateFrame("Frame")
	frame.name = PAGE_NAME

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(PAGE_NAME)

	AddRule(frame, RULE_COLOR, RULE_WIDTH, -TITLE_GAP)
	AddRule(frame, ACCENT_COLOR, ACCENT_WIDTH, -TITLE_GAP)

	local context = {
		frame = frame,
		catalog = catalog,
		preferences = preferences,
	}

	local rows = {
		{
			Dropdown(context, Keys.BACKGROUND_TEXTURE, Addon.MediaLibrary.BackgroundChoices),
			Swatch(context, Keys.BACKGROUND_COLOR),
		},
		{
			Dropdown(context, Keys.BORDER_TEXTURE, Addon.MediaLibrary.BorderChoices),
			Swatch(context, Keys.BORDER_COLOR),
		},
		{
			Checkbox(context, Keys.BORDER_CLASS_COLOR),
		},
		{
			Slider(context, Keys.BORDER_THICKNESS),
			Slider(context, Keys.BORDER_OPACITY),
		},
		{
			Slider(context, Keys.BACKGROUND_INSET),
		},
		{
			Dropdown(context, Keys.PROGRESS_BAR_TEXTURE, Addon.MediaLibrary.ProgressBarChoices),
		},
	}

	local controls = {}
	local offset = -TITLE_GAP - LABEL_ROW_GAP - ROW_GAP

	for _, row in ipairs(rows) do
		for index, control in ipairs(row) do
			control:SetPoint("TOPLEFT", PADDING + (index - 1) * COLUMN_GAP, offset)
			table.insert(controls, control)
		end

		offset = offset - ROW_GAP
	end

	RefreshOnShow(frame, controls)
	Settings.RegisterCanvasLayoutSubcategory(category, frame, PAGE_NAME)
end

Addon.BackgroundPanel = BackgroundPanel
