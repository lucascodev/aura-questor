local _, Addon = ...

local BADGE_SIZE = 30
local BADGE_GLOW_SIZE = 38
local BADGE_GAP = 6

--- A font string centres on its bounding box, descender included, which leaves
--- the digit looking low inside the pin. One pixel up puts it back.
local NUMBER_OFFSET_Y = 1

local TITLE_SIZE_DELTA = 0
local LINE_SIZE_DELTA = -1

--- The border art of the game's own objective bar is taller than the bar and
--- hangs over it, by the same amount above and below. The row reserves that
--- whole height and the bar sits centred in it.
local BAR_DEFAULT_HEIGHT = 12
local BAR_BORDER_MARGIN = 7
local BAR_BORDER_FILE = [[Interface\PaperDollInfoFrame\UI-Character-Skills-BarBorder]]
local BAR_BORDER_WIDTH = 9
local BAR_BORDER_OVERHANG = 3
local FULL_PERCENT = 100
local BAR_BACKGROUND_COLOR = { red = 0.04, green = 0.07, blue = 0.18, alpha = 1 }
local BAR_FILL_COLOR = { red = 0.26, green = 0.42, blue = 1 }
local BAR_COMPLETE_COLOR = { red = 0.16, green = 0.55, blue = 0.28 }

--- A countdown gets a card of its own: the number is the thing being watched,
--- and as one more dashed line it reads like a footnote.
local CARD_PADDING = 8
local CARD_GAP = 4
local CARD_ART_TEXT_INSET_X = 15
local CARD_ART_TEXT_INSET_Y = 14
local CARD_HIGHLIGHT_SIZE_DELTA = 9
local CARD_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
}
local CARD_BACKGROUND_COLOR = { red = 0.04, green = 0.05, blue = 0.09, alpha = 0.75 }
local CARD_BORDER_COLOR = { red = 0.32, green = 0.29, blue = 0.24, alpha = 1 }

--- Hung off the right edge, on the block's vertical centre: at the head of the
--- title it squeezed the name aside to make room for the icon.
local ITEM_SIZE = 32
local ITEM_GAP = 6
local ITEM_ICON_INSET = 2
--- The standard trim that cuts the baked-in edge off an icon before framing it.
local ITEM_ICON_CROP = 0.08
local ITEM_BORDER_ATLAS = "UI-HUD-ActionBar-IconFrame"
--- Andar não dispara evento, então o alcance é conferido por tempo, no mesmo
--- ritmo e vermelho do botão de item da Blizzard.
local ITEM_RANGE_INTERVAL = 0.3
local ITEM_OUT_OF_RANGE_COLOR = { red = 1, green = 0.1, blue = 0.1 }
local TAG_SIZE = 18
local TAG_GAP = 3
local GROUP_SIZE = 20
local GROUP_GAP = 4
local LINE_SPACING = 2

--- Shown when a quest reports an item but no icon comes with it. An empty
--- button would look like the feature is broken; this says "found it, missing
--- the art".
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local BADGE_GLOW_ATLAS = "UI-QuestPoi-OuterGlow"
local BADGE_COLOR = { red = 0.6, green = 0.75, blue = 1 }

--- Recycles the widgets that draw a single entry.
---
--- Pooling is not an optimisation here. QUEST_LOG_UPDATE fires constantly, and
--- creating frames per refresh would leak widgets for the whole session, WoW
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

--- Which slot a row takes: the pool keeps one list per kind, and a block's
--- shape is the sequence of kinds its rows filled.
---@param row table
---@return string
local function RowKind(row)
	if row.widgetSetID then
		return "widget"
	end

	if row.card then
		return "card"
	end

	if row.percent then
		return "bar"
	end

	return "line"
end

