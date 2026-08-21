local _, Addon = ...

local BUTTON_GAP = 6

--- The buttons live in a strip of their own, the exact width of what is
--- visible, so whatever has to stop before them anchors to the strip instead of
--- guessing that width.
---@class HeaderButtonRow
---@field private strip table
---@field private buttons table[]
local HeaderButtonRow = {}
HeaderButtonRow.__index = HeaderButtonRow

---@param header table
---@return HeaderButtonRow
function HeaderButtonRow.New(header)
	local strip = CreateFrame("Frame", nil, header)
	strip:SetPoint("TOPRIGHT")
	strip:SetPoint("BOTTOMRIGHT")
	strip:SetWidth(0)

	return setmetatable({ strip = strip, buttons = {} }, HeaderButtonRow)
end

--- The strip: parent of the buttons and right edge for whatever precedes them.
---@return table
function HeaderButtonRow:Frame()
	return self.strip
end

---@param button table
function HeaderButtonRow:Add(button)
	table.insert(self.buttons, button)
	self:Layout()
end

function HeaderButtonRow:Layout()
	local offset = 0

	for _, button in ipairs(self.buttons) do
		if button:IsShown() then
			button:ClearAllPoints()
			button:SetPoint("RIGHT", self.strip, "RIGHT", -offset, 0)
			offset = offset + button:GetWidth() + BUTTON_GAP
		end
	end

	self.strip:SetWidth(math.max(offset - BUTTON_GAP, 0))
end

Addon.HeaderButtonRow = HeaderButtonRow
