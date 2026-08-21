local _, Addon = ...

--- An addon only shows up under Options → AddOns if it registers a category.
--- Every page is a canvas drawn by the addon; the Settings API only provides
--- the tree. The price, accepted on purpose: no native search and no Defaults
--- button, in exchange for full control of label, hint and value.
---@class OptionsPanel
---@field private addonInfo AddonInfo
---@field private catalog Preference[]
---@field private preferences Preferences
---@field private category table?
---@field private panels table<string, table>
local OptionsPanel = {}
OptionsPanel.__index = OptionsPanel

--- The pages, in the order the tree shows them.
local PANELS = {
	{
		name = "appearance",
		register = function(category, catalog, preferences)
			return Addon.AppearancePanel.Register(category, catalog, preferences)
		end,
	},
	{
		name = "frame",
		register = function(category, catalog, preferences)
			return Addon.FramePanel.Register(category, catalog, preferences)
		end,
	},
	{
		name = "content",
		register = function(category, catalog, preferences, sectionCommands)
			return Addon.ContentPanel.Register(category, catalog, preferences, sectionCommands)
		end,
	},
	{
		name = "integration",
		register = function(category, _, preferences)
			return Addon.IntegrationPanel.Register(category, preferences)
		end,
	},
}

---@param addonInfo AddonInfo
---@param catalog Preference[]
---@param preferences Preferences
---@param info { label: string, value: string }[] Read-only facts for the root page.
---@param choiceProviders table<string, fun(): PreferenceChoice[]> Lists resolved on open.
---@param profileCommands table Everything the profile page can do.
---@param logger ChatLogger
---@param sectionCommands table Reading and arranging the tracker's sections.
---@return OptionsPanel
function OptionsPanel.New(
	addonInfo,
	catalog,
	preferences,
	info,
	choiceProviders,
	profileCommands,
	logger,
	sectionCommands
)
	return setmetatable({
		addonInfo = addonInfo,
		catalog = catalog,
		preferences = preferences,
		panels = {},
		info = info,
		choiceProviders = choiceProviders or {},
		profileCommands = profileCommands,
		logger = logger,
		sectionCommands = sectionCommands,
	}, OptionsPanel)
end

function OptionsPanel:Register()
	local category = Addon.MainPanel.Register(
		self.addonInfo,
		self.catalog,
		self.preferences,
		self.info
	)

	for _, panel in ipairs(PANELS) do
		self.panels[panel.name] = panel.register(
			category,
			self.catalog,
			self.preferences,
			self.sectionCommands
		)
	end

	Addon.ProfilePanel.Register(category, self.profileCommands)

	Settings.RegisterAddOnCategory(category)
	self.category = category
end

--- Every page is hand drawn, so writing goes straight to the store; the pages
--- re-read their values on show.
---@param key string
---@param value boolean|number|string
function OptionsPanel:SelectValue(key, value)
	self.preferences:Set(key, value)
end

--- A Blizzard protege a abertura do painel em combate; tentar mesmo assim
--- raises a blocked action in the addon's name, so the click becomes a warning.
---@private
---@return boolean
function OptionsPanel:CanOpenNow()
	if not InCombatLockdown() then
		return true
	end

	self.logger:Warn(Addon.L.OPTIONS_IN_COMBAT)

	return false
end

function OptionsPanel:Open()
	if not self:CanOpenNow() then
		return
	end

	Settings.OpenToCategory(self.category:GetID())
end

function OptionsPanel:OpenIntegrations()
	if not self:CanOpenNow() then
		return
	end

	local panel = self.panels.integration

	if type(panel) == "table" then
		Settings.OpenToCategory(panel:GetID())
		return
	end

	self:Open()
end

Addon.OptionsPanel = OptionsPanel
