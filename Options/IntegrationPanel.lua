local _, Addon = ...

local Keys = Addon.PreferenceKeys

local PAGE_NAME = Addon.L.PAGE_INTEGRATION
local VERSION_LABEL = Addon.L.INTEGRATION_VERSION
local ADDONS_LABEL = Addon.L.INTEGRATION_ADDONS
local MISSING_VERSION = "---"

local PADDING = 20
local TITLE_GAP = 56
local SECTION_TOP = 92
local LIST_TOP = 108
local BOX_PADDING = 14
local ROW_HEIGHT = 64
local VERSION_INDENT = 36
local VERSION_GAP = 26
local DESCRIPTION_LEFT = 300
local DESCRIPTION_WIDTH = 330

local RULE_THICKNESS = 1
local RULE_WIDTH = 420
local ACCENT_WIDTH = 60
local RULE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }

--- A caixa com borda de tooltip é a convenção das páginas de opções clássicas,
--- desenhada por arquivo de textura em vez de template, que muda menos.
local BOX_BACKDROP = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local BOX_BACKGROUND_COLOR = { red = 0.08, green = 0.08, blue = 0.08, alpha = 0.8 }

local MISSING_COLOR = { red = 0.55, green = 0.55, blue = 0.55 }
local DESCRIPTION_COLOR = { red = 1, green = 1, blue = 1 }

local ACTIVE_VALUE = "|cff66d966%s|r"

--- Integrações com outros addons, uma linha por addon, desenhada à mão: a
--- Settings API não tem como desabilitar um controle com o motivo ao lado.
---@class IntegrationPanel
local IntegrationPanel = {}

---@class IntegrationRow
---@field key string Preferência que liga e desliga a integração.
---@field name string Nome próprio do addon, igual em qualquer idioma.
---@field description string
---@field isAvailable fun(): boolean
---@field version fun(): string
---@field installedVersion fun(): string? Presente mesmo com o addon desligado.

---@return IntegrationRow[]
local function Integrations()
	return {
		{
			key = Keys.TOMTOM_ENABLED,
			name = "TomTom",
			description = Addon.L.TOMTOM_DESCRIPTION,
			isAvailable = Addon.TomTomArrow.IsAvailable,
			version = Addon.TomTomArrow.Version,
			installedVersion = Addon.TomTomArrow.InstalledVersion,
		},
	}
end

---@param frame table
---@param color table
---@param width number
local function AddRule(frame, color, width)
	local rule = frame:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	rule:SetSize(width, RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", PADDING, -TITLE_GAP)
end

---@param box table
---@param preferences Preferences
---@param row IntegrationRow
---@param offset number
---@return table
local function AddRow(box, preferences, row, offset)
	local checkbox = Addon.PanelControls.ClassicCheckbox(box, {
		label = row.name,
		get = function()
			return preferences:Get(row.key) == true
		end,
		set = function(value)
			preferences:Set(row.key, value)
		end,
		isEnabled = row.isAvailable,
	})
	checkbox:SetPoint("TOPLEFT", BOX_PADDING, offset)

	local version = box:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("TOPLEFT", BOX_PADDING + VERSION_INDENT, offset - VERSION_GAP)

	local description = box:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", DESCRIPTION_LEFT, offset - 6)
	description:SetWidth(DESCRIPTION_WIDTH)
	description:SetJustifyH("LEFT")
	description:SetText(row.description)

	return {
		Refresh = function()
			checkbox:Refresh()

			version:SetTextColor(MISSING_COLOR.red, MISSING_COLOR.green, MISSING_COLOR.blue)

			if row.isAvailable() then
				version:SetText(VERSION_LABEL:format(ACTIVE_VALUE:format(row.version())))
				description:SetTextColor(
					DESCRIPTION_COLOR.red,
					DESCRIPTION_COLOR.green,
					DESCRIPTION_COLOR.blue
				)
				return
			end

			version:SetText(VERSION_LABEL:format(row.installedVersion() or MISSING_VERSION))
			description:SetTextColor(MISSING_COLOR.red, MISSING_COLOR.green, MISSING_COLOR.blue)
		end,
	}
end

---@param category table
---@param preferences Preferences
---@return table subcategory
function IntegrationPanel.Register(category, preferences)
	local frame = CreateFrame("Frame")
	frame.name = PAGE_NAME

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(PAGE_NAME)

	AddRule(frame, RULE_COLOR, RULE_WIDTH)
	AddRule(frame, ACCENT_COLOR, ACCENT_WIDTH)

	local section = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section:SetPoint("TOPLEFT", PADDING, -SECTION_TOP)
	section:SetText(ADDONS_LABEL)

	local integrations = Integrations()

	local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	box:SetBackdrop(BOX_BACKDROP)
	box:SetBackdropColor(
		BOX_BACKGROUND_COLOR.red,
		BOX_BACKGROUND_COLOR.green,
		BOX_BACKGROUND_COLOR.blue,
		BOX_BACKGROUND_COLOR.alpha
	)
	box:SetPoint("TOPLEFT", PADDING, -LIST_TOP)
	box:SetPoint("TOPRIGHT", -PADDING, -LIST_TOP)
	box:SetHeight(#integrations * ROW_HEIGHT + BOX_PADDING * 2)

	local rows = {}
	local offset = -BOX_PADDING

	for _, integration in ipairs(integrations) do
		table.insert(rows, AddRow(box, preferences, integration, offset))
		offset = offset - ROW_HEIGHT
	end

	frame:SetScript("OnShow", function()
		for _, row in ipairs(rows) do
			row.Refresh()
		end
	end)

	return (Settings.RegisterCanvasLayoutSubcategory(category, frame, PAGE_NAME))
end

Addon.IntegrationPanel = IntegrationPanel
