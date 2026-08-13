local _, Addon = ...

local BADGE_SIZE = 30
local BADGE_GAP = 6

--- Event art is drawn smaller than a quest pin — it reads better that way, and
--- it is the size it had before the pins grew. The column stays BADGE_SIZE wide
--- either way, so a smaller pin is centred in it instead of shifting the text.
local EVENT_PIN_SIZE = 26

--- A font string centres on its bounding box, descender included, which leaves
--- the digit looking low inside the pin. One pixel up puts it back.
local NUMBER_OFFSET_Y = 1

local TITLE_SIZE_DELTA = 0
local LINE_SIZE_DELTA = -1

local BAR_HEIGHT = 14
local FULL_PERCENT = 100
local BAR_BACKGROUND_COLOR = { red = 0, green = 0, blue = 0, alpha = 0.55 }
local BAR_FILL_COLOR = { red = 0.16, green = 0.55, blue = 0.28 }
local BAR_COMPLETE_COLOR = { red = 0.35, green = 0.35, blue = 0.35 }

--- Every numbered quest pin comes as the same four-part set, so the family name
--- is enough to build one.
---@param prefix string
---@return table
local function NumberedPin(prefix)
	return {
		normal = prefix,
		pressed = prefix .. "-Pressed",
		selected = prefix .. "-SuperTracked",
		selectedPressed = prefix .. "-Pressed-SuperTracked",
		showsNumber = true,
	}
end

--- The same set, for a pin that carries an icon where the number would be.
---@param prefix string
---@return table
local function IconPin(prefix)
	local style = NumberedPin(prefix)
	style.showsNumber = false

	return style
end

--- Blizzard's own pin art, matched to what each kind of objective is. Using the
--- same families the map uses is what makes a campaign quest here look like the
--- campaign quest there.
local PIN_STYLES = {
	normal = NumberedPin("UI-QuestPoi-QuestNumber"),
	campaign = NumberedPin("UI-QuestPoiCampaign-QuestNumber"),
	legendary = NumberedPin("UI-QuestPoiLegendary-QuestNumber"),
	recurring = NumberedPin("UI-QuestPoiRecurring-QuestNumber"),
	important = NumberedPin("UI-QuestPoiImportant-QuestNumber"),
	meta = NumberedPin("UI-QuestPoiWrapper-QuestNumber"),

	-- Blizzard gives a world quest the same ring as a plain quest, with the type
	-- icon where the number would be.
	worldQuest = IconPin("UI-QuestPoi-QuestNumber"),

	bonus = {
		normal = "worldquest-questmarker-epic",
		pressed = "worldquest-questmarker-epic-down",
		selected = "worldquest-questmarker-epic-supertracked",
		selectedPressed = "worldquest-questmarker-epic-down-supertracked",
		showsNumber = false,
	},

	-- No pin at all. A number that cannot be clicked and points at nothing is
	-- noise, and the column it reserved goes back to the text.
	none = { isHidden = true, showsNumber = false },
}

-- An event pin is a map pin, and the game draws those with the same marker
-- whenever the event has no icon of its own.
PIN_STYLES.areaPoi = PIN_STYLES.bonus

--- A pin drawn with art the entry supplied. There are no pressed or selected
--- variants of these, so all four states share one texture.
---@param atlas string
---@return table
local function OwnArtPin(atlas)
	return {
		normal = atlas,
		pressed = atlas,
		selected = atlas,
		selectedPressed = atlas,
		showsNumber = false,
		size = EVENT_PIN_SIZE,
	}
end
--- Sized to sit on the title's line rather than tower over it, now that it is
--- inline instead of parked in the corner.
local ITEM_SIZE = 22
local ITEM_GAP = 4
local TAG_SIZE = 18
local TAG_GAP = 3
local GROUP_SIZE = 20
local GROUP_GAP = 4
local LINE_SPACING = 2

--- Shown when a quest reports an item but no icon comes with it. An empty
--- button would look like the feature is broken; this says "found it, missing
--- the art".
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local TITLE_COLOR = { red = 1, green = 0.82, blue = 0 }
local TITLE_COMPLETE_COLOR = { red = 0.55, green = 0.85, blue = 0.55 }

