local _, Addon = ...

local BUTTON_SIZE = 24

local FRAME_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local PRESSED_ATLAS = "UI-QuestTrackerButton-QuestItem-Frame"
local HIGHLIGHT_ATLAS = "ui-questtrackerbutton-red-highlight"

local BUTTON_LABEL = "I"
local LABEL_COLOR = { red = 1, green = 0.95, blue = 0.85 }

--- Opens the integrations page from the tracker header.
---@class TrackerIntegrationButton
---@field private onClick fun()
local TrackerIntegrationButton = {}
TrackerIntegrationButton.__index = TrackerIntegrationButton

---@param onClick fun()
---@return TrackerIntegrationButton
function TrackerIntegrationButton.New(onClick)
	return setmetatable({ onClick = onClick }, TrackerIntegrationButton)
end

---@param row HeaderButtonRow
function TrackerIntegrationButton:Attach(row)
	local button = CreateFrame("Button", nil, row:Frame())
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetNormalAtlas(FRAME_ATLAS)
	button:SetPushedAtlas(PRESSED_ATLAS)
	button:SetHighlightAtlas(HIGHLIGHT_ATLAS)

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER")
	label:SetText(BUTTON_LABEL)
	label:SetTextColor(LABEL_COLOR.red, LABEL_COLOR.green, LABEL_COLOR.blue)

	button:SetScript("OnEnter", function(owner)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(Addon.L.PAGE_INTEGRATION)
		GameTooltip:AddLine(Addon.L.INTEGRATION_BUTTON_TIP, 1, 1, 1)
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
function TrackerIntegrationButton:SetShown(isShown)
	if not self.button then
		return
	end

	self.button:SetShown(isShown)
	self.row:Layout()
end

Addon.TrackerIntegrationButton = TrackerIntegrationButton
