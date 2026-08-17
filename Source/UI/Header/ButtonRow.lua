local _, Addon = ...

local BUTTON_GAP = 6

--- Os botoes vivem numa faixa propria, colada a direita do cabecalho e do
--- tamanho exato do que esta visivel. Quem precisa parar antes deles, como o
--- titulo, ancora nessa faixa em vez de adivinhar a largura.
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

--- A faixa: pai dos botoes e limite direito do que vem antes deles.
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
