--- Aura Tracker Questor
--- Copyright (c) 2026 Lucascodev. MIT licensed — see LICENSE.

local ADDON_NAME, Addon = ...

local Keys = Addon.PreferenceKeys

local STATUS_ARGUMENT = "status"
local HELP_ARGUMENT = "ajuda"
local RESET_ARGUMENT = "posicao"

local SLASH_COMMANDS = {
	{ command = "/atq", description = "abre as opções" },
	{ command = "/atq ajuda", description = "mostra esta lista" },
	{ command = "/atq status", description = "confirma que o addon está ativo" },
	{ command = "/atq posicao", description = "devolve o rastreador ao lugar padrão" },
}

local NEW_PROFILE_QUESTION = "Nome do novo perfil:"
local COPY_PROFILE_QUESTION = "Copiar as configurações atuais para qual nome?"
local DELETE_PROFILE_QUESTION = "Nome do perfil a apagar:"
local DELETE_ACTIVE_WARNING = "O perfil em uso não pode ser apagado."
local EXPORT_MESSAGE = "Copie o texto abaixo (Ctrl+C):"
local IMPORT_QUESTION = "Cole o texto de um perfil exportado:"

--- Imports land in one known profile rather than in a name the text carries:
--- an import that silently overwrote whatever it was named after would be a
--- trap, and this one is always the same, visible place.
local IMPORTED_PROFILE_NAME = "Importado"

local ADDON_AUTHOR = "Lucascodev"
local ADDON_LICENSE = "MIT"

---@type Startup
local startup
---@type TrackerDisplay
local display
---@type TrackerFilterButton
local filterButton
---@type TrackerAchievementButton
local achievementButton
---@type OwnTrackerFrame
local ownTracker
---@type MinimapButton
local minimapButton

