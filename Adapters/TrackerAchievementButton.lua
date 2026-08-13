local _, Addon = ...

local BUTTON_SIZE = 24

--- A font string centres on its bounding box, descender space included, which
--- leaves the letter sitting low inside the frame. One pixel up puts it back —
--- the same correction the numbered quest pins needed.
local LABEL_OFFSET_Y = 1

--- The red frame the tracker already uses around a quest item, empty of any
--- glyph — which is what lets a letter sit inside it and still look like it
--- belongs beside the filter button.
local FRAME_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local HIGHLIGHT_ATLAS = "ui-questtrackerbutton-red-highlight"

local BUTTON_LABEL = "A"
local LABEL_COLOR = { red = 1, green = 0.95, blue = 0.85 }

--- The binding the game itself uses for the achievement panel, so the tooltip
--- shows whatever key the player actually has set — and nothing extra if they
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
	button:SetHighlightAtlas(HIGHLIGHT_ATLAS)

	-- OVERLAY so the letter draws above the frame rather than under it.
	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER", button, "CENTER", 0, LABEL_OFFSET_Y)
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
