local _, Addon = ...

--- Only until the first refresh applies the saved size; the frame is hidden
--- until then, so these never reach the screen.
local INITIAL_WIDTH = 320
local INITIAL_HEIGHT = 420
local FRAME_PADDING = 10
--- Tall enough for the biggest header button, so nothing has to stick out.
local HEADER_HEIGHT = 24
local WHEEL_STEP = 40

local TITLE_GAP = 7
local COUNTDOWN_TICK_SECONDS = 1
local BLOCK_GAP = 10
local SECTION_GAP = 18

local HEADER_COLOR = { red = 1, green = 0.82, blue = 0 }

local SECTION_COLOR = { red = 0.60, green = 0.56, blue = 0.48 }
local SECTION_LINE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local SECTION_ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }
local EDIT_OUTLINE_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 0.15 }
local SECTION_ACCENT_WIDTH = 22
local SECTION_LINE_THICKNESS = 1
local SECTION_LINE_GAP = 4
local SECTION_HEADER_HEIGHT = 18

local LOGO_TEXTURE = [[Interface\AddOns\AuraQuestor\Media\Logo]]
local LOGO_SIZE = 18
local LOGO_GAP = 6
local TITLE_BUTTONS_GAP = 8

local HEADER_RULE_GAP = 3
local HEADER_ACCENT_WIDTH = 34

local EXPANDED_MARK = "-"
local COLLAPSED_MARK = "+"

--- Collapsed, only the header and the rule under it are left.
local COLLAPSED_HEIGHT = FRAME_PADDING * 2 + HEADER_HEIGHT + HEADER_RULE_GAP + SECTION_LINE_THICKNESS

local TITLE_SIZE_DELTA = 1
local SECTION_SIZE_DELTA = -1

--- TrackerRenderer port: our own tracker frame.
---
--- Owns everything it draws, which is the whole point of the rewrite. Nothing
--- here is protected, so scrolling is a real ScrollFrame, the layout is ours,
--- and none of the taint workarounds the skinning approach needed apply.
---@class OwnTrackerFrame : TrackerRenderer
---@field private position FramePosition
---@field private backdrop TrackerBackdrop
---@field private actions EntryActions
---@field private header table
---@field private headerButtons HeaderButtonRow
---@field private collapsedSections table<string, boolean>
---@field private state table
---@field private expandedHeight number
---@field private hasPendingPin boolean
---@field private lastSections TrackerSection[]
---@field private root table
---@field private scroll table
---@field private content table
---@field private pool EntryBlockPool
---@field private countdownTicker table?
---@field private sectionHeaders table[]
---@field private usedHeaders number
local OwnTrackerFrame = {}
OwnTrackerFrame.__index = OwnTrackerFrame

---@param addonInfo AddonInfo
---@param position table Persisted across sessions; empty on a fresh install.
---@param actions EntryActions
---@param collapsedSections table<string, boolean> Persisted across sessions.
---@param state table Persisted across sessions; whether the panel is collapsed.
---@return OwnTrackerFrame
function OwnTrackerFrame.New(addonInfo, position, actions, collapsedSections, state)
	local view = setmetatable({
		actions = actions,
		collapsedSections = collapsedSections,
		state = state,
		expandedHeight = INITIAL_HEIGHT,
		hasPendingPin = false,
		sectionHeaders = {},
		usedHeaders = 0,
		lastSections = {},
	}, OwnTrackerFrame)

	view:Build(addonInfo, position)

	return view
end