--- Composition root: the only place allowed to know every concrete implementation.
local function Build()
	local logger = Addon.ChatLogger.New()
	local commands = Addon.SlashCommandRegistry.New(ADDON_NAME)
	local addonInfo = Addon.AddonMetadata.Read()

	-- Before anything reads a media list: our own border is one of the choices.
	Addon.MediaLibrary.RegisterOwnMedia()

	AuraTrackerQuestorDB = AuraTrackerQuestorDB or {}

	local profiles = Addon.Profiles.New(
		AuraTrackerQuestorDB,
		("%s - %s"):format(UnitName("player"), GetRealmName())
	)
	local profile = profiles:Current()

	local preferences = Addon.Preferences.New(Addon.PreferenceCatalog, profile.settings)
	local hiddenCategories = profile.hiddenCategories

	local filtering = Addon.QuestFiltering.New(
		Addon.QuestLogSource.New(),
		Addon.QuestFilters,
		logger
	)

	-- A world quest is a real quest and answers to the same actions. A bonus
	-- objective is not: it has no quest log page and was never tracked on
	-- purpose, so it gets its own, shorter set.
	local questActions = Addon.QuestEntryActions.New()
	local collectableActions = Addon.CollectableEntryActions.New()
	local actions = Addon.EntryActionRouter.New({
		quest = questActions,
		worldQuest = questActions,
		bonus = Addon.BonusEntryActions.New(),
		achievement = Addon.AchievementEntryActions.New(),
		event = Addon.EventEntryActions.New(),
		scenario = Addon.ScenarioEntryActions.New(),
		recipe = Addon.ProfessionEntryActions.New(),
		monthlyActivity = Addon.MonthlyActivityEntryActions.New(),
		initiativeTask = Addon.InitiativeTaskEntryActions.New(),
		appearance = collectableActions,
		decor = collectableActions,
	})

	ownTracker = Addon.OwnTrackerFrame.New(
		addonInfo,
		profile.ownTrackerPosition,
		actions,
		profile.collapsedSections
	)

	-- Filled further down rather than here: the buttons are built after the
	-- display because what their menus do is written in terms of it. The display
	-- only reads this table when it refreshes, which is after all of that.
	local widgets = {}

	display = Addon.TrackerDisplay.New(
		Addon.TrackerContent.New({
			Addon.ScenarioSectionProvider.New(),
			Addon.QuestSectionProvider.New(),
			Addon.WorldQuestSectionProvider.New(),
			Addon.EventSectionProvider.New(preferences),
			Addon.BonusObjectiveSectionProvider.New(preferences),
			Addon.AchievementSectionProvider.New(hiddenCategories),
			Addon.ProfessionSectionProvider.New(),
			Addon.MonthlyActivitySectionProvider.New(),
			Addon.CollectableSectionProvider.New(),
			Addon.InitiativeTaskSectionProvider.New(),
		}, Addon.SortModes, preferences),
		ownTracker,
		Addon.BlizzardTracker.New(),
		preferences,
		profile.hiddenSections,
		{
			Font = Addon.MediaLibrary.FontPath,
			Background = Addon.MediaLibrary.BackgroundPath,
			Border = Addon.MediaLibrary.BorderPath,
			ProgressBar = Addon.MediaLibrary.ProgressBarPath,
			ClassColor = Addon.ClassColor.Current,
		},
		widgets
	)

	local sounds = Addon.SoundPlayer.New()

	local function PlayCompletionSound()
		if not preferences:Get(Keys.SOUND_ENABLED) then
			return
		end

		sounds:Play(
			preferences:Get(Keys.SOUND_QUEST_COMPLETE),
			preferences:Get(Keys.SOUND_CHANNEL)
		)
	end

	local completion = Addon.CompletionWatcher.New()

	local function RefreshFromGame()
		display:Refresh()

		if #completion:Detect(display:Sections()) > 0 then
			PlayCompletionSound()
		end
	end

	Addon.TrackerEvents.New(RefreshFromGame):Start()
	Addon.ChallengeTimer.New(RefreshFromGame):Start()

	-- Switching a profile reloads the interface. Re-pointing every table already
	-- handed to the frame and the providers would work until one was forgotten,
	-- and a forgotten one fails silently.
	local profileCommands = {
		profileNames = function()
			return profiles:Names()
		end,
		currentProfile = function()
			return profiles:CurrentName()
		end,
		selectProfile = function(name)
			profiles:Select(name)
			ReloadUI()
		end,
		createProfile = function()
			Addon.NamePrompt.Ask(NEW_PROFILE_QUESTION, function(name)
				profiles:Create(name)
				profiles:Select(name)
				ReloadUI()
			end)
		end,
		copyProfile = function()
			Addon.NamePrompt.Ask(COPY_PROFILE_QUESTION, function(name)
				profiles:CopyCurrentTo(name)
				profiles:Select(name)
				ReloadUI()
			end)
		end,
		exportProfile = function()
			Addon.NamePrompt.Show(EXPORT_MESSAGE, Addon.ProfileTransfer.Export(profiles:Current()))
		end,
		importProfile = function()
			Addon.NamePrompt.Ask(IMPORT_QUESTION, function(text)
				local imported, failure = Addon.ProfileTransfer.Import(text)

				if not imported then
					logger:Warn(failure)
					return
				end

				profiles:Import(IMPORTED_PROFILE_NAME, imported)
				profiles:Select(IMPORTED_PROFILE_NAME)
				ReloadUI()
			end)
		end,
		deleteProfile = function()
			Addon.NamePrompt.Ask(DELETE_PROFILE_QUESTION, function(name)
				if not profiles:Delete(name) then
					logger:Warn(DELETE_ACTIVE_WARNING)
				end
			end)
		end,
	}

	local optionsPanel = Addon.OptionsPanel.New(
		addonInfo,
		Addon.PreferenceCatalog,
		preferences,
		function(changedKey)
			display:Refresh()

			if changedKey == Keys.SOUND_QUEST_COMPLETE then
				PlayCompletionSound()
			end
		end,
		{
			{ label = "Versão", value = addonInfo.version },
			{ label = "Autor", value = ADDON_AUTHOR },
			{ label = "Licença", value = ADDON_LICENSE },
			{ label = "Comandos", value = "/atq  ·  /atq ajuda  ·  /atq status" },
			-- Plain separators: the game font has no arrow glyph, and the one
			-- used before rendered as an empty box.
			{ label = "Atalhos", value = "Opções  >  Atalhos  >  Aura Tracker Questor" },
		},
		{
			fonts = Addon.MediaLibrary.FontChoices,
			sounds = Addon.SoundLibrary.Choices,
		},
		profileCommands
	)
	optionsPanel:Register()

	-- Toggles go through the settings object like every other change, so the
	-- options panel and the menu can never disagree.
	filterButton = Addon.TrackerFilterButton.New(Addon.QuestFilters, {
		filterCounts = function()
			return filtering:Counts()
		end,
		applyFilter = function(filterID)
			filtering:Apply(filterID)
			display:Refresh()
		end,
		groups = function()
			return filtering:Groups()
		end,
		applyGroup = function(groupName)
			filtering:ApplyGroup(groupName)
			display:Refresh()
		end,
		untrackQuests = function()
			filtering:UntrackAll()
			display:Refresh()
		end,
		untrackAchievements = function()
			Addon.AchievementTracking.UntrackAll()
		end,
		sections = function()
			return display:Sections()
		end,
		isSectionShown = function(sectionID)
			return display:IsSectionShown(sectionID)
		end,
		toggleSection = function(sectionID)
			display:ToggleSection(sectionID)
		end,
		sortModes = Addon.SortModes,
		selectedSort = function()
			return preferences:Get(Keys.SORT_MODE)
		end,
		selectSort = function(modeID)
			optionsPanel:SelectValue(Keys.SORT_MODE, modeID)
		end,
		isEventsEnabled = function()
			return preferences:Get(Keys.EVENTS_ENABLED)
		end,
		toggleEvents = function()
			optionsPanel:SelectValue(Keys.EVENTS_ENABLED, not preferences:Get(Keys.EVENTS_ENABLED))
		end,
		categories = function()
			return Addon.AchievementCategoryReader.ListTopLevel()
		end,
		isCategoryShown = function(categoryID)
			return not hiddenCategories[categoryID]
		end,
		toggleCategory = function(categoryID)
			-- Shown categories drop their key instead of storing false, so the
			-- saved table only ever holds what differs from the default.
			if hiddenCategories[categoryID] then
				hiddenCategories[categoryID] = nil
			else
				hiddenCategories[categoryID] = true
			end

			display:Refresh()
		end,
		showAllCategories = function(isShown)
			for categoryID in pairs(hiddenCategories) do
				hiddenCategories[categoryID] = nil
			end

			if not isShown then
				for _, category in ipairs(Addon.AchievementCategoryReader.ListTopLevel()) do
					hiddenCategories[category.id] = true
				end
			end

			display:Refresh()
		end,
	})

	achievementButton = Addon.TrackerAchievementButton.New(Addon.AchievementPanel.Open)

	local function ToggleTracker()
		optionsPanel:SelectValue(
			Keys.OWN_TRACKER_ENABLED,
			not preferences:Get(Keys.OWN_TRACKER_ENABLED)
		)
	end

	minimapButton = Addon.MinimapButton.New(addonInfo, profile.minimapButton, ToggleTracker, function()
		optionsPanel:Open()
	end)

	widgets[Keys.SHOW_FILTER_BUTTON] = filterButton
	widgets[Keys.SHOW_ACHIEVEMENT_BUTTON] = achievementButton
	widgets[Keys.SHOW_MINIMAP_BUTTON] = minimapButton

	local status = Addon.StatusCommand.New(logger, addonInfo)
	local help = Addon.HelpCommand.New(logger, SLASH_COMMANDS)

	commands:Register("atq", function(argument)
		local command = strtrim(argument)

		if command == STATUS_ARGUMENT then
			status:Run()
			return
		end

		-- A frame dragged off screen cannot be reached to be dragged back, and
		-- the options panel has no plain button to put this on.
		if command == RESET_ARGUMENT then
			ownTracker:ResetPosition()
			return
		end

		if command == HELP_ARGUMENT then
			help:Run()
			return
		end

		optionsPanel:Open()
	end)

	Addon.KeyBindings.Install(ToggleTracker, function()
		optionsPanel:Open()
	end)

	startup = Addon.Startup.New(logger, addonInfo, preferences)
