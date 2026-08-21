--- Aura Questor: Objective Tracker
--- Copyright (c) 2026 Lucascodev. MIT licensed. See LICENSE.

local ADDON_NAME, Addon = ...

local Keys = Addon.PreferenceKeys
local L = Addon.L

--- Cada acao aceita o termo em ingles e o em portugues: quem le a interface
--- traduzida digita o que esta escrito nela, e quem le em ingles digita o que
--- esta escrito na dele.
local STATUS_ARGUMENTS = { status = true }
local HELP_ARGUMENTS = { help = true, ajuda = true }
local RESET_ARGUMENTS = { reset = true, posicao = true }

local SLASH_COMMANDS = {
	{ command = "/atq", description = L.COMMAND_OPTIONS },
	{ command = "/atq " .. L.COMMAND_HELP_ARGUMENT, description = L.COMMAND_HELP },
	{ command = "/atq status", description = L.COMMAND_STATUS },
	{ command = "/atq " .. L.COMMAND_RESET_ARGUMENT, description = L.COMMAND_RESET },
}

local NEW_PROFILE_QUESTION = L.PROFILE_NEW_QUESTION
local COPY_PROFILE_QUESTION = L.PROFILE_COPY_QUESTION
local DELETE_PROFILE_QUESTION = L.PROFILE_DELETE_QUESTION
local DELETE_ACTIVE_WARNING = L.PROFILE_DELETE_ACTIVE
local EXPORT_MESSAGE = L.PROFILE_EXPORT_MESSAGE
local IMPORT_QUESTION = L.PROFILE_IMPORT_QUESTION

--- Imports land in one known profile rather than in a name the text carries:
--- an import that silently overwrote whatever it was named after would be a
--- trap, and this one is always the same, visible place.
local IMPORTED_PROFILE_NAME = L.PROFILE_IMPORTED_NAME

local ADDON_AUTHOR = "Lucascodev"
local ADDON_LICENSE = "MIT"

---@type TrackedListSource
local MONTHLY_ACTIVITIES = {
	kind = "monthlyActivity",
	sectionID = "monthlyActivities",
	title = TRACKER_HEADER_MONTHLY_ACTIVITIES,
	titleField = "activityName",
	readTracked = function()
		return C_PerksActivities.GetTrackedPerksActivities()
	end,
	readInfo = function(id)
		return C_PerksActivities.GetPerksActivityInfo(id)
	end,
}

---@type TrackedListSource
local INITIATIVE_TASKS = {
	kind = "initiativeTask",
	sectionID = "initiativeTasks",
	title = TRACKER_HEADER_INITIATIVE_TASKS,
	titleField = "taskName",
	readTracked = function()
		return C_NeighborhoodInitiative.GetTrackedInitiativeTasks()
	end,
	readInfo = function(id)
		return C_NeighborhoodInitiative.GetInitiativeTaskInfo(id)
	end,
}

---@type Startup
local startup
---@type TrackerDisplay
local display
---@type TrackerFilterButton
local filterButton
---@type TrackerAchievementButton
local achievementButton
---@type TrackerIntegrationButton
local integrationButton
---@type OwnTrackerFrame
local ownTracker
---@type MinimapButton
local minimapButton
---@type TrackerCollapseButton
local collapseButton
---@type WaypointSync
local waypointSync