---@private
---@param addonInfo AddonInfo
function OwnTrackerFrame:Build(addonInfo, position)
	local root = CreateFrame("Frame", "AuraQuestorTracker", UIParent, "BackdropTemplate")
	root:SetSize(INITIAL_WIDTH, INITIAL_HEIGHT)
	root:SetClampedToScreen(true)
	root:SetMovable(true)
	root:RegisterForDrag("LeftButton")
	root:SetScript("OnDragStart", root.StartMoving)
	root:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		self.position:Save()
	end)
	root:Hide()

	-- Drawn above everything, so an empty tracker is still findable while being
	-- placed.
	local outline = root:CreateTexture(nil, "OVERLAY")
	outline:SetColorTexture(
		EDIT_OUTLINE_COLOR.red,
		EDIT_OUTLINE_COLOR.green,
		EDIT_OUTLINE_COLOR.blue,
		EDIT_OUTLINE_COLOR.alpha
	)
	outline:SetAllPoints()
	outline:Hide()
	self.editOutline = outline

	self.root = root
	self.backdrop = Addon.TrackerBackdrop.New(root)
	self.position = Addon.FramePosition.New(root, position)
	self.position:Restore()

	local header = CreateFrame("Frame", nil, root)
	header:SetPoint("TOPLEFT", root, "TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
	header:SetPoint("TOPRIGHT", root, "TOPRIGHT", -FRAME_PADDING, -FRAME_PADDING)
	header:SetHeight(HEADER_HEIGHT)
	self.header = header

	local logo = header:CreateTexture(nil, "ARTWORK")
	logo:SetSize(LOGO_SIZE, LOGO_SIZE)
	logo:SetPoint("LEFT")
	logo:SetTexture(LOGO_TEXTURE)

	self.headerButtons = Addon.HeaderButtonRow.New(header)

	-- Held between the logo and the button row so a narrow panel cuts the name
	-- with an ellipsis instead of running it under the buttons.
	local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("LEFT", logo, "RIGHT", LOGO_GAP, 0)
	title:SetPoint("RIGHT", self.headerButtons:Frame(), "LEFT", -TITLE_BUTTONS_GAP, 0)
	title:SetJustifyH("LEFT")
	title:SetWordWrap(false)
	title:SetText(addonInfo.brand)
	self.titleText = title
	title:SetTextColor(HEADER_COLOR.red, HEADER_COLOR.green, HEADER_COLOR.blue)

	local rule = root:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(
		SECTION_LINE_COLOR.red,
		SECTION_LINE_COLOR.green,
		SECTION_LINE_COLOR.blue,
		SECTION_LINE_COLOR.alpha
	)
	rule:SetHeight(SECTION_LINE_THICKNESS)
	rule:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -HEADER_RULE_GAP)
	rule:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -HEADER_RULE_GAP)

	local accent = root:CreateTexture(nil, "OVERLAY")
	accent:SetColorTexture(
		SECTION_ACCENT_COLOR.red,
		SECTION_ACCENT_COLOR.green,
		SECTION_ACCENT_COLOR.blue,
		SECTION_ACCENT_COLOR.alpha
	)
	accent:SetSize(HEADER_ACCENT_WIDTH, SECTION_LINE_THICKNESS)
	accent:SetPoint("TOPLEFT", rule, "TOPLEFT")

	-- Anchored to the header, not to the rule: the quest item button is
	-- protected, and the game refuses to anchor a protected frame to a chain
	-- that passes through a texture.
	local scrollTop = HEADER_RULE_GAP + SECTION_LINE_THICKNESS + FRAME_PADDING

	local scroll = CreateFrame("ScrollFrame", nil, root)
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -scrollTop)
	scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -FRAME_PADDING, FRAME_PADDING)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(INITIAL_WIDTH - FRAME_PADDING * 2, 1)
	scroll:SetScrollChild(content)

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(frame, delta)
		if self:IsLockedByCombat() then
			return
		end

		local hidden = math.max(0, content:GetHeight() - frame:GetHeight())
		local wanted = frame:GetVerticalScroll() - delta * WHEEL_STEP

		frame:SetVerticalScroll(math.min(math.max(wanted, 0), hidden))
	end)

	self.scroll = scroll
	self.content = content
	self.pool = Addon.EntryBlockPool.New(content, self.actions)
end

---@private
---@return table
function OwnTrackerFrame:AcquireSectionHeader()
	self.usedHeaders = self.usedHeaders + 1

	local header = self.sectionHeaders[self.usedHeaders]
	if not header then
		local button = CreateFrame("Button", nil, self.content)
		button:SetHeight(SECTION_HEADER_HEIGHT)

		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT")
		text:SetJustifyH("LEFT")
		text:SetTextColor(SECTION_COLOR.red, SECTION_COLOR.green, SECTION_COLOR.blue)

		local line = self.content:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(
			SECTION_LINE_COLOR.red,
			SECTION_LINE_COLOR.green,
			SECTION_LINE_COLOR.blue,
			SECTION_LINE_COLOR.alpha
		)
		line:SetHeight(SECTION_LINE_THICKNESS)

		local accent = self.content:CreateTexture(nil, "OVERLAY")
		accent:SetColorTexture(
			SECTION_ACCENT_COLOR.red,
			SECTION_ACCENT_COLOR.green,
			SECTION_ACCENT_COLOR.blue,
			SECTION_ACCENT_COLOR.alpha
		)
		accent:SetSize(SECTION_ACCENT_WIDTH, SECTION_LINE_THICKNESS)

		header = { button = button, text = text, line = line, accent = accent }
		self.sectionHeaders[self.usedHeaders] = header

		-- Built after the font was chosen, so it catches up on its own.
		if self.fontStyle then
			Addon.FontStyler.Apply(text, self.fontStyle, SECTION_SIZE_DELTA)
		end

		button:SetScript("OnClick", function()
			if not header.sectionID then
				return
			end

			self:ToggleSection(header.sectionID)
		end)
	end

	header.button:Show()
	header.line:Show()
	header.accent:Show()

	return header
