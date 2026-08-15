local _, Addon = ...

local Keys = Addon.PreferenceKeys

local VERSION_WIDTH = 96
local STATE_WIDTH = 110
local COLUMN_SPACING = 16
local ROW_PADDING = 14
local HEADER_HEIGHT = 38
local MISSING_VERSION = "-"

---@class IntegrationPanel
local IntegrationPanel = {}

---@class IntegrationRow
---@field key string
---@field name string
---@field description string
---@field isAvailable fun(): boolean
---@field version fun(): string
---@field installedVersion fun(): string?

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

---@param card table
---@param text string
---@param x number
---@param width number?
local function HeaderColumn(card, text, x, width)
	local Theme = Addon.OptionsTheme
	local label = card:CreateFontString(nil, "ARTWORK")
	label:SetFontObject(Addon.OptionsFonts.EYEBROW)
	label:SetPoint("TOPLEFT", x, -Theme.CARD_PADDING)
	label:SetText(text:upper())
	label:SetTextColor(Theme.ACCENT_COLOR.red, Theme.ACCENT_COLOR.green, Theme.ACCENT_COLOR.blue)

	if width then
		label:SetWidth(width)
		label:SetJustifyH("LEFT")
	end
end

---@param card table
---@param preferences Preferences
---@param row IntegrationRow
---@param top number
---@param nameWidth number
---@return table line
---@return number height
local function AddRow(card, preferences, row, top, nameWidth)
	local Theme = Addon.OptionsTheme
	local Fonts = Addon.OptionsFonts
	local Controls = Addon.OptionsControls

	local name = card:CreateFontString(nil, "ARTWORK")
	name:SetFontObject(Fonts.STRONG)
	name:SetPoint("TOPLEFT", Theme.CARD_PADDING, -top)
	name:SetText(row.name)

	local description = card:CreateFontString(nil, "ARTWORK")
	description:SetFontObject(Fonts.HINT)
	description:SetPoint("TOPLEFT", Theme.CARD_PADDING, -(top + name:GetStringHeight() + 4))
	description:SetWidth(nameWidth)
	description:SetJustifyH("LEFT")
	description:SetText(row.description)

	local versionX = Theme.CARD_PADDING + nameWidth + COLUMN_SPACING

	local version = card:CreateFontString(nil, "ARTWORK")
	version:SetFontObject(Fonts.MONO)
	version:SetPoint("TOPLEFT", versionX, -(top + 2))
	version:SetWidth(VERSION_WIDTH)
	version:SetJustifyH("LEFT")

	local badge = Controls.Badge(card, "", Theme.HINT_COLOR)
	badge:SetPoint("TOPLEFT", versionX + VERSION_WIDTH + COLUMN_SPACING, -top)

	local switch = Controls.Switch(card, {
		get = function()
			return preferences:Get(row.key) == true
		end,
		set = function(value)
			preferences:Set(row.key, value)
		end,
		isEnabled = row.isAvailable,
	})
	switch:SetPoint("TOPRIGHT", -Addon.OptionsTheme.CARD_PADDING, -(top - 4))

	local line = {}

	function line:Refresh()
		switch:Refresh()

		if row.isAvailable() then
			local isOn = preferences:Get(row.key) == true

			name:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)
			description:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)
			version:SetText(row.version())
			version:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

			if isOn then
				badge:Paint(Addon.L.INTEGRATION_STATE_ACTIVE, Theme.ACCENT_COLOR)
			else
				badge:Paint(Addon.L.INTEGRATION_STATE_OFF, Theme.MUTED_COLOR)
			end

			return
		end

		local installed = row.installedVersion()

		name:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)
		description:SetTextColor(Theme.FAINT_COLOR.red, Theme.FAINT_COLOR.green, Theme.FAINT_COLOR.blue)
		version:SetText(installed or MISSING_VERSION)
		version:SetTextColor(Theme.FAINT_COLOR.red, Theme.FAINT_COLOR.green, Theme.FAINT_COLOR.blue)
		badge:Paint(installed and Addon.L.INTEGRATION_STATE_OFF or Addon.L.INTEGRATION_STATE_MISSING, Theme.FAINT_COLOR)
	end

	line:Refresh()

	local height = name:GetStringHeight() + 4 + description:GetStringHeight()

	return line, math.max(height, Theme.SWITCH_HEIGHT)
end

---@param category table
---@param preferences Preferences
---@return table subcategory
function IntegrationPanel.Register(category, preferences)
	local Theme = Addon.OptionsTheme
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_INTEGRATION,
		subtitle = Addon.L.PAGE_INTEGRATION_HINT,
	})

	local card = page:AddCard({ top = Theme.CARD_TOP })

	local nameWidth = 290

	HeaderColumn(card, Addon.L.INTEGRATION_ADDON, Theme.CARD_PADDING, nameWidth)
	HeaderColumn(card, Addon.L.INFO_VERSION, Theme.CARD_PADDING + nameWidth + COLUMN_SPACING, VERSION_WIDTH)
	HeaderColumn(
		card,
		Addon.L.INTEGRATION_STATE,
		Theme.CARD_PADDING + nameWidth + COLUMN_SPACING + VERSION_WIDTH + COLUMN_SPACING,
		STATE_WIDTH
	)

	local rule = card:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(
		Theme.BORDER_COLOR.red,
		Theme.BORDER_COLOR.green,
		Theme.BORDER_COLOR.blue,
		Theme.BORDER_COLOR.alpha
	)
	rule:SetHeight(Theme.RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
	rule:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)

	local top = HEADER_HEIGHT + ROW_PADDING
	local integrations = Integrations()

	for index, integration in ipairs(integrations) do
		local line, height = AddRow(card, preferences, integration, top, nameWidth)
		page:AddRefresh(line)

		top = top + height + ROW_PADDING

		if index < #integrations then
			local divider = card:CreateTexture(nil, "ARTWORK")
			divider:SetColorTexture(
				Theme.DIVIDER_COLOR.red,
				Theme.DIVIDER_COLOR.green,
				Theme.DIVIDER_COLOR.blue,
				Theme.DIVIDER_COLOR.alpha
			)
			divider:SetHeight(Theme.RULE_THICKNESS)
			divider:SetPoint("TOPLEFT", 0, -top)
			divider:SetPoint("TOPRIGHT", 0, -top)

			top = top + Theme.RULE_THICKNESS + ROW_PADDING
		end
	end

	local height = top + Theme.CARD_PADDING - ROW_PADDING
	card:SetHeight(height)
	page:GrowContent(Theme.CARD_TOP + height + Theme.CARD_GAP)

	return page:RegisterUnder(category)
end

Addon.IntegrationPanel = IntegrationPanel