---@param entry TrackerEntry
---@return string
local function EntryKey(entry)
	return entry.kind .. ":" .. tostring(entry.id)
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

	-- The same glow the map puts behind a pin it is following, for the art that
	-- has no followed version of itself.
	local badgeGlow = badge:CreateTexture(nil, "BACKGROUND")
	badgeGlow:SetAtlas(BADGE_GLOW_ATLAS)
	badgeGlow:SetSize(BADGE_GLOW_SIZE, BADGE_GLOW_SIZE)
	badgeGlow:SetPoint("CENTER")
	badgeGlow:Hide()

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
		badgeGlow = badgeGlow,
		tag = tag,
		title = title,
		group = group,
		lines = {},
		bars = {},
		cards = {},
		widgets = {},
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

		Addon.EntryTooltip.Show(actions, block.entry, owner)
	end)

	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	frame:SetScript("OnClick", function(owner, mouseButton)
		if not block.entry then
			return
		end

		if mouseButton == "RightButton" then
			Addon.EntryTooltip.ShowMenu(actions, block.entry, owner)
			return
		end

		if actions:InsertChatLink(block.entry) then
			return
		end

		actions:OpenDetails(block.entry)
	end)

	return block
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
--- One of the three pieces the game's bar frame is made of. The ends keep their
--- width and the middle stretches between them, which is why the right end
--- takes the same coordinates mirrored.
---@param bar table
---@param left number
---@param right number
---@return table
local function CreateBarBorder(bar, left, right)
	local border = bar:CreateTexture(nil, "ARTWORK")

	border:SetTexture(BAR_BORDER_FILE)
	border:SetTexCoord(left, right, 0.193548, 0.774193)

	return border
end

---@param block table
---@return table
local function CreateBar(block)
	local bar = CreateFrame("StatusBar", nil, block.frame)
	bar:SetMinMaxValues(0, FULL_PERCENT)

	local background = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
	background:SetColorTexture(
		BAR_BACKGROUND_COLOR.red,
		BAR_BACKGROUND_COLOR.green,
		BAR_BACKGROUND_COLOR.blue,
		BAR_BACKGROUND_COLOR.alpha
	)
	background:SetAllPoints()

	local borderLeft = CreateBarBorder(bar, 0.007843, 0.043137)
	borderLeft:SetPoint("LEFT", -BAR_BORDER_OVERHANG, 0)

	local borderRight = CreateBarBorder(bar, 0.043137, 0.007843)
	borderRight:SetPoint("RIGHT", BAR_BORDER_OVERHANG, 0)

	local borderMiddle = CreateBarBorder(bar, 0.113726, 0.1490196)
	borderMiddle:SetPoint("TOPLEFT", borderLeft, "TOPRIGHT")
	borderMiddle:SetPoint("BOTTOMRIGHT", borderRight, "BOTTOMLEFT")

	bar.borderEnds = { borderLeft, borderRight }

	local label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("CENTER", 0, -1)

	bar.label = label

	return bar
end

---@param block table
---@return table
--- A hidden container stops receiving widget updates, and it does not catch
--- up by itself when it is shown again: whatever the set dropped in the
--- meantime stays drawn beside what it added, which is how a delve came back
--- with last visit's tier card next to the current one. Registering again on
--- show rebuilds it from the set as it is now.
---@param container table
local function ResyncWidgetSet(container)
	local widgetSetID = container.widgetSetID

	if not widgetSetID then
		return
	end

	container:UnregisterForWidgetSet()
	container:RegisterForWidgetSet(widgetSetID, DefaultWidgetLayout)
end

--- The same two layout keys Blizzard's stage container declares. The step set
--- carries one header widget per state (tier known, tier unknown, hidden) and
--- relies on them overlapping, the current one drawn on top; the default
--- layout stacks them, and a delve showed last visit's tier under this one.
local WIDGET_ANCHOR_POINT = "TOPRIGHT"
local WIDGET_RELATIVE_POINT = "TOPRIGHT"

---@param block table
---@return table
local function CreateWidgetContainer(block)
	local container = CreateFrame("Frame", nil, block.frame, "UIWidgetContainerTemplate")
	container.verticalAnchorPoint = WIDGET_ANCHOR_POINT
	container.verticalRelativePoint = WIDGET_RELATIVE_POINT
	container:HookScript("OnShow", ResyncWidgetSet)

	return container
end

