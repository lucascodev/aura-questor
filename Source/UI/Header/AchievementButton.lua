local _, Addon = ...

--- No button in the tracker family comes without a glyph of its own, so the
--- quest item frame is the only empty base available. Drawn at the size the art
--- was made for: shrinking it washes the red out to beige.
local BUTTON_SIZE = 24

local FRAME_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local PRESSED_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local HIGHLIGHT_ATLAS = "ui-questtrackerbutton-red-highlight"

local BUTTON_LABEL = "A"
local LABEL_COLOR = { red = 1, green = 0.95, blue = 0.85 }

--- The binding the game itself uses for the achievement panel, so the tooltip
--- shows whatever key the player actually has set, and nothing extra if they
--- have none.
local ACHIEVEMENT_BINDING = "TOGGLEACHIEVEMENT"

--- Opens the achievement panel from the tracker header.
---@class TrackerAchievementButton
---@field private onClick fun()
local TrackerAchievementButton = {}
TrackerAchievementButton.__index = TrackerAchievementButton

---@param onClick fun()
---@return TrackerAchievementButton
function TrackerAchievementButton.New(onClick)
	return setmetatable({ onClick = onClick }, TrackerAchievementButton)
end

--- Handed to the header row, which decides where it sits.
---@param row HeaderButtonRow
function TrackerAchievementButton:Attach(row)
	local button = CreateFrame("Button", nil, row:Frame())
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetNormalAtlas(FRAME_ATLAS)
	button:SetPushedAtlas(PRESSED_ATLAS)
	button:SetHighlightAtlas(HIGHLIGHT_ATLAS)

	-- OVERLAY so the letter draws above the frame rather than under it. Centred
	-- on the button's own box, without a nudge: the letter is set in a font whose
	-- cap height fits the frame, so there is nothing left to correct by hand.
	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER")
	label:SetText(BUTTON_LABEL)
	label:SetTextColor(LABEL_COLOR.red, LABEL_COLOR.green, LABEL_COLOR.blue)

	button:SetScript("OnEnter", function(owner)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(MicroButtonTooltipText(ACHIEVEMENT_BUTTON, ACHIEVEMENT_BINDING))
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function()
		self.onClick()
	end)

	self.button = button
	self.row = row
	row:Add(button)
end

--- TrackerWidget port.
---@param isShown boolean
function TrackerAchievementButton:SetShown(isShown)
	if not self.button then
		return
	end

	self.button:SetShown(isShown)
	self.row:Layout()
end

Addon.TrackerAchievementButton = TrackerAchievementButton
