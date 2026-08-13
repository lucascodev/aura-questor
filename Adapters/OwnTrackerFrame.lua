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
local BLOCK_GAP = 10
local SECTION_GAP = 18

local HEADER_COLOR = { red = 1, green = 0.82, blue = 0 }

--- Sections read as quiet labels rather than gold banners: the rule under them
--- carries the structure, and a short bright segment at its head marks where a
--- section starts. Weight and spacing do the work that ornament does elsewhere.
local SECTION_COLOR = { red = 0.60, green = 0.56, blue = 0.48 }
local SECTION_LINE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local SECTION_ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }
local EDIT_OUTLINE_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 0.15 }
local SECTION_ACCENT_WIDTH = 22
local SECTION_LINE_THICKNESS = 1
local SECTION_LINE_GAP = 4
local SECTION_HEADER_HEIGHT = 18

local EXPANDED_MARK = "-"
local COLLAPSED_MARK = "+"

local TITLE_SIZE_DELTA = 1
local SECTION_SIZE_DELTA = -1

--- TrackerRenderer port: our own tracker frame.
---
--- Owns everything it draws, which is the whole point of the rewrite. Nothing
--- here is protected, so scrolling is a real ScrollFrame, the layout is ours,
--- and none of the taint workarounds the skinning approach needed apply.
---@class OwnTrackerFrame : TrackerRenderer
---@field private position table
---@field private actions EntryActions
---@field private header table
---@field private collapsedSections table<string, boolean>
---@field private lastSections TrackerSection[]
---@field private root table
---@field private content table
---@field private pool EntryBlockPool
---@field private sectionHeaders table[]
---@field private usedHeaders number
local OwnTrackerFrame = {}
OwnTrackerFrame.__index = OwnTrackerFrame

--- Rebuilding a backdrop recreates nine textures, and appearance is applied on
--- every quest update, so two runs that read the same have nothing to redo.
---@param appearance TrackerAppearance
---@return string
local function BackdropSignature(appearance)
	return ("%s|%s|%d|%d"):format(
		appearance.backgroundTexture or "",
		appearance.borderTexture or "",
		appearance.borderThickness,
		appearance.backgroundInset
	)
end

---@param appearance TrackerAppearance
---@return table
local function BackdropFrom(appearance)
	local inset = appearance.backgroundInset

	return {
		bgFile = appearance.backgroundTexture,
		edgeFile = appearance.borderTexture,
		edgeSize = appearance.borderThickness,
		insets = { left = inset, right = inset, top = inset, bottom = inset },
	}
end

---@param addonInfo AddonInfo
---@param position table Persisted across sessions; empty on a fresh install.
---@param actions EntryActions
---@param collapsedSections table<string, boolean> Persisted across sessions.
---@return OwnTrackerFrame
function OwnTrackerFrame.New(addonInfo, position, actions, collapsedSections)
	local view = setmetatable({
		position = position,
		actions = actions,
		collapsedSections = collapsedSections,
		sectionHeaders = {},
		usedHeaders = 0,
		lastSections = {},
	}, OwnTrackerFrame)

	view:Build(addonInfo)

	return view
end

---@private
function OwnTrackerFrame:SavePosition()
	local point, _, relativePoint, x, y = self.root:GetPoint()

	self.position.point = point
	self.position.relativePoint = relativePoint
	self.position.x = x
	self.position.y = y
end

---@private
function OwnTrackerFrame:RestorePosition()
	local saved = self.position

	if not saved.point then
		self.root:SetPoint("RIGHT", UIParent, "RIGHT", -120, 0)
		return
	end

	self.root:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
end

---@private
---@param addonInfo AddonInfo
function OwnTrackerFrame:Build(addonInfo)
	-- BackdropTemplate is what puts SetBackdrop on a frame.
	local root = CreateFrame("Frame", "AuraTrackerQuestorTracker", UIParent, "BackdropTemplate")
	root:SetSize(INITIAL_WIDTH, INITIAL_HEIGHT)
	root:SetClampedToScreen(true)
	root:SetMovable(true)
	root:RegisterForDrag("LeftButton")
	root:SetScript("OnDragStart", root.StartMoving)
	root:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		self:SavePosition()
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
	self:RestorePosition()

	-- A real header strip rather than a loose title: everything that belongs to
	-- the header centres inside it, so buttons of different heights still share
	-- one middle line.
	local header = CreateFrame("Frame", nil, root)
	header:SetPoint("TOPLEFT", root, "TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
	header:SetPoint("TOPRIGHT", root, "TOPRIGHT", -FRAME_PADDING, -FRAME_PADDING)
	header:SetHeight(HEADER_HEIGHT)
	self.header = header

	local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("LEFT")
	title:SetText(addonInfo.title)
	self.titleText = title
	title:SetTextColor(HEADER_COLOR.red, HEADER_COLOR.green, HEADER_COLOR.blue)

	local scroll = CreateFrame("ScrollFrame", nil, root)
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -FRAME_PADDING)
	scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -FRAME_PADDING, FRAME_PADDING)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(INITIAL_WIDTH - FRAME_PADDING * 2, 1)
	scroll:SetScrollChild(content)

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(frame, delta)
		local hidden = math.max(0, content:GetHeight() - frame:GetHeight())
		local wanted = frame:GetVerticalScroll() - delta * WHEEL_STEP

		frame:SetVerticalScroll(math.min(math.max(wanted, 0), hidden))
	end)

	self.content = content
	self.pool = Addon.EntryBlockPool.New(content, self.actions)
