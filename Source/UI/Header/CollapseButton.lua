local _, Addon = ...

--- O mesmo botao que o rastreador da Blizzard poe no canto do cabecalho, no
--- tamanho em que a arte foi feita.
local BUTTON_WIDTH = 18
local BUTTON_HEIGHT = 19

local COLLAPSE_ATLAS = "ui-questtrackerbutton-collapse-all"
local COLLAPSE_PRESSED_ATLAS = "ui-questtrackerbutton-collapse-all-pressed"
local EXPAND_ATLAS = "ui-questtrackerbutton-expand-all"
local EXPAND_PRESSED_ATLAS = "ui-questtrackerbutton-expand-all-pressed"
local HIGHLIGHT_ATLAS = "ui-questtrackerbutton-red-highlight"

--- Recolhe o rastreador ate sobrar so o cabecalho, e o traz de volta.
---@class TrackerCollapseButton
---@field private onToggle fun(): boolean Devolve o estado depois do clique.
---@field private isCollapsed boolean
local TrackerCollapseButton = {}
TrackerCollapseButton.__index = TrackerCollapseButton

---@param onToggle fun(): boolean
---@return TrackerCollapseButton
function TrackerCollapseButton.New(onToggle)
	return setmetatable({ onToggle = onToggle, isCollapsed = false }, TrackerCollapseButton)
end

---@private
function TrackerCollapseButton:Paint()
	if not self.button then
		return
	end

	if self.isCollapsed then
		self.button:SetNormalAtlas(EXPAND_ATLAS)
		self.button:SetPushedAtlas(EXPAND_PRESSED_ATLAS)
		return
	end

	self.button:SetNormalAtlas(COLLAPSE_ATLAS)
	self.button:SetPushedAtlas(COLLAPSE_PRESSED_ATLAS)
end

---@private
---@return string
function TrackerCollapseButton:TooltipText()
	return self.isCollapsed and Addon.L.TRACKER_EXPAND or Addon.L.TRACKER_COLLAPSE
end

---@param row HeaderButtonRow
---@param isCollapsed boolean
function TrackerCollapseButton:Attach(row, isCollapsed)
	local button = CreateFrame("Button", nil, row:Frame())
	button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	button:SetHighlightAtlas(HIGHLIGHT_ATLAS)

	button:SetScript("OnEnter", function(owner)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(self:TooltipText())
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function()
		self.isCollapsed = self.onToggle()
		self:Paint()

		if GameTooltip:IsOwned(button) then
			GameTooltip:SetText(self:TooltipText())
		end
	end)

	self.button = button
	self.isCollapsed = isCollapsed
	self:Paint()

	row:Add(button)
end

Addon.TrackerCollapseButton = TrackerCollapseButton
