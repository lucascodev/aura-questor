local _, Addon = ...

local BUTTON_WIDTH = 18
local BUTTON_HEIGHT = 19

local GROUPS_LABEL = Addon.L.MENU_GROUPS
local SORTING_LABEL = Addon.L.MENU_SORTING
local CATEGORIES_LABEL = Addon.L.MENU_CATEGORIES
local SECTIONS_LABEL = Addon.L.MENU_SECTIONS
local UNTRACK_ALL_LABEL = Addon.L.MENU_UNTRACK_ALL
local TRACK_EVENTS_LABEL = Addon.L.MENU_TRACK_EVENTS
local COMPLETED_AT_TOP_LABEL = Addon.L.PREF_COMPLETED_AT_TOP
local SHOW_ALL_LABEL = Addon.L.MENU_CHECK_ALL
local HIDE_ALL_LABEL = Addon.L.MENU_UNCHECK_ALL

--- The filter menu on the tracker header.
---
--- Filters are buttons, not a selected mode: clicking one rewrites the watch
--- list once. Modelling them as a persistent state is what forced an entry that
--- did nothing, since going back to "no filter" cannot undo what was applied.
---@class TrackerFilterButton
---@field private filters QuestFilter[]
---@field private commands table Everything the menu can do beyond filtering.
local TrackerFilterButton = {}
TrackerFilterButton.__index = TrackerFilterButton

---@param filters QuestFilter[]
---@param commands table
---@return TrackerFilterButton
function TrackerFilterButton.New(filters, commands)
	return setmetatable({ filters = filters, commands = commands }, TrackerFilterButton)
end

---@private
---@param rootDescription table
function TrackerFilterButton:AddQuests(rootDescription)
	local counts = self.commands.filterCounts()

	rootDescription:CreateTitle(TRACKER_HEADER_QUESTS)

	for _, filter in ipairs(self.filters) do
		rootDescription:CreateButton(("%s (%d)"):format(filter.label, counts[filter.id]), function()
			self.commands.applyFilter(filter.id)
		end)
	end

	local groups = rootDescription:CreateButton(GROUPS_LABEL)

	for _, group in ipairs(self.commands.groups()) do
		groups:CreateButton(("%s (%d)"):format(group.name, group.count), function()
			self.commands.applyGroup(group.name)
		end)
	end

	rootDescription:CreateButton(UNTRACK_ALL_LABEL, self.commands.untrackQuests)
end

---@private
---@param rootDescription table
function TrackerFilterButton:AddSorting(rootDescription)
	rootDescription:CreateTitle(SORTING_LABEL)

	for _, mode in ipairs(self.commands.sortModes) do
		rootDescription:CreateRadio(mode.label, function(modeID)
			return modeID == self.commands.selectedSort()
		end, function(modeID)
			self.commands.selectSort(modeID)
		end, mode.id)
	end

	rootDescription:CreateCheckbox(
		COMPLETED_AT_TOP_LABEL,
		self.commands.isCompletedAtTop,
		self.commands.toggleCompletedAtTop
	)
end

---@private
---@param rootDescription table
function TrackerFilterButton:AddAchievements(rootDescription)
	rootDescription:CreateTitle(TRACKER_HEADER_ACHIEVEMENTS)

	local categories = rootDescription:CreateButton(CATEGORIES_LABEL)
	local all = self.commands.categories()

	categories:CreateButton(SHOW_ALL_LABEL, function()
		self.commands.showAllCategories(true)
	end)
	categories:CreateButton(HIDE_ALL_LABEL, function()
		self.commands.showAllCategories(false)
	end)
	categories:CreateDivider()

	for _, category in ipairs(all) do
		categories:CreateCheckbox(category.name, function(categoryID)
			return self.commands.isCategoryShown(categoryID)
		end, function(categoryID)
			self.commands.toggleCategory(categoryID)
		end, category.id)
	end

	rootDescription:CreateButton(UNTRACK_ALL_LABEL, self.commands.untrackAchievements)
end

--- Built from the sections that actually have content right now, so the list
--- never offers something that would not appear either way.
---@private
---@param rootDescription table
function TrackerFilterButton:AddSections(rootDescription)
	local sections = self.commands.sections()
	if #sections == 0 then
		return
	end

	local menu = rootDescription:CreateButton(SECTIONS_LABEL)

	for _, section in ipairs(sections) do
		menu:CreateCheckbox(section.title, function(sectionID)
			return self.commands.isSectionShown(sectionID)
		end, function(sectionID)
			self.commands.toggleSection(sectionID)
		end, section.id)
	end
end

---@private
---@param rootDescription table
function TrackerFilterButton:BuildMenu(rootDescription)
	self:AddQuests(rootDescription)

	rootDescription:CreateDivider()
	self:AddSections(rootDescription)

	rootDescription:CreateDivider()
	self:AddSorting(rootDescription)

	rootDescription:CreateDivider()
	rootDescription:CreateTitle(EVENTS_LABEL)
	rootDescription:CreateCheckbox(
		TRACK_EVENTS_LABEL,
		self.commands.isEventsEnabled,
		self.commands.toggleEvents
	)

	rootDescription:CreateDivider()
	self:AddAchievements(rootDescription)
end

--- Handed to the header row, which decides where it sits.
---@param row HeaderButtonRow
function TrackerFilterButton:Attach(row)
	local button = CreateFrame("Button", nil, row:Frame())
	button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	button:SetNormalAtlas("ui-questtrackerbutton-filter")
	button:SetPushedAtlas("ui-questtrackerbutton-filter-pressed")
	button:SetHighlightAtlas("ui-questtrackerbutton-red-highlight")

	button:SetScript("OnEnter", function(owner)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(FILTER)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(owner)
		MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
			self:BuildMenu(rootDescription)
		end)
	end)

	self.button = button
	self.row = row
	row:Add(button)
end

--- TrackerWidget port.
---@param isShown boolean
function TrackerFilterButton:SetShown(isShown)
	if not self.button then
		return
	end

	self.button:SetShown(isShown)
	self.row:Layout()
end

Addon.TrackerFilterButton = TrackerFilterButton