--- Composition root: the only place allowed to know every concrete implementation.
local function Build()
	local logger = Addon.ChatLogger.New()
	local commands = Addon.SlashCommandRegistry.New(ADDON_NAME)
	local addonInfo = Addon.AddonMetadata.Read()

	-- Before anything reads a media list: our own border is one of the choices.
	Addon.MediaLibrary.RegisterOwnMedia()

	local hasAdoptedLegacy
	AuraQuestorDB, hasAdoptedLegacy = Addon.LegacyDatabase.Resolve(AuraQuestorDB, AuraTrackerQuestorDB)

	local profiles = Addon.Profiles.New(
		AuraQuestorDB,
		("%s - %s"):format(UnitName("player"), GetRealmName())
	)
	local profile = profiles:Current()

	-- As fontes empacotadas não têm glifo CJK. Nesses clientes o padrão de
	-- fábrica vira a fonte do jogo, e uma escolha delas já gravada é migrada:
	-- gravada, era ilegível de qualquer forma.
	if Addon.ClientFont.PrefersGameFont() then
		local gameFont = Addon.MediaLibrary.GAME_FONT_NAME

		Addon.PreferenceLookup.Find(Addon.PreferenceCatalog, Keys.FONT_NAME).default = gameFont

		if Addon.MediaLibrary.IsBundledLatinFont(profile.settings[Keys.FONT_NAME]) then
			profile.settings[Keys.FONT_NAME] = gameFont
		end
	end

	local sounds = Addon.SoundPlayer.New()

	---@type Preferences
	local preferences

	local function PlayCompletionSound()
		if not preferences:Get(Keys.SOUND_ENABLED) then
			return
		end

		sounds:Play(
			preferences:Get(Keys.SOUND_QUEST_COMPLETE),
			preferences:Get(Keys.SOUND_CHANNEL)
		)
	end

	preferences = Addon.Preferences.New(
		Addon.PreferenceCatalog,
		profile.settings,
		function(changedKey)
			display:Refresh()

			if changedKey == Keys.SOUND_QUEST_COMPLETE then
				PlayCompletionSound()
			end

			-- Desligar a integração recolhe a seta na hora, sem esperar evento.
			if changedKey == Keys.TOMTOM_ENABLED and waypointSync then
				waypointSync:Sync()
			end
		end
	)

	local waypointArrow = Addon.TomTomArrow.New(addonInfo.brand)
	waypointSync = Addon.WaypointSync.New(Addon.WaypointReader.Current, waypointArrow, function()
		return preferences:Get(Keys.TOMTOM_ENABLED) == true
	end)

	---@type EntryWaypoints
	local waypoints = {
		isAvailable = function()
			return Addon.TomTomArrow.IsAvailable() and preferences:Get(Keys.TOMTOM_ENABLED) == true
		end,
		send = function(entry)
			local target = Addon.WaypointReader.ForQuest(entry.id, entry.kind)

			if target and target.x then
				waypointArrow:SetWaypoint(target)
			end
		end,
	}

	local hiddenCategories = profile.hiddenCategories
	local categories = Addon.AchievementCategories.New(
		hiddenCategories,
		Addon.AchievementCategoryReader.ListTopLevel,
		function()
			display:Refresh()
		end
	)

	local filtering = Addon.QuestFiltering.New(
		Addon.QuestLogSource.New(),
		Addon.QuestFilters,
		logger
	)

	-- A world quest is a real quest and answers to the same actions. A bonus
	-- objective is not: it has no quest log page and was never tracked on
	-- purpose, so it gets its own, shorter set.
	local questActions = Addon.QuestEntryActions.New(waypoints)
	local collectableActions = Addon.CollectableEntryActions.New()
	local actions = Addon.EntryActionRouter.New({
		quest = questActions,
		worldQuest = questActions,
		bonus = Addon.BonusEntryActions.New(waypoints),
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
		profile.collapsedSections,
		profile.ownTrackerState
	)

	-- Filled further down rather than here: the buttons are built after the
	-- display because what their menus do is written in terms of it. The display
	-- only reads this table when it refreshes, which is after all of that.
	local widgets = {}

	display = Addon.TrackerDisplay.New(
		Addon.TrackerContent.New({
			Addon.ScenarioSectionProvider.New(),
			Addon.QuestSectionProvider.New(),
			Addon.WorldQuestSectionProvider.New(preferences),
			Addon.EventSectionProvider.New(preferences),
			Addon.BonusObjectiveSectionProvider.New(preferences),
			Addon.AchievementSectionProvider.New(hiddenCategories),
			Addon.ProfessionSectionProvider.New(),
			Addon.TrackedListSectionProvider.New(MONTHLY_ACTIVITIES),
			Addon.CollectableSectionProvider.New(),
			Addon.TrackedListSectionProvider.New(INITIATIVE_TASKS),
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
		widgets,
		{
			IsChallengeActive = function()
				return C_ChallengeMode.IsChallengeModeActive()
			end,
		}
	)

	local completion = Addon.CompletionWatcher.New()

	local function RefreshFromGame()
		display:Refresh()
		waypointSync:Sync()

		if #completion:Detect(display:Sections()) > 0 then
			PlayCompletionSound()
		end
	end

	Addon.TrackerEvents.New(RefreshFromGame):Start()
	Addon.ChallengeTimer.New(RefreshFromGame):Start()
	Addon.QuestPopupSource.Start()

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
		{
			{ label = L.INFO_VERSION, value = addonInfo.version },
			{ label = L.INFO_AUTHOR, value = ADDON_AUTHOR },
			{ label = L.INFO_LICENSE, value = ADDON_LICENSE },
			{ label = L.INFO_COMMANDS, value = ("/atq  ·  /atq %s  ·  /atq status"):format(L.COMMAND_HELP_ARGUMENT) },
			-- Plain separators: the game font has no arrow glyph, and the one
			-- used before rendered as an empty box.
			{ label = L.INFO_BINDINGS, value = L.INFO_BINDINGS_PATH },
		},
		{
			fonts = Addon.MediaLibrary.FontChoices,
			sounds = Addon.SoundLibrary.Choices,
		},
		profileCommands,
		logger
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
		isCompletedAtTop = function()
			return preferences:Get(Keys.COMPLETED_AT_TOP)
		end,
		toggleCompletedAtTop = function()
			optionsPanel:SelectValue(Keys.COMPLETED_AT_TOP, not preferences:Get(Keys.COMPLETED_AT_TOP))
		end,
		isEventsEnabled = function()
			return preferences:Get(Keys.EVENTS_ENABLED)
		end,
		toggleEvents = function()
			optionsPanel:SelectValue(Keys.EVENTS_ENABLED, not preferences:Get(Keys.EVENTS_ENABLED))
		end,
		worldQuestScopes = Addon.WorldQuestScopes.Choices,
		selectedWorldQuestScope = function()
			return preferences:Get(Keys.WORLD_QUEST_SCOPE)
		end,
		selectWorldQuestScope = function(scopeID)
			optionsPanel:SelectValue(Keys.WORLD_QUEST_SCOPE, scopeID)
		end,
		isWorldQuestsEnabled = function()
			return preferences:Get(Keys.WORLD_QUESTS_ENABLED)
		end,
		toggleWorldQuests = function()
			optionsPanel:SelectValue(Keys.WORLD_QUESTS_ENABLED, not preferences:Get(Keys.WORLD_QUESTS_ENABLED))
		end,
		isEditing = function()
			return preferences:Get(Keys.EDIT_MODE)
		end,
		toggleEditing = function()
			optionsPanel:SelectValue(Keys.EDIT_MODE, not preferences:Get(Keys.EDIT_MODE))
		end,
		categories = function()
			return categories:List()
		end,
		isCategoryShown = function(categoryID)
			return categories:IsShown(categoryID)
		end,
		toggleCategory = function(categoryID)
			categories:Toggle(categoryID)
		end,
		showAllCategories = function(isShown)
			categories:ShowAll(isShown)
		end,
	})

	achievementButton = Addon.TrackerAchievementButton.New(Addon.AchievementPanel.Open)

	collapseButton = Addon.TrackerCollapseButton.New(function()
		return ownTracker:ToggleCollapsed()
	end)

	integrationButton = Addon.TrackerIntegrationButton.New(function()
		optionsPanel:OpenIntegrations()
	end)

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
	widgets[Keys.SHOW_INTEGRATION_BUTTON] = integrationButton
	widgets[Keys.SHOW_MINIMAP_BUTTON] = minimapButton

	local status = Addon.StatusCommand.New(logger, addonInfo)
	local help = Addon.HelpCommand.New(logger, SLASH_COMMANDS)

	commands:Register("atq", function(argument)
		local command = strtrim(argument):lower()

		if STATUS_ARGUMENTS[command] then
			status:Run()
			return
		end

		-- A frame dragged off screen cannot be reached to be dragged back, and
		-- the options panel has no plain button to put this on.
		if RESET_ARGUMENTS[command] then
			ownTracker:ResetPosition()
			return
		end

		if HELP_ARGUMENTS[command] then
			help:Run()
			return
		end

		optionsPanel:Open()
	end)

	Addon.KeyBindings.Install(ToggleTracker, function()
		optionsPanel:Open()
	end)

	startup = Addon.Startup.New(logger, addonInfo, preferences, hasAdoptedLegacy)
end

--- Everything that touches a frame, the quest log or the chat waits for the UI
--- to exist.
local function Start()
	-- Added right to left in this order, which is where they sat when each one
	-- still carried its own offset.
	local headerButtons = ownTracker:HeaderButtons()

	collapseButton:Attach(headerButtons, ownTracker:IsCollapsed())
	filterButton:Attach(headerButtons)
	achievementButton:Attach(headerButtons)
	integrationButton:Attach(headerButtons)
	minimapButton:Attach()
	display:Refresh()
	-- Entrar no jogo já supervisionando uma missão também merece a seta.
	waypointSync:Sync()
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