end

---@param sectionID string
function OwnTrackerFrame:ToggleSection(sectionID)
	Addon.ToggleSet.Toggle(self.collapsedSections, sectionID)
	self:Render(self.lastSections)
end

--- Once a quest item button exists, the blocks around it are protected frames,
--- and combat forbids moving, resizing or hiding those. Waiting is the only
--- legal answer, PLAYER_REGEN_ENABLED brings the refresh straight back.
---
--- Nothing is locked until an item button actually exists, so the usual case is
--- a tracker that keeps updating right through the fight.
---@private
---@return boolean
function OwnTrackerFrame:IsLockedByCombat()
	return self.pool:IsProtected() and InCombatLockdown()
end

---@param sections TrackerSection[]
function OwnTrackerFrame:Render(sections)
	if self:IsLockedByCombat() then
		self.pool:RewriteInPlace(sections)
		return
	end

	self.lastSections = sections

	-- Collapsed, the list is off screen, so no blocks are built for it.
	if self:IsCollapsed() then
		self:SyncCountdownTicker()
		return
	end

	self.pool:ReleaseAll()
	self.usedHeaders = 0

	local width = self.content:GetWidth()
	local offset = 0

	-- Numbered in reading order, not by the game's internal watch index.
	local entryNumber = 0

	for _, section in ipairs(sections) do
		local isCollapsed = self.collapsedSections[section.id] == true
		local header = self:AcquireSectionHeader()
		header.sectionID = section.id
		header.text:SetText(("%s %s (%d)"):format(
			isCollapsed and COLLAPSED_MARK or EXPANDED_MARK,
			section.title,
			#section.entries
		))
		header.button:ClearAllPoints()
		header.button:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)
		header.button:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -offset)
		offset = offset + SECTION_HEADER_HEIGHT + SECTION_LINE_GAP

		header.line:ClearAllPoints()
		header.line:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)
		header.line:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -offset)

		header.accent:ClearAllPoints()
		header.accent:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)

		offset = offset + SECTION_LINE_THICKNESS + TITLE_GAP

		if not isCollapsed then
			for _, entry in ipairs(section.entries) do
				entryNumber = entryNumber + 1

				local block, height = self.pool:Build(entry, width, entryNumber)
				block.frame:ClearAllPoints()
				block.frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)
				offset = offset + height + BLOCK_GAP
			end
		end

		offset = offset + SECTION_GAP
	end

	for index = self.usedHeaders + 1, #self.sectionHeaders do
		self.sectionHeaders[index].button:Hide()
		self.sectionHeaders[index].line:Hide()
		self.sectionHeaders[index].accent:Hide()
	end

	self.pool:HideUnused()
	self.content:SetHeight(math.max(offset, 1))
	self:SyncCountdownTicker()
end

--- The ticker only exists while something on screen is counting down, and it
--- rewrites those lines from the deadline each block kept: no game call, no
--- layout, no rebuild. A permanent one would cost the frame budget all day.
---@private
function OwnTrackerFrame:SyncCountdownTicker()
	local wantsTicker = self.pool:RefreshCountdowns() and not self:IsCollapsed()

	if wantsTicker == (self.countdownTicker ~= nil) then
		return
	end

	if not wantsTicker then
		self.countdownTicker:Cancel()
		self.countdownTicker = nil

		return
	end

	self.countdownTicker = C_Timer.NewTicker(COUNTDOWN_TICK_SECONDS, function()
		if not self.pool:RefreshCountdowns() then
			self:SyncCountdownTicker()
		end
	end)