---@param block table
---@return table
local function CreateCard(block)
	local card = CreateFrame("Frame", nil, block.frame, "BackdropTemplate")
	card:SetBackdrop(CARD_BACKDROP)
	card:SetBackdropColor(
		CARD_BACKGROUND_COLOR.red,
		CARD_BACKGROUND_COLOR.green,
		CARD_BACKGROUND_COLOR.blue,
		CARD_BACKGROUND_COLOR.alpha
	)
	card:SetBackdropBorderColor(
		CARD_BORDER_COLOR.red,
		CARD_BORDER_COLOR.green,
		CARD_BORDER_COLOR.blue,
		CARD_BORDER_COLOR.alpha
	)

	local art = card:CreateTexture(nil, "BACKGROUND")
	art:SetAllPoints()
	art:Hide()

	local highlight = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	highlight:SetJustifyH("LEFT")

	local caption = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	caption:SetJustifyH("LEFT")

	card.art = art
	card.highlight = highlight
	card.caption = caption

	return card
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
	-- Anchored once, to the RIGHT: the vertical centre follows the block's
	-- height on its own, and a protected frame cannot be re-anchored in combat.
	item:SetPoint("RIGHT")
	item:SetAttribute("type", "item")
	-- Since 10.0 the secure handler only fires when the registered press matches
	-- the ActionButtonUseKeyDown cvar. Registering both instead would make the
	-- handler toggle pass-through on every click, a protected call in combat.
	item:RegisterForClicks(GetCVarBool("ActionButtonUseKeyDown") and "AnyDown" or "AnyUp")

	block.icon = item:CreateTexture(nil, "ARTWORK")
	block.icon:SetPoint("TOPLEFT", ITEM_ICON_INSET, -ITEM_ICON_INSET)
	block.icon:SetPoint("BOTTOMRIGHT", -ITEM_ICON_INSET, ITEM_ICON_INSET)
	block.icon:SetTexCoord(
		ITEM_ICON_CROP,
		1 - ITEM_ICON_CROP,
		ITEM_ICON_CROP,
		1 - ITEM_ICON_CROP
	)

	if C_Texture.GetAtlasInfo(ITEM_BORDER_ATLAS) then
		local border = item:CreateTexture(nil, "OVERLAY")
		border:SetAllPoints()
		border:SetAtlas(ITEM_BORDER_ATLAS)
	end

	block.itemCooldown = CreateFrame("Cooldown", nil, item, "CooldownFrameTemplate")
	block.itemCooldown:SetAllPoints(block.icon)

	block.itemCount = item:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	block.itemCount:SetPoint("BOTTOMRIGHT", -ITEM_ICON_INSET, ITEM_ICON_INSET)

	-- OnUpdate only runs while the button is shown, so the check costs nothing
	-- when no entry carries an item.
	local sinceCheck = 0
	item:SetScript("OnUpdate", function(_, elapsed)
		sinceCheck = sinceCheck + elapsed

		if sinceCheck < ITEM_RANGE_INTERVAL then
			return
		end

		sinceCheck = 0

		local isInRange = block.entry and Addon.QuestItemSource.InRange(block.entry)

		if isInRange == false then
			block.icon:SetVertexColor(
				ITEM_OUT_OF_RANGE_COLOR.red,
				ITEM_OUT_OF_RANGE_COLOR.green,
				ITEM_OUT_OF_RANGE_COLOR.blue
			)
		else
			block.icon:SetVertexColor(1, 1, 1)
		end
	end)

	return item
end

--- A secure button's attributes are locked while the player is in combat, and so
--- is hiding it. Leaving it exactly as it was is the only legal move, the same
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
	-- A recycled button may still be red from the entry it drew before.
	block.icon:SetVertexColor(1, 1, 1)

	-- One charge is implied by the button existing; only more is worth a number.
	block.itemCount:SetShown(item.charges > 1)
	block.itemCount:SetText(item.charges)
	block.itemCooldown:SetCooldown(item.cooldownStart, item.cooldownDuration)

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

---@param height number
function EntryBlockPool:SetProgressBarHeight(height)
	self.progressBarHeight = height
end

---@private
---@return number
function EntryBlockPool:BarHeight()
	return self.progressBarHeight or BAR_DEFAULT_HEIGHT
end

--- Devolve a altura, porque ela sai do tamanho da fonte escolhida e o layout
--- não tem como saber antes de o texto estar posto.
--- Registrar de novo o mesmo conjunto destruiria e recriaria cada widget a
--- cada refresh; o jogo mantém o conteúdo vivo sozinho.
---@private
---@param container table
---@param widgetSetID number
---@return number
function EntryBlockPool:ApplyWidgetSet(container, widgetSetID)
	if container.widgetSetID ~= widgetSetID then
		container:RegisterForWidgetSet(widgetSetID, DefaultWidgetLayout)
	end

	container:Show()

	return math.max(container:GetHeight(), 1)
end

