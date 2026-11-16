local _, Addon = ...

--- Reads what a widget set says, one line per widget, so a tooltip can carry it
--- without the game's widget frames.
---
--- Those frames are not ours to draw: GameTooltip_AddWidgetSet keeps a single
--- widget container on GameTooltip for the whole interface, and called from an
--- addon it is built and written in tainted code. The map's own point tooltip
--- then reuses it, measures text that comes back secret, and errors with this
--- addon's name on it.
---@class WidgetTextReader
local WidgetTextReader = {}

local Visualization = Enum.UIWidgetVisualizationType

--- Only the kinds whose whole content is text. Bars, icons and models have
--- nothing a tooltip line could carry, and the map still shows them.
---@type table<number, { Read: fun(widgetID: number): table?, IsShown: fun(info: table): boolean }>
local TEXT_KINDS = {
	[Visualization.TextWithState] = {
		Read = function(widgetID)
			return C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(widgetID)
		end,
		IsShown = function(info)
			return info.shownState ~= Enum.WidgetShownState.Hidden
		end,
	},
	[Visualization.IconAndText] = {
		Read = function(widgetID)
			return C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(widgetID)
		end,
		IsShown = function(info)
			return info.state ~= Enum.IconAndTextWidgetState.Hidden
		end,
	},
}

---@param widget table UIWidgetInfo
---@return { text: string, orderIndex: number, widgetID: number }?
local function ShownText(widget)
	local kind = TEXT_KINDS[widget.widgetType]

	if not kind then
		return nil
	end

	-- Nil while the game has not loaded the widget yet.
	local info = kind.Read(widget.widgetID)

	if not info or not kind.IsShown(info) or info.text == "" then
		return nil
	end

	return { text = info.text, orderIndex = info.orderIndex, widgetID = widget.widgetID }
end

--- The game lays a set out by orderIndex, not in the order it lists it.
---@param first { orderIndex: number, widgetID: number }
---@param second { orderIndex: number, widgetID: number }
---@return boolean
local function IsDrawnBefore(first, second)
	if first.orderIndex ~= second.orderIndex then
		return first.orderIndex < second.orderIndex
	end

	return first.widgetID < second.widgetID
end

---@param widgetSetID number
---@return string[]
function WidgetTextReader.Lines(widgetSetID)
	local shown = {}

	for _, widget in ipairs(C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetID) or {}) do
		local text = ShownText(widget)

		if text then
			table.insert(shown, text)
		end
	end

	table.sort(shown, IsDrawnBefore)

	local lines = {}

	for _, text in ipairs(shown) do
		table.insert(lines, text.text)
	end

	return lines
end

Addon.WidgetTextReader = WidgetTextReader
