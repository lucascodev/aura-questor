local _, Addon = ...

--- Page geometry: plain maths, no frames, so the layout can be tested
--- fora do jogo. As alturas chegam medidas; aqui vive o empilhamento.
---@class OptionsSchematic
local OptionsSchematic = {}

---@param items number[] Altura de cada linha, na ordem; divisores entram como a espessura deles.
---@param rowGap number
---@return number
function OptionsSchematic.ContentHeight(items, rowGap)
	if #items == 0 then
		return 0
	end

	local total = (#items - 1) * rowGap

	for _, height in ipairs(items) do
		total = total + height
	end

	return total
end

---@param contentHeight number
---@param hasTitle boolean
---@param metrics { cardPadding: number, titleBlock: number }
---@return number
function OptionsSchematic.CardHeight(contentHeight, hasTitle, metrics)
	return metrics.cardPadding * 2
		+ (hasTitle and metrics.titleBlock or 0)
		+ contentHeight
end

---@param heights number[]
---@param top number
---@param gap number
---@return number[] tops
function OptionsSchematic.Tops(heights, top, gap)
	local tops = {}
	local current = top

	for _, height in ipairs(heights) do
		table.insert(tops, current)
		current = current + height + gap
	end

	return tops
end

Addon.OptionsSchematic = OptionsSchematic
