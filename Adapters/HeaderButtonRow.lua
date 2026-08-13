local _, Addon = ...

local BUTTON_GAP = 6

---@class HeaderButtonRow
---@field private header table
---@field private buttons table[]
local HeaderButtonRow = {}
HeaderButtonRow.__index = HeaderButtonRow

---@param header table
---@return HeaderButtonRow
function HeaderButtonRow.New(header)
	return setmetatable({ header = header, buttons = {} }, HeaderButtonRow)
end

---@return table
function HeaderButtonRow:Frame()
	return self.header
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
			button:SetPoint("RIGHT", self.header, "RIGHT", -offset, 0)
			offset = offset + button:GetWidth() + BUTTON_GAP
		end
	end
end

Addon.HeaderButtonRow = HeaderButtonRow