--- The one the arrow is following reads brighter than the rest. The pin already
--- says so, but only if you are looking at the pin.
local TITLE_TRACKED_COLOR = { red = 1, green = 0.97, blue = 0.88 }
local OBJECTIVE_COLOR = { red = 0.82, green = 0.82, blue = 0.82 }
local OBJECTIVE_COMPLETE_COLOR = { red = 0.55, green = 0.55, blue = 0.55 }
local TIME_COLOR = { red = 0.4, green = 0.7, blue = 1 }
local GROUP_COLOR = { red = 0.45, green = 0.65, blue = 0.9 }

local COLOR_CHANNEL_MAXIMUM = 255
local FULL_ALPHA = 1

--- Gold for the part already done, so "9/16" reads as progress at a glance
--- instead of as one grey number.
local PROGRESS_HEX = "ffd100"
local BADGE_COLOR = { red = 0.6, green = 0.75, blue = 1 }

--- Recycles the widgets that draw a single entry.
---
--- Pooling is not an optimisation here. QUEST_LOG_UPDATE fires constantly, and
--- creating frames per refresh would leak widgets for the whole session — WoW
--- never frees them.
---@class EntryBlockPool
---@field private parent table
---@field private actions EntryActions
---@field private blocks table[]
---@field private used number
---@field private hasSecureChildren boolean
local EntryBlockPool = {}
EntryBlockPool.__index = EntryBlockPool

---@param parent table
---@param actions EntryActions
---@return EntryBlockPool
function EntryBlockPool.New(parent, actions)
	return setmetatable({
		parent = parent,
		actions = actions,
		blocks = {},
		used = 0,
		hasSecureChildren = false,
		areItemButtonsShown = true,
	}, EntryBlockPool)
end

--- True once any block holds a quest item button, which is what turns the
--- layout into something combat can block.
---@return boolean
function EntryBlockPool:IsProtected()
	return self.hasSecureChildren
end

---@param actions EntryActions
---@param entry TrackerEntry
---@param owner table
--- The actions decide what belongs in the menu, so an entry that supports
--- nothing gets no menu at all rather than one full of dead options.
local function ShowMenu(actions, entry, owner)
	local items = actions:MenuItems(entry)
	if #items == 0 then
		return
	end

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:CreateTitle(entry.title)

		for _, item in ipairs(items) do
			rootDescription:CreateButton(item.label, item.run)
		end
	end)
end