end

--- Exposed so buttons can be hung on it without this frame knowing what they do.
---@return HeaderButtonRow
function OwnTrackerFrame:HeaderButtons()
	return self.headerButtons
end

--- The panel itself, kept apart from Render because it changes on a preference
--- and not on every quest update.
---@param appearance TrackerAppearance
function OwnTrackerFrame:SetAppearance(appearance)
	if self:IsLockedByCombat() then
		return
	end

	self.expandedHeight = appearance.height
	self.root:SetWidth(appearance.width)
	self.content:SetWidth(appearance.width - FRAME_PADDING * 2)

	if self.hasPendingPin then
		self.hasPendingPin = false
		self:PinTop()
	end

	self:ApplyHeight()

	self.backdrop:Apply(appearance)
end

---@return boolean
function OwnTrackerFrame:IsCollapsed()
	return self.state.isCollapsed == true
end

---@private
function OwnTrackerFrame:ApplyHeight()
	local isCollapsed = self:IsCollapsed()

	self.root:SetHeight(isCollapsed and COLLAPSED_HEIGHT or self.expandedHeight)
	self.scroll:SetShown(not isCollapsed)
end

--- Anchored by the top corner: around a centre or bottom anchor the header
--- would jump every time the height changed.
---@private
function OwnTrackerFrame:PinTop()
	local left, top = self.root:GetLeft(), self.root:GetTop()

	self.root:ClearAllPoints()
	self.root:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
	self.position:Save()
end

--- With an item button on the list the frame is protected in combat and cannot
--- be resized, so the state is saved and applied by the refresh that follows.
---@return boolean isCollapsed
function OwnTrackerFrame:ToggleCollapsed()
	self.state.isCollapsed = not self:IsCollapsed() or nil

	if self:IsLockedByCombat() then
		self.hasPendingPin = true
		return self:IsCollapsed()
	end

	self:PinTop()
	self:ApplyHeight()

	if not self:IsCollapsed() then
		self:Render(self.lastSections)
	end

	return self:IsCollapsed()
end

---@param style TrackerFontStyle
function OwnTrackerFrame:SetFont(style)
	self.fontStyle = style

	Addon.FontStyler.Apply(self.titleText, style, TITLE_SIZE_DELTA)
	self.titleText:SetWordWrap(false)

	for _, header in ipairs(self.sectionHeaders) do
		Addon.FontStyler.Apply(header.text, style, SECTION_SIZE_DELTA)
	end

	self.pool:SetFont(style)
end

---@param isShown boolean
function OwnTrackerFrame:SetItemButtonsShown(isShown)
	self.pool:SetItemButtonsShown(isShown)
end

---@param path string
function OwnTrackerFrame:SetProgressBarTexture(path)
	self.pool:SetProgressBarTexture(path)
end

---@param height number
function OwnTrackerFrame:SetProgressBarHeight(height)
	self.pool:SetProgressBarHeight(height)
end

---@param style string
function OwnTrackerFrame:SetProgressBarStyle(style)
	self.pool:SetProgressBarStyle(style)
end

--- Dragging is off until the player asks for it.
---
--- A tracker that moves whenever a click lands on it gets nudged out of place
--- by accident, and the frame covers a good part of the screen. Edit mode makes
--- moving deliberate, and the outline says the frame is listening.
---@param isEditing boolean
function OwnTrackerFrame:SetEditing(isEditing)
	if self:IsLockedByCombat() then
		return
	end

	self.root:EnableMouse(isEditing)
	self.editOutline:SetShown(isEditing)
end

--- Scale is separate from size: it multiplies everything, text included, while
--- width and height only change how much room the list has.
---@param scale number
function OwnTrackerFrame:SetScale(scale)
	if self:IsLockedByCombat() then
		return
	end

	self.root:SetScale(scale)
end

function OwnTrackerFrame:ResetPosition()
	self.position:Reset()
end

---@param isShown boolean
function OwnTrackerFrame:SetShown(isShown)
	if self:IsLockedByCombat() then
		return
	end

	self.root:SetShown(isShown)

	if not isShown and self.countdownTicker then
		self.countdownTicker:Cancel()
		self.countdownTicker = nil
	end
end

Addon.OwnTrackerFrame = OwnTrackerFrame
