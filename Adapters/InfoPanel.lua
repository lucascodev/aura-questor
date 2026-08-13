local _, Addon = ...

local PAGE_NAME = "Informações"
local SUBTITLE = "Rastreador de objetivos próprio, construído sobre as APIs públicas do jogo."

--- Measured from the top of the page. The title is set in the huge font, which
--- is far taller than it looks in a constant — the first spacing here left the
--- subtitle printed across it.
local PADDING = 20
local SUBTITLE_GAP = 56
local RULE_GAP = 82
local FIRST_LINE_GAP = 104
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

--- The about page.
---
--- Built as a canvas rather than a list because a list page is made of
--- controls, and there is nothing here to change — only to read. It also
--- borrows the tracker's own look: quiet labels, gold values, and a rule with a
--- bright head, so the options page and the tracker read as one addon.
---@class InfoPanel
local InfoPanel = {}

---@param frame table
---@param color table
---@param width number
---@param offset number
---@return table
local function AddRule(frame, color, width, offset)
	local rule = frame:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	rule:SetSize(width, RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", PADDING, offset)

	return rule
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

---@param category table Parent category the page hangs under.
---@param addonInfo AddonInfo
---@param entries { label: string, value: string }[]
function InfoPanel.Register(category, addonInfo, entries)
	local frame = CreateFrame("Frame")
	frame.name = PAGE_NAME

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(addonInfo.title)

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	subtitle:SetPoint("TOPLEFT", PADDING, -SUBTITLE_GAP)
	subtitle:SetText(SUBTITLE)
	subtitle:SetTextColor(SUBTITLE_COLOR.red, SUBTITLE_COLOR.green, SUBTITLE_COLOR.blue)

	-- The same rule the tracker draws under a section: a long quiet line with a
	-- short bright segment at its head.
	AddRule(frame, RULE_COLOR, RULE_WIDTH, -RULE_GAP)
	AddRule(frame, ACCENT_COLOR, ACCENT_WIDTH, -RULE_GAP)

	local offset = -FIRST_LINE_GAP

	for _, entry in ipairs(entries) do
		AddLine(frame, offset, entry.label, entry.value)
		offset = offset - LINE_HEIGHT
	end

	Settings.RegisterCanvasLayoutSubcategory(category, frame, PAGE_NAME)
end

Addon.InfoPanel = InfoPanel