--- The tracker shows a line per objective; the tooltip is where the briefing
--- fits. Anchored left so it never covers the tracker it came from.
---@param actions EntryActions
---@param entry TrackerEntry
---@param owner table
local function ShowEntryTooltip(actions, entry, owner)
	GameTooltip:SetOwner(owner, "ANCHOR_LEFT")

	-- SetText takes an alpha before the wrap flag, unlike AddLine. Passing the
	-- flag straight after the colour lands it in the alpha slot and errors.
	GameTooltip:SetText(
		entry.title,
		TITLE_COLOR.red,
		TITLE_COLOR.green,
		TITLE_COLOR.blue,
		FULL_ALPHA,
		true
	)

	if entry.groupName then
		GameTooltip:AddLine(entry.groupName, GROUP_COLOR.red, GROUP_COLOR.green, GROUP_COLOR.blue)
	end

	local description = actions:Describe(entry)

	if description and description ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(description, 1, 1, 1, true)
	end

	if #entry.objectives > 0 then
		GameTooltip:AddLine(" ")

		for _, objective in ipairs(entry.objectives) do
			local color = objective.isComplete and OBJECTIVE_COMPLETE_COLOR or OBJECTIVE_COLOR
			GameTooltip:AddLine("- " .. objective.text, color.red, color.green, color.blue, true)
		end
	end

	local rewards = actions:Rewards(entry)

	if #rewards > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(REWARDS, TITLE_COLOR.red, TITLE_COLOR.green, TITLE_COLOR.blue)

		for _, reward in ipairs(rewards) do
			GameTooltip:AddLine(reward, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

---@param parent table
---@param actions EntryActions
---@return table
local function CreateBlock(parent, actions)
	local frame = CreateFrame("Button", nil, parent)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- Textures on a Button's HIGHLIGHT layer light up on hover by themselves.
	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetColorTexture(1, 1, 1, 0.05)
	highlight:SetAllPoints()

	-- The pin is Blizzard's own quest POI art, and clicking it does what clicking
	-- it does on the map: points the arrow at that objective.
	local badge = CreateFrame("Button", nil, frame)
	badge:SetSize(BADGE_SIZE, BADGE_SIZE)
	badge:SetPoint("TOPLEFT")

	local badgeNumber = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	badgeNumber:SetPoint("CENTER", badge, "CENTER", 0, NUMBER_OFFSET_Y)
	badgeNumber:SetTextColor(BADGE_COLOR.red, BADGE_COLOR.green, BADGE_COLOR.blue)

	local badgeIcon = badge:CreateTexture(nil, "OVERLAY")
	badgeIcon:SetPoint("CENTER")
	badgeIcon:Hide()

	local tag = frame:CreateTexture(nil, "ARTWORK")
	tag:SetSize(TAG_SIZE, TAG_SIZE)
	tag:Hide()

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", BADGE_SIZE + BADGE_GAP, 0)
	title:SetJustifyH("LEFT")

	-- The green eye Blizzard puts on group content, same atlas and all.
	local group = CreateFrame("Button", nil, frame)
	group:SetSize(GROUP_SIZE, GROUP_SIZE)
	group:SetPoint("TOPRIGHT")
	group:SetNormalAtlas("ui-questtracker-lfg-eye")
	group:SetHighlightAtlas("ui-questtracker-lfg-eye-selected")
	group:Hide()

	local block = {
		frame = frame,
		badge = badge,
		badgeNumber = badgeNumber,
		badgeIcon = badgeIcon,
		tag = tag,
		title = title,
		group = group,
		lines = {},
		bars = {},
	}

	-- Clicking the pin of what is already being followed lets go of it, the way
	-- Blizzard's own quest pin does. Without it there was no way back to no
	-- selection at all once one had been made.
	badge:SetScript("OnClick", function()
		if not block.entry then
			return
		end

		if block.entry.isSuperTracked then
			Addon.SuperTracking.Clear()
			return
		end

		actions:SuperTrack(block.entry)
	end)

	group:SetScript("OnClick", function()
		if not block.entry then
			return
		end

		actions:FindGroup(block.entry)
	end)

	frame:SetScript("OnEnter", function(owner)
		if not block.entry then
			return
		end

		ShowEntryTooltip(actions, block.entry, owner)
	end)

	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	frame:SetScript("OnClick", function(owner, mouseButton)
		if not block.entry then
			return
		end

		if mouseButton == "RightButton" then
			ShowMenu(actions, block.entry, owner)
			return
		end

		actions:OpenDetails(block.entry)
	end)

	return block
end

local MINUTES_PER_HOUR = 60

---@param minutes number
---@return string
local function FormatTimeLeft(minutes)
	if minutes < MINUTES_PER_HOUR then
		return ("%d min"):format(minutes)
	end

	return ("%dh %dmin"):format(math.floor(minutes / MINUTES_PER_HOUR), minutes % MINUTES_PER_HOUR)
end

--- The level reads in the game's own difficulty colour, the same one the quest
--- log uses, so green really means trivial.
---@param entry TrackerEntry
---@return string
local function FormatTitle(entry)
	if not entry.level then
		return entry.title
	end

	local color = GetQuestDifficultyColor(entry.level)

	return ("|cff%02x%02x%02x[%d]|r %s"):format(
		math.floor(color.r * COLOR_CHANNEL_MAXIMUM),
		math.floor(color.g * COLOR_CHANNEL_MAXIMUM),
		math.floor(color.b * COLOR_CHANNEL_MAXIMUM),
		entry.level,
		entry.title
	)
end

--- Highlights the achieved half of an "x/y" count. Objectives that have not
--- started keep a plain zero: colouring it would suggest progress that is not
--- there.
---@param text string
---@return string
local function HighlightProgress(text)
	local current, remainder = text:match("^(%d+)(/%d+.*)$")

	if not current or tonumber(current) == 0 then
		return text
	end

	return ("|cff%s%s|r%s"):format(PROGRESS_HEX, current, remainder)
end

--- The group, the objectives and the expiry clock share one column, so they are
--- collected into a single list first and drawn by one loop. Only objectives get
--- the dash: the others are context, not progress.
---@param entry TrackerEntry
---@return { text: string, color: table, percent: number? }[]
local function CollectRows(entry)
	local rows = {}

	if entry.groupName then
		table.insert(rows, { text = entry.groupName, color = GROUP_COLOR })
	end

	for _, objective in ipairs(entry.objectives) do
		table.insert(rows, {
			text = "- " .. HighlightProgress(objective.text),
			color = objective.isComplete and OBJECTIVE_COMPLETE_COLOR or OBJECTIVE_COLOR,
			percent = objective.percent,
		})
	end

	if entry.timeLeftMinutes and entry.timeLeftMinutes > 0 then
		table.insert(rows, { text = FormatTimeLeft(entry.timeLeftMinutes), color = TIME_COLOR })
	end

	return rows
end

--- Hangs a widget from the top of the block, offset so its middle lines up with
--- the middle of the header row.
---@param widget table
---@param point string TOPLEFT or TOPRIGHT.
---@param offsetX number
---@param rowHeight number
---@param widgetHeight number
local function CenterInRow(widget, point, offsetX, rowHeight, widgetHeight)
	widget:ClearAllPoints()
	widget:SetPoint(point, widget:GetParent(), point, offsetX, -(rowHeight - widgetHeight) / 2)
end

---@param block table
---@return table
local function CreateBar(block)
	local bar = CreateFrame("StatusBar", nil, block.frame)
	bar:SetHeight(BAR_HEIGHT)
	bar:SetMinMaxValues(0, FULL_PERCENT)

	local background = bar:CreateTexture(nil, "BACKGROUND")
	background:SetColorTexture(
		BAR_BACKGROUND_COLOR.red,
		BAR_BACKGROUND_COLOR.green,
		BAR_BACKGROUND_COLOR.blue,
		BAR_BACKGROUND_COLOR.alpha
	)
	background:SetAllPoints()

	local label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("CENTER")

	bar.label = label

	return bar
end

---@param block table
---@return table
local function CreateLine(block)
	local line = block.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	line:SetJustifyH("LEFT")

	return line
end

--- Created only for the rare quest that actually carries an item.
---
--- A SecureActionButton makes every frame above it protected, and moving or
--- hiding a protected frame in combat is blocked. Creating one per block cost
--- that protection on all nineteen blocks while showing zero items.
---@param block table
---@return table
local function CreateItemButton(block)
	local item = CreateFrame("Button", nil, block.frame, "SecureActionButtonTemplate")
	item:SetSize(ITEM_SIZE, ITEM_SIZE)
	item:SetPoint("TOPLEFT", block.frame, "TOPLEFT", BADGE_SIZE + BADGE_GAP, 0)
	item:SetAttribute("type", "item")

	block.icon = item:CreateTexture(nil, "ARTWORK")
	block.icon:SetAllPoints()

	return item
end

--- A secure button's attributes are locked while the player is in combat, and so
--- is hiding it. Leaving it exactly as it was is the only legal move — the same
--- restriction Blizzard's own tracker lives with.
---@param pool EntryBlockPool
---@param block table
---@param entry TrackerEntry
---@return boolean hasItem
local function UpdateItem(pool, block, entry)
	local item = pool.areItemButtonsShown and Addon.QuestItemSource.Read(entry)

	if InCombatLockdown() then
		return block.item ~= nil and block.item:IsShown()
	end

	if not item then
		if block.item then
			block.item:Hide()
		end

		return false
	end

	if not block.item then
		block.item = CreateItemButton(block)
		pool.hasSecureChildren = true
	end

	block.item:SetAttribute("item", item.link)
	block.icon:SetTexture(item.texture or FALLBACK_ICON)
	block.item:Show()

	return true
end

--- Stored rather than applied here: blocks are pooled, so the font is put on
--- each one as it is built, which also covers blocks created later.
---@param style TrackerFontStyle
function EntryBlockPool:SetFont(style)
	self.fontStyle = style
end

--- Off means the button is never created, and a block with no secure child is a
--- block combat cannot lock.
---@param isShown boolean
function EntryBlockPool:SetItemButtonsShown(isShown)
	self.areItemButtonsShown = isShown
end

---@param path string
function EntryBlockPool:SetProgressBarTexture(path)
	self.progressBarTexture = path
end

---@private
---@param bar table
---@param percent number
function EntryBlockPool:ApplyBar(bar, percent)
	local color = percent >= FULL_PERCENT and BAR_COMPLETE_COLOR or BAR_FILL_COLOR

	bar:SetStatusBarTexture(self.progressBarTexture)
	bar:SetStatusBarColor(color.red, color.green, color.blue)
	bar:SetValue(percent)
	bar.label:SetFormattedText(PERCENTAGE_STRING, percent)

	if self.fontStyle then
		Addon.FontStyler.Apply(bar.label, self.fontStyle, LINE_SIZE_DELTA)
	end
end

---@private
---@param block table
function EntryBlockPool:ApplyFont(block)
	if not self.fontStyle then
		return
	end

	Addon.FontStyler.Apply(block.title, self.fontStyle, TITLE_SIZE_DELTA)
end

--- Lines are created as the entry needs them, so each one is dressed on its way
--- into the layout rather than in a sweep that would miss the new ones.
---@private
---@param line table
function EntryBlockPool:ApplyLineFont(line)
	if not self.fontStyle then
		return
	end

	Addon.FontStyler.Apply(line, self.fontStyle, LINE_SIZE_DELTA)
end

function EntryBlockPool:ReleaseAll()
	for _, block in ipairs(self.blocks) do
		block.frame:Hide()
	end

	self.used = 0
end

---@private
---@return table
function EntryBlockPool:Acquire()
	self.used = self.used + 1

	local block = self.blocks[self.used]
	if not block then
		block = CreateBlock(self.parent, self.actions)
		self.blocks[self.used] = block
	end

	block.frame:Show()

	return block
end

--- Widths are set explicitly rather than by anchors because GetStringHeight
--- only reports the wrapped height once the string knows how wide it may be.
---@param entry TrackerEntry
---@param width number
---@param index number Position shown in the badge.
---@return table block, number height
function EntryBlockPool:Build(entry, width, index)
	local block = self:Acquire()
	block.entry = entry
	block.frame:SetWidth(width)

	-- Before anything is measured: every height below comes from GetStringHeight,
	-- and changing the font afterwards would lay the block out for the old one.
	self:ApplyFont(block)
	block.badgeNumber:SetText(index)

	-- An entry that names its own art wins: a world event has a specific icon,
	-- and replacing it with a generic marker is how five different events end up
	-- looking like the same thing.
	local style = entry.pinAtlas and OwnArtPin(entry.pinAtlas)
		or PIN_STYLES[entry.pinStyle]
		or PIN_STYLES.normal
	local hasPin = not style.isHidden
	local isSuperTracked = entry.isSuperTracked == true

	-- Drawn at the size the game reports when it reports one: the world quest
	-- icons are not all square. The rest keep their own size.
	local pinIcon = hasPin and entry.pinIcon

	block.badge:SetShown(hasPin)
	block.badgeNumber:SetShown(hasPin and style.showsNumber and not pinIcon)
	block.badgeIcon:SetShown(pinIcon ~= nil)

	if pinIcon then
		block.badgeIcon:SetAtlas(pinIcon.atlas, pinIcon.width == nil)

		if pinIcon.width then
			block.badgeIcon:SetSize(pinIcon.width, pinIcon.height)
		end
	end

	if hasPin then
		block.badge:SetNormalAtlas(isSuperTracked and style.selected or style.normal)
		block.badge:SetPushedAtlas(isSuperTracked and style.selectedPressed or style.pressed)
		block.badge:SetEnabled(entry.isSuperTrackable == true)
	end

	local hasItem = UpdateItem(self, block, entry)
	block.group:SetShown(entry.canFindGroup)
	block.tag:SetShown(entry.tagAtlas ~= nil)

	if entry.tagAtlas then
		block.tag:SetAtlas(entry.tagAtlas)
	end

	-- The item takes the head of the title's line, the group eye and the tag the
	-- tail; objectives keep the same indent either way, so the column stays
	-- straight down the list.
	local objectiveLeft = hasPin and BADGE_SIZE + BADGE_GAP or 0
	local titleLeft = objectiveLeft + (hasItem and ITEM_SIZE + ITEM_GAP or 0)
	local groupWidth = entry.canFindGroup and GROUP_SIZE + GROUP_GAP or 0
	local tagWidth = entry.tagAtlas and TAG_SIZE + TAG_GAP or 0

	local titleColor = entry.isComplete and TITLE_COMPLETE_COLOR
		or isSuperTracked and TITLE_TRACKED_COLOR
		or TITLE_COLOR
	block.title:SetWidth(width - titleLeft - groupWidth - tagWidth)
	block.title:SetText(FormatTitle(entry))
	block.title:SetTextColor(titleColor.red, titleColor.green, titleColor.blue)

	-- Everything lines up against the title's own line, not against the pin.
	-- Measuring the row by the pin instead pushed the objectives a full pin
	-- height below the name and left a hole under every quest.
	local titleHeight = block.title:GetStringHeight()

	block.title:ClearAllPoints()
	block.title:SetPoint("TOPLEFT", block.frame, "TOPLEFT", titleLeft, 0)

	local pinSize = BADGE_SIZE

	if hasPin then
		-- The pin is taller than the text and hangs down past it, into the
		-- column the objectives are indented clear of.
		pinSize = style.size or BADGE_SIZE
		block.badge:SetSize(pinSize, pinSize)
		block.badge:ClearAllPoints()
		block.badge:SetPoint("TOPLEFT", block.frame, "TOPLEFT", (BADGE_SIZE - pinSize) / 2, 0)
	end

	if hasItem then
		CenterInRow(block.item, "TOPLEFT", objectiveLeft, titleHeight, ITEM_SIZE)
	end

	if entry.canFindGroup then
		CenterInRow(block.group, "TOPRIGHT", 0, titleHeight, GROUP_SIZE)
	end

	if entry.tagAtlas then
		CenterInRow(block.tag, "TOPRIGHT", -groupWidth, titleHeight, TAG_SIZE)
	end

	local height = titleHeight
	local rows = CollectRows(entry)
	local rowWidth = width - objectiveLeft
	local usedLines = 0
	local usedBars = 0

	for _, row in ipairs(rows) do
		if row.percent then
			usedBars = usedBars + 1

			local bar = block.bars[usedBars] or CreateBar(block)
			block.bars[usedBars] = bar

			self:ApplyBar(bar, row.percent)
			bar:SetWidth(rowWidth)
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", block.frame, "TOPLEFT", objectiveLeft, -(height + LINE_SPACING))
			bar:Show()

			height = height + LINE_SPACING + BAR_HEIGHT
		else
			usedLines = usedLines + 1

			local line = block.lines[usedLines] or CreateLine(block)
			block.lines[usedLines] = line

			self:ApplyLineFont(line)
			line:SetWidth(rowWidth)
			line:SetText(row.text)
			line:SetTextColor(row.color.red, row.color.green, row.color.blue)
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", block.frame, "TOPLEFT", objectiveLeft, -(height + LINE_SPACING))
			line:Show()

			height = height + LINE_SPACING + line:GetStringHeight()
		end
	end

	for lineIndex = usedLines + 1, #block.lines do
		block.lines[lineIndex]:Hide()
	end

	for barIndex = usedBars + 1, #block.bars do
		block.bars[barIndex]:Hide()
	end

	-- A one-line entry can be shorter than its own pin; the block still has to
	-- contain it.
	height = math.max(height, hasPin and pinSize or 0)
	block.frame:SetHeight(height)

	return block, height
end

Addon.EntryBlockPool = EntryBlockPool
