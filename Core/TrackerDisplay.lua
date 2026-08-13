local _, Addon = ...

local Keys = Addon.PreferenceKeys

local PERCENTAGE_MAXIMUM = 100

--- Decides what is on screen: our tracker, how it looks, which of its sections
--- are drawn, and whether Blizzard's stays visible beside it.
---
--- The rules live here so neither the frame nor the event adapter has to know
--- what turns any of it on.
---@class TrackerDisplay
---@field private content TrackerContent
---@field private renderer TrackerRenderer
---@field private blizzardTracker TrackerVisibility
---@field private preferences Preferences
---@field private hiddenSections table<string, boolean>
---@field private lastSections TrackerSection[]
---@field private widgets table<string, TrackerWidget>
local TrackerDisplay = {}
TrackerDisplay.__index = TrackerDisplay

---@param content TrackerContent
---@param renderer TrackerRenderer
---@param blizzardTracker TrackerVisibility
---@param preferences Preferences
---@param hiddenSections table<string, boolean>
---@param sources AppearanceSources What the look is resolved against.
---@param widgets table<string, TrackerWidget> Keyed by the preference that shows it.
---@return TrackerDisplay
function TrackerDisplay.New(
	content,
	renderer,
	blizzardTracker,
	preferences,
	hiddenSections,
	sources,
	widgets
)
	return setmetatable({
		content = content,
		renderer = renderer,
		blizzardTracker = blizzardTracker,
		preferences = preferences,
		hiddenSections = hiddenSections,
		sources = sources,
		widgets = widgets,
		lastSections = {},
	}, TrackerDisplay)
end

--- Every section that has content right now, hidden ones included, so they can
--- still be found and switched back on.
---@return TrackerSection[]
function TrackerDisplay:Sections()
	return self.lastSections
end

---@param sectionID string
---@return boolean
function TrackerDisplay:IsSectionShown(sectionID)
	return not self.hiddenSections[sectionID]
end

---@param sectionID string
function TrackerDisplay:ToggleSection(sectionID)
	Addon.ToggleSet.Toggle(self.hiddenSections, sectionID)
	self:Refresh()
end

---@private
---@param sections TrackerSection[]
---@return TrackerSection[]
function TrackerDisplay:Visible(sections)
	local visible = {}

	for _, section in ipairs(sections) do
		if self:IsSectionShown(section.id) then
			table.insert(visible, section)
		end
	end

	return visible
end

---@private
---@param key string
---@return TrackerColor
function TrackerDisplay:Color(key)
	local red, green, blue = Addon.HexColor.ToRGB(self.preferences:Get(key))

	return { red = red, green = green, blue = blue }
end

---@private
---@return TrackerColor
function TrackerDisplay:BorderColor()
	if self.preferences:Get(Keys.BORDER_CLASS_COLOR) then
		return self.sources.ClassColor()
	end

	return self:Color(Keys.BORDER_COLOR)
end

---@private
function TrackerDisplay:ApplyAppearance()
	-- Font before size: the layout measures text, so it has to be laid out with
	-- the font it will be drawn in.
	self.renderer:SetFont({
		path = self.sources.Font(self.preferences:Get(Keys.FONT_NAME)),
		size = self.preferences:Get(Keys.FONT_SIZE),
		flags = Addon.FontFlags.Resolve(self.preferences:Get(Keys.FONT_FLAG)),
		hasShadow = self.preferences:Get(Keys.FONT_SHADOW),
		wrapsLongText = self.preferences:Get(Keys.WRAP_LONG_TEXT),
	})

	self.renderer:SetItemButtonsShown(self.preferences:Get(Keys.SHOW_ITEM_BUTTONS))
	self.renderer:SetProgressBarTexture(
		self.sources.ProgressBar(self.preferences:Get(Keys.PROGRESS_BAR_TEXTURE))
	)
	self.renderer:SetScale(self.preferences:Get(Keys.TRACKER_SCALE) / PERCENTAGE_MAXIMUM)
	self.renderer:SetEditing(self.preferences:Get(Keys.EDIT_MODE))

	self.renderer:SetAppearance({
		width = self.preferences:Get(Keys.TRACKER_WIDTH),
		height = self.preferences:Get(Keys.TRACKER_HEIGHT),
		opacity = self.preferences:Get(Keys.PANEL_OPACITY) / PERCENTAGE_MAXIMUM,
		backgroundTexture = self.sources.Background(self.preferences:Get(Keys.BACKGROUND_TEXTURE)),
		backgroundColor = self:Color(Keys.BACKGROUND_COLOR),
		backgroundInset = self.preferences:Get(Keys.BACKGROUND_INSET),
		borderTexture = self.sources.Border(self.preferences:Get(Keys.BORDER_TEXTURE)),
		borderColor = self:BorderColor(),
		borderOpacity = self.preferences:Get(Keys.BORDER_OPACITY) / PERCENTAGE_MAXIMUM,
		borderThickness = self.preferences:Get(Keys.BORDER_THICKNESS),
	})
end

---@private
function TrackerDisplay:ApplyWidgets()
	for key, widget in pairs(self.widgets) do
		widget:SetShown(self.preferences:Get(key))
	end
end

function TrackerDisplay:Refresh()
	local isOwnEnabled = self.preferences:Get(Keys.OWN_TRACKER_ENABLED)

	-- Blizzard's tracker steps aside for ours: two trackers on screen is a thing
	-- to opt into, not the default. With ours off it is always visible, since
	-- otherwise nothing would be.
	local keepBlizzard = self.preferences:Get(Keys.KEEP_BLIZZARD_TRACKER)
	self.blizzardTracker:SetHidden(isOwnEnabled and not keepBlizzard)

	-- Ahead of the early return: with the tracker off, the minimap button is how
	-- it gets turned back on.
	self:ApplyWidgets()

	if not isOwnEnabled then
		self.renderer:SetShown(false)
		return
	end

	self.lastSections = self.content:Build()

	self.renderer:SetShown(true)
	self:ApplyAppearance()
	self.renderer:Render(self:Visible(self.lastSections))
end

Addon.TrackerDisplay = TrackerDisplay
