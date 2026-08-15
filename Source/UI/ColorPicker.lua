local _, Addon = ...

---@class ColorPicker
local ColorPicker = {}

---@param red number
---@param green number
---@param blue number
---@param onPicked fun(red: number, green: number, blue: number)
function ColorPicker.Open(red, green, blue, onPicked)
	ColorPickerFrame:SetupColorPickerAndShow({
		r = red,
		g = green,
		b = blue,
		hasOpacity = false,
		swatchFunc = function()
			onPicked(ColorPickerFrame:GetColorRGB())
		end,
		cancelFunc = function()
			onPicked(red, green, blue)
		end,
	})
end

Addon.ColorPicker = ColorPicker
