local _, Addon = ...

--- An addon only shows up under Options → AddOns if it registers a category.
--- This does it through the native Settings API, so there is no Ace3 and no
--- hand-built frame to keep alive across patches.
---@class OptionsPanel
---@field private addonInfo AddonInfo
---@field private catalog Preference[]
---@field private preferences Preferences
---@field private category table?
---@field private settings table<string, table>
---@field private panels table<string, boolean>
local OptionsPanel = {}
OptionsPanel.__index = OptionsPanel

--- Namespaces the setting ids, which share one global registry with every
--- other addon.
local VARIABLE_PREFIX = "ATQ_"

--- The pages drawn by hand, under the name a preference points at.
local CUSTOM_PANELS = {
	background = function(category, catalog, preferences)
		Addon.BackgroundPanel.Register(category, catalog, preferences)
	end,
	integration = function(category, _, preferences)
		return Addon.IntegrationPanel.Register(category, preferences)
	end,
}

---@param addonInfo AddonInfo
---@param catalog Preference[]
---@param preferences Preferences
---@param info { label: string, value: string }[] Read-only facts for the about page.
---@param choiceProviders table<string, fun(): PreferenceChoice[]> Lists resolved on open.
---@param profileCommands table Everything the profile page can do.
---@return OptionsPanel
function OptionsPanel.New(addonInfo, catalog, preferences, info, choiceProviders, profileCommands)
	return setmetatable({
		addonInfo = addonInfo,
		catalog = catalog,
		preferences = preferences,
		settings = {},
		panels = {},
		info = info,
		choiceProviders = choiceProviders or {},
		profileCommands = profileCommands,
	}, OptionsPanel)
end

---@private
---@param category table
---@param preference Preference
function OptionsPanel:AddControl(category, preference)
	local setting = Settings.RegisterAddOnSetting(
		category,
		VARIABLE_PREFIX .. preference.key,
		preference.key,
		self.preferences:Values(),
		preference.kind,
		preference.label,
		preference.default
	)

	setting:SetValueChangedCallback(function()
		self.preferences:Notify(preference.key)
	end)
	self.settings[preference.key] = setting

	-- A dropdown's options are asked for when it opens, so a list that fills as
	-- addons load can be resolved then instead of at login.
	local provider = preference.choicesKey and self.choiceProviders[preference.choicesKey]

	if preference.choices or provider then
		Settings.CreateDropdown(category, setting, function()
			local container = Settings.CreateControlTextContainer()

			for _, choice in ipairs(provider and provider() or preference.choices) do
				container:Add(choice.id, choice.label)
			end

			return container:GetData()
		end, preference.tooltip)
		return
	end

	if preference.kind == "boolean" then
		Settings.CreateCheckbox(category, setting, preference.tooltip)
		return
	end

	local sliderOptions = Settings.CreateSliderOptions(
		preference.minimum,
		preference.maximum,
		preference.step
	)

	Settings.CreateSlider(category, setting, sliderOptions, preference.tooltip)
end

--- Registered on the first preference that names one, so a hand-built page lands
--- in the tree where the catalog puts it.
---@private
---@param category table
---@param name string
function OptionsPanel:AddPanel(category, name)
	if self.panels[name] then
		return
	end

	-- Guarda a subcategoria quando o painel a devolve, para poder abrir a
	-- página direto; true marca só que o painel já foi registrado.
	self.panels[name] = CUSTOM_PANELS[name](category, self.catalog, self.preferences) or true
end

function OptionsPanel:Register()
	-- A raiz é desenhada à mão: interruptores gerais e os fatos do addon juntos,
	-- para a primeira tela apresentar o addon em vez de esconder isso numa
	-- subpágina.
	local category = Addon.MainPanel.Register(
		self.addonInfo,
		self.catalog,
		self.preferences,
		self.info
	)
	local pages = {}

	for _, preference in ipairs(self.catalog) do
		if preference.panel then
			self:AddPanel(category, preference.panel)
		elseif preference.page then
			pages[preference.page] = pages[preference.page]
				or Settings.RegisterVerticalLayoutSubcategory(category, preference.page)
			self:AddControl(pages[preference.page], preference)
		end
	end

	Addon.ProfilePanel.Register(category, self.profileCommands)

	Settings.RegisterAddOnCategory(category)
	self.category = category
end

--- The one way to change a preference from outside the panel. A preference the
--- Settings API drew goes through its setting object, which persists the value,
--- refreshes the control and announces the change; one drawn by hand has no
--- control to refresh and goes straight to the store.
---@param key string
---@param value boolean|number|string
function OptionsPanel:SelectValue(key, value)
	local setting = self.settings[key]

	if setting then
		setting:SetValue(value)
		return
	end

	self.preferences:Set(key, value)
end

function OptionsPanel:Open()
	Settings.OpenToCategory(self.category:GetID())
end

function OptionsPanel:OpenIntegrations()
	local panel = self.panels.integration

	if type(panel) == "table" then
		Settings.OpenToCategory(panel:GetID())
		return
	end

	self:Open()
end

Addon.OptionsPanel = OptionsPanel