end

--- Everything that touches a frame, the quest log or the chat waits for the UI
--- to exist.
local function Start()
	-- Added right to left in this order, which is where they sat when each one
	-- still carried its own offset.
	local headerButtons = Addon.HeaderButtonRow.New(ownTracker:HeaderAnchor())

	filterButton:Attach(headerButtons)
	achievementButton:Attach(headerButtons)
	minimapButton:Attach()
	display:Refresh()
	startup:Run()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
-- Starting on PLAYER_LOGIN, not on ADDON_LOADED: addons load during the loading
-- screen, and the chat frame restores its history afterwards, dropping whatever was
-- written before it. PLAYER_LOGIN is the first moment a message actually survives.
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, loadedAddonName)
	if event ~= "ADDON_LOADED" or loadedAddonName ~= ADDON_NAME then
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent("PLAYER_LOGIN")
			Start()
		end
		return
	end

	-- SavedVariables are only readable from here on.
	self:UnregisterEvent("ADDON_LOADED")
	Build()

	-- Already logged in means PLAYER_LOGIN is long gone (/reload, or a future
	-- load-on-demand). Start now instead of waiting for an event that will
	-- never come.
	if IsLoggedIn() then
		self:UnregisterEvent("PLAYER_LOGIN")
		Start()
	end
end)