---@private
---@param card table
---@param content TrackerObjectiveCard
---@param width number
---@return number
function EntryBlockPool:ApplyCard(card, content, width)
	-- Com arte própria a moldura desenhada sobraria por baixo dela, aparecendo
	-- nas beiradas onde o atlas é transparente. A borda decorada do atlas também
	-- pede recuos maiores para o texto não sentar sobre o desenho.
	local hasArt = content.atlas ~= nil
	local frameAlpha = hasArt and 0 or 1
	local paddingLeft = hasArt and CARD_ART_TEXT_INSET_X or CARD_PADDING
	local top = hasArt and CARD_ART_TEXT_INSET_Y or CARD_PADDING
	local textWidth = width - paddingLeft * 2

	card:SetWidth(width)

	card.art:SetShown(hasArt)
	card:SetBackdropColor(
		CARD_BACKGROUND_COLOR.red,
		CARD_BACKGROUND_COLOR.green,
		CARD_BACKGROUND_COLOR.blue,
		CARD_BACKGROUND_COLOR.alpha * frameAlpha
	)
	card:SetBackdropBorderColor(
		CARD_BORDER_COLOR.red,
		CARD_BORDER_COLOR.green,
		CARD_BORDER_COLOR.blue,
		frameAlpha
	)

	if hasArt then
		card.art:SetAtlas(content.atlas)
	end

	card.highlight:SetText(content.highlight)
	card.highlight:SetWidth(textWidth)
	card.highlight:ClearAllPoints()
	card.highlight:SetPoint("TOPLEFT", paddingLeft, -top)

	if self.fontStyle then
		Addon.FontStyler.Apply(card.highlight, self.fontStyle, CARD_HIGHLIGHT_SIZE_DELTA)
	end

	top = top + card.highlight:GetStringHeight()

	if content.caption then
		card.caption:SetText(content.caption)
		card.caption:SetWidth(textWidth)
		card.caption:ClearAllPoints()
		card.caption:SetPoint("TOPLEFT", paddingLeft, -(top + CARD_GAP))
		card.caption:Show()

		if self.fontStyle then
			Addon.FontStyler.Apply(card.caption, self.fontStyle, LINE_SIZE_DELTA)
		end

		top = top + CARD_GAP + card.caption:GetStringHeight()
	else
		card.caption:Hide()
	end

	local height = top + CARD_PADDING

	-- A arte tem altura própria; um card mais baixo cortaria a moldura no meio
	-- do desenho.
	if hasArt then
		local atlasInfo = C_Texture.GetAtlasInfo(content.atlas)
		height = math.max(height, atlasInfo.height)
	end

	card:SetHeight(height)

	return height
end

---@private
---@param bar table
---@param percent number
function EntryBlockPool:ApplyBar(bar, percent)
	local color = percent >= FULL_PERCENT and BAR_COMPLETE_COLOR or BAR_FILL_COLOR
	local height = self:BarHeight()

	bar:SetHeight(height)

	for _, border in ipairs(bar.borderEnds) do
		border:SetSize(BAR_BORDER_WIDTH, height + BAR_BORDER_MARGIN)
	end

	bar:SetStatusBarTexture(self.progressBarTexture)
	bar:SetStatusBarColor(color.red, color.green, color.blue)
	bar:SetValue(percent)
	bar.label:SetFormattedText(PERCENTAGE_STRING, percent)

	if self.fontStyle then
		Addon.FontStyler.ApplyMono(bar.label, self.fontStyle, LINE_SIZE_DELTA)
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

---@param block table
---@param rows table[]
---@return boolean
local function MatchesShape(block, rows)
	if not block.shape or #block.shape ~= #rows then
		return false
	end

	for index, row in ipairs(rows) do
		if block.shape[index].kind ~= RowKind(row) then
			return false
		end
	end

	return true
end

--- New text that wraps to a different height would need the rows below it
--- moved, which combat forbids; the old text stays until then.
---@param line table
---@param text string
---@param height number
---@return boolean written
local function RewriteText(line, text, height)
	local previous = line:GetText()

	line:SetText(text)

	if line:GetStringHeight() ~= height then
		line:SetText(previous)
		return false
	end

	return true
end

local function RewriteLine(line, row, height)
	if not RewriteText(line, row.text, height) then
		return
	end

	line:SetTextColor(row.color.red, row.color.green, row.color.blue)
end