end

--- A clickable title plus the rule under it. The line is what stops the sections
--- from reading as one long list; the click is what collapses them.
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

		-- Built after the font was chosen, so it has to catch up on its own.
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

--- Collapsed sections are remembered by id, and an expanded one drops its key
--- rather than storing false, so the saved table only ever holds what differs
--- from the default.
---@param sectionID string
function OwnTrackerFrame:ToggleSection(sectionID)
	if self.collapsedSections[sectionID] then
		self.collapsedSections[sectionID] = nil
	else
		self.collapsedSections[sectionID] = true
	end

	self:Render(self.lastSections)
end

--- Once a quest item button exists, the blocks around it are protected frames,
--- and combat forbids moving, resizing or hiding those. Waiting is the only
--- legal answer — PLAYER_REGEN_ENABLED brings the refresh straight back.
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
		return
	end

	self.pool:ReleaseAll()
	self.usedHeaders = 0
	self.lastSections = sections

	local width = self.content:GetWidth()
	local offset = 0

	-- Numbered in reading order across every section, the way the player scans
	-- the list — not by the game's internal watch index.
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

	self.content:SetHeight(math.max(offset, 1))
end

--- The header strip. Exposed so the composition root can hang buttons on it
--- without this frame having to know what they do — and so they all centre on
--- the same line whatever their size.
---@return table
function OwnTrackerFrame:HeaderAnchor()
	return self.header
end

--- The panel itself, kept apart from Render because it changes on a preference
--- and not on every quest update.
---@param appearance TrackerAppearance
function OwnTrackerFrame:SetAppearance(appearance)
	self.root:SetSize(appearance.width, appearance.height)
	self.content:SetWidth(appearance.width - FRAME_PADDING * 2)

	local signature = BackdropSignature(appearance)

	if signature ~= self.backdropSignature then
		self.backdropSignature = signature
		self.root:SetBackdrop(BackdropFrom(appearance))
	end

	self.root:SetBackdropColor(
		appearance.backgroundColor.red,
		appearance.backgroundColor.green,
		appearance.backgroundColor.blue,
		appearance.opacity
	)
	self.root:SetBackdropBorderColor(
		appearance.borderColor.red,
		appearance.borderColor.green,
		appearance.borderColor.blue,
		appearance.borderOpacity
	)
end

---@param style TrackerFontStyle
function OwnTrackerFrame:SetFont(style)
	self.fontStyle = style

	Addon.FontStyler.Apply(self.titleText, style, TITLE_SIZE_DELTA)

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

--- Dragging is off until the player asks for it.
---
--- A tracker that moves whenever a click lands on it gets nudged out of place
--- by accident, and the frame covers a good part of the screen. Edit mode makes
--- moving deliberate, and the outline says the frame is listening.
---@param isEditing boolean
function OwnTrackerFrame:SetEditing(isEditing)
	self.root:EnableMouse(isEditing)
	self.editOutline:SetShown(isEditing)
end

--- Scale is separate from size: it multiplies everything, text included, while
--- width and height only change how much room the list has.
---@param scale number
function OwnTrackerFrame:SetScale(scale)
	self.root:SetScale(scale)
end

--- Back to where a fresh install puts it, for when the frame has been dragged
--- somewhere unreachable — off screen, or under another addon.
function OwnTrackerFrame:ResetPosition()
	wipe(self.position)
	self.root:ClearAllPoints()
	self:RestorePosition()
end

---@param isShown boolean
function OwnTrackerFrame:SetShown(isShown)
	if self:IsLockedByCombat() then
		return
	end

	self.root:SetShown(isShown)
end

Addon.OwnTrackerFrame = OwnTrackerFrame
