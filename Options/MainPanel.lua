local _, Addon = ...

local SUBTITLE = Addon.L.INFO_SUBTITLE

local PADDING = 20
local SUBTITLE_GAP = 56
local RULE_GAP = 82
local CONTROLS_TOP = 108
local CONTROL_HEIGHT = 36
local FACTS_GAP = 24
local LINE_HEIGHT = 24
local LABEL_WIDTH = 110

local RULE_THICKNESS = 1
local ACCENT_WIDTH = 60
local RULE_WIDTH = 420

local SUBTITLE_COLOR = { red = 0.62, green = 0.58, blue = 0.50 }
local LABEL_COLOR = { red = 0.62, green = 0.58, blue = 0.50 }
local VALUE_COLOR = { red = 1, green = 0.82, blue = 0 }
local RULE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }

--- A página raiz: os interruptores gerais e os fatos do addon num lugar só,
--- para a primeira tela já apresentar o que ele é.
---@class MainPanel
local MainPanel = {}

---@param frame table
---@param color table
---@param width number
local function AddRule(frame, color, width)
	local rule = frame:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	rule:SetSize(width, RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", PADDING, -RULE_GAP)
end

---@param frame table
---@param offset number
---@param label string
---@param value string
local function AddLine(frame, offset, label, value)
	local labelText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	labelText:SetPoint("TOPLEFT", PADDING, offset)
	labelText:SetText(label)
	labelText:SetTextColor(LABEL_COLOR.red, LABEL_COLOR.green, LABEL_COLOR.blue)

	local valueText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	valueText:SetPoint("TOPLEFT", PADDING + LABEL_WIDTH, offset)
	valueText:SetText(value)
	valueText:SetTextColor(VALUE_COLOR.red, VALUE_COLOR.green, VALUE_COLOR.blue)
end

--- As preferências sem página são as gerais, e moram na raiz.
---@param catalog Preference[]
---@return Preference[]
local function RootPreferences(catalog)
	local roots = {}

	for _, preference in ipairs(catalog) do
		if not preference.page and not preference.panel then
			table.insert(roots, preference)
		end
	end

	return roots
end

---@param addonInfo AddonInfo
---@param catalog Preference[]
---@param preferences Preferences
---@param entries { label: string, value: string }[]
---@return table category
function MainPanel.Register(addonInfo, catalog, preferences, entries)
	local frame = CreateFrame("Frame")
	frame.name = addonInfo.title

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(addonInfo.title)

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", PADDING, -SUBTITLE_GAP)
	subtitle:SetText(SUBTITLE)
	subtitle:SetTextColor(SUBTITLE_COLOR.red, SUBTITLE_COLOR.green, SUBTITLE_COLOR.blue)

	AddRule(frame, RULE_COLOR, RULE_WIDTH)
	AddRule(frame, ACCENT_COLOR, ACCENT_WIDTH)

	local controls = {}
	local offset = -CONTROLS_TOP

	for _, preference in ipairs(RootPreferences(catalog)) do
		local checkbox = Addon.PanelControls.ClassicCheckbox(frame, {
			label = preference.label,
			tooltip = preference.tooltip,
			get = function()
				return preferences:Get(preference.key) == true
			end,
			set = function(value)
				preferences:Set(preference.key, value)
			end,
		})
		checkbox:SetPoint("TOPLEFT", PADDING, offset)
		table.insert(controls, checkbox)

		offset = offset - CONTROL_HEIGHT
	end

	offset = offset - FACTS_GAP

	for _, entry in ipairs(entries) do
		AddLine(frame, offset, entry.label, entry.value)
		offset = offset - LINE_HEIGHT
	end

	frame:SetScript("OnShow", function()
		for _, control in ipairs(controls) do
			control:Refresh()
		end
	end)

	return Settings.RegisterCanvasLayoutCategory(frame, addonInfo.title)
end

Addon.MainPanel = MainPanel