---@private
---@param block table
---@param entry TrackerEntry
function EntryBlockPool:RewriteBlock(block, entry)
	local rows = Addon.EntryText.Rows(entry)

	if not MatchesShape(block, rows) then
		return
	end

	block.entry = entry

	local titleColor = Addon.EntryText.TitleColor(entry, entry.isSuperTracked == true)
	block.title:SetTextColor(titleColor.red, titleColor.green, titleColor.blue)

	local usedLines = 0
	local usedBars = 0

	block.countdown = nil

	for index, row in ipairs(rows) do
		local slot = block.shape[index]

		if slot.kind == "bar" then
			usedBars = usedBars + 1
			self:ApplyBar(block.bars[usedBars], row.percent)
		elseif slot.kind == "line" then
			usedLines = usedLines + 1
			RewriteLine(block.lines[usedLines], row, slot.height)

			if row.expiresAt then
				block.countdown = {
					line = block.lines[usedLines],
					expiresAt = row.expiresAt,
					height = slot.height,
				}
			end
		end
	end
end

--- Rewrites only the countdown lines, from the deadline each block kept, so a
--- ticking second costs no game call and no layout. A line that would change
--- height keeps the text it had: growing a block is what combat forbids.
---@return boolean hasCountdown Whether any block is still counting down.
function EntryBlockPool:RefreshCountdowns()
	local now = time()
	local hasCountdown = false

	for index = 1, self.used do
		local countdown = self.blocks[index].countdown

		if countdown then
			local secondsLeft = countdown.expiresAt - now

			if secondsLeft > 0 then
				hasCountdown = true
				RewriteText(countdown.line, Addon.EntryText.TimeLeft(secondsLeft), countdown.height)
			end
		end
	end

	return hasCountdown
end

--- In combat the blocks around a quest item are protected: nothing may move,
--- grow, appear or hide. Their words may still change, since font strings and
--- status bars are not guarded, and a fight is exactly when a "slay creatures"
--- bar moves. So the blocks on screen are rewritten in place, entry by entry,
--- and anything whose shape changed waits for the refresh that follows the
--- combat.
---@param sections TrackerSection[]
function EntryBlockPool:RewriteInPlace(sections)
	local entriesByKey = {}

	for _, section in ipairs(sections) do
		for _, entry in ipairs(section.entries) do
			entriesByKey[EntryKey(entry)] = entry
		end
	end

	for index = 1, self.used do
		local block = self.blocks[index]
		local entry = block.entry and entriesByKey[EntryKey(block.entry)]

		if entry then
			self:RewriteBlock(block, entry)
		end
	end
end

--- Blocks are handed out again in order, so the ones still in use keep their
--- frames shown from one render to the next: hiding and reshowing them would
--- fire every OnHide and OnShow underneath for nothing.
function EntryBlockPool:ReleaseAll()
	self.used = 0
end

--- Called once the render has taken what it needs.
function EntryBlockPool:HideUnused()
	for index = self.used + 1, #self.blocks do
		self.blocks[index].frame:Hide()
	end
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
	block.countdown = nil
	block.frame:SetWidth(width)

	-- Before anything is measured: every height below comes from GetStringHeight,
	-- and changing the font afterwards would lay the block out for the old one.
	self:ApplyFont(block)
	block.badgeNumber:SetText(index)

	-- An entry that names its own art wins: a world event has a specific icon,
	-- and replacing it with a generic marker is how five different events end up
	-- looking like the same thing.
	local style = Addon.EntryPinStyles.For(entry)
	local hasPin = not style.isHidden
	local isSuperTracked = entry.isSuperTracked == true

	-- Drawn at the size the game reports when it reports one: the world quest
	-- icons are not all square. The rest keep their own size.
	local pinIcon = hasPin and entry.pinIcon

	block.badge:SetShown(hasPin)
	block.badgeNumber:SetShown(hasPin and style.showsNumber and not pinIcon)
	block.badgeIcon:SetShown(pinIcon ~= nil)
	block.badgeGlow:SetShown(hasPin and isSuperTracked and style.glowsWhenSelected == true)

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

	-- The item hangs off the right edge; the group eye and the tag take the tail
	-- of the title's line. Objectives keep the same indent either way, so the
	-- column stays straight down the list.
	local objectiveLeft = hasPin and BADGE_SIZE + BADGE_GAP or 0
	local itemWidth = hasItem and ITEM_SIZE + ITEM_GAP or 0
	local groupWidth = entry.canFindGroup and GROUP_SIZE + GROUP_GAP or 0
	local tagWidth = entry.tagAtlas and TAG_SIZE + TAG_GAP or 0

	local titleColor = Addon.EntryText.TitleColor(entry, isSuperTracked)
	block.title:SetWidth(width - objectiveLeft - groupWidth - tagWidth - itemWidth)
	block.title:SetText(entry.hidesTitle and "" or Addon.EntryText.Title(entry))
	block.title:SetTextColor(titleColor.red, titleColor.green, titleColor.blue)

	-- Everything lines up against the title's own line, not against the pin.
	-- Measuring the row by the pin instead pushed the objectives a full pin
	-- height below the name and left a hole under every quest.
	local titleHeight = entry.hidesTitle and 0 or block.title:GetStringHeight()

	block.title:ClearAllPoints()
	block.title:SetPoint("TOPLEFT", block.frame, "TOPLEFT", objectiveLeft, 0)

	local pinSize = BADGE_SIZE

	if hasPin then
		-- The pin is taller than the text and hangs down past it, into the
		-- column the objectives are indented clear of.
		pinSize = style.size or BADGE_SIZE
		block.badge:SetSize(pinSize, pinSize)
		block.badge:ClearAllPoints()
		block.badge:SetPoint("TOPLEFT", block.frame, "TOPLEFT", (BADGE_SIZE - pinSize) / 2, 0)
	end

	if entry.canFindGroup then
		CenterInRow(block.group, "TOPRIGHT", 0, titleHeight, GROUP_SIZE)
	end

	if entry.tagAtlas then
		CenterInRow(block.tag, "TOPRIGHT", -groupWidth, titleHeight, TAG_SIZE)
	end

	local height = titleHeight
	local rows = Addon.EntryText.Rows(entry)
	local rowWidth = width - objectiveLeft - itemWidth
	local usedLines = 0
	local usedBars = 0
	local usedCards = 0
	local usedWidgets = 0
	local shape = {}

	for _, row in ipairs(rows) do
		table.insert(shape, { kind = RowKind(row) })

		if row.widgetSetID then
			usedWidgets = usedWidgets + 1

			local container = block.widgets[usedWidgets] or CreateWidgetContainer(block)
			block.widgets[usedWidgets] = container

			container:ClearAllPoints()
			container:SetPoint("TOPLEFT", block.frame, "TOPLEFT", objectiveLeft, -(height + LINE_SPACING))

			height = height + LINE_SPACING + self:ApplyWidgetSet(container, row.widgetSetID)
		elseif row.card then
			usedCards = usedCards + 1

			local card = block.cards[usedCards] or CreateCard(block)
			block.cards[usedCards] = card

			card:ClearAllPoints()
			card:SetPoint("TOPLEFT", block.frame, "TOPLEFT", objectiveLeft, -(height + LINE_SPACING))
			card:Show()

			height = height + LINE_SPACING + self:ApplyCard(card, row.card, rowWidth)
		elseif row.percent then
			usedBars = usedBars + 1

			local bar = block.bars[usedBars] or CreateBar(block)
			block.bars[usedBars] = bar

			self:ApplyBar(bar, row.percent)
			bar:SetWidth(rowWidth)
			bar:ClearAllPoints()
			bar:SetPoint(
				"TOPLEFT",
				block.frame,
				"TOPLEFT",
				objectiveLeft,
				-(height + LINE_SPACING + BAR_BORDER_MARGIN / 2)
			)
			bar:Show()

			height = height + LINE_SPACING + self:BarHeight() + BAR_BORDER_MARGIN
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

			local lineHeight = line:GetStringHeight()
			shape[#shape].height = lineHeight

			if row.expiresAt then
				block.countdown = { line = line, expiresAt = row.expiresAt, height = lineHeight }
			end

			height = height + LINE_SPACING + lineHeight
		end
	end

	block.shape = shape

	for lineIndex = usedLines + 1, #block.lines do
		block.lines[lineIndex]:Hide()
	end

	for cardIndex = usedCards + 1, #block.cards do
		block.cards[cardIndex]:Hide()
	end

	for widgetIndex = usedWidgets + 1, #block.widgets do
		local container = block.widgets[widgetIndex]

		if container.widgetSetID then
			container:UnregisterForWidgetSet()
		end

		container:Hide()
	end

	for barIndex = usedBars + 1, #block.bars do
		block.bars[barIndex]:Hide()
	end

	-- A one-line entry can be shorter than its own pin or its item button; the
	-- block still has to contain them.
	height = math.max(height, hasPin and pinSize or 0, hasItem and ITEM_SIZE or 0)
	block.frame:SetHeight(height)

	return block, height
end

Addon.EntryBlockPool = EntryBlockPool
