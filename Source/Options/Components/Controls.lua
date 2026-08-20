local _, Addon = ...

local Theme = Addon.OptionsTheme
local Fonts = Addon.OptionsFonts

local WHITE = [[Interface\Buttons\WHITE8X8]]

local SLIDER_BLOCK_HEIGHT = 46
local SLIDER_TOP = 18
local SWATCH_SIZE = 28
local SWATCH_HEX_GAP = 10
local BUTTON_HEIGHT = 24
local BUTTON_TEXT_PAD = 36
local DISABLED_ALPHA = 0.5
local MENU_SCREEN_FRACTION = 0.4

---@class OptionsControls
local OptionsControls = {}

---@param parent table
---@param options { get: fun(): boolean, set: fun(value: boolean), isEnabled: (fun(): boolean)? }
---@return table
function OptionsControls.Switch(parent, options)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox:SetSize(Theme.SWITCH_WIDTH, Theme.SWITCH_HEIGHT)

	if checkbox.Text then
		checkbox.Text:SetText("")
	end

	checkbox:SetScript("OnClick", function(owner)
		options.set(owner:GetChecked() == true)
	end)

	function checkbox:Refresh()
		local isEnabled = options.isEnabled == nil or options.isEnabled()

		checkbox:SetChecked(isEnabled and options.get())
		checkbox:SetEnabled(isEnabled)
		checkbox:SetAlpha(isEnabled and 1 or DISABLED_ALPHA)
	end

	checkbox:Refresh()

	return checkbox
end

---@param parent table
---@param options { label: string, minimum: number, maximum: number, step: number, get: fun(): number, set: fun(value: number), suffix: string? }
---@return table
function OptionsControls.Slider(parent, options)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(Theme.COLUMN_WIDTH, SLIDER_BLOCK_HEIGHT)

	local label = frame:CreateFontString(nil, "ARTWORK")
	label:SetFontObject(Fonts.LABEL)
	label:SetPoint("TOPLEFT")
	label:SetText(options.label)
	label:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

	local value = frame:CreateFontString(nil, "ARTWORK")
	value:SetFontObject(Fonts.MONO)
	value:SetPoint("TOPRIGHT")
	value:SetTextColor(
		Theme.SECONDARY_COLOR.red,
		Theme.SECONDARY_COLOR.green,
		Theme.SECONDARY_COLOR.blue
	)

	local slider = CreateFrame("Slider", nil, frame, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("TOPLEFT", 0, -SLIDER_TOP)
	slider:SetPoint("TOPRIGHT", 0, -SLIDER_TOP)
	slider:SetHeight(SLIDER_BLOCK_HEIGHT - SLIDER_TOP)

	local steps = (options.maximum - options.minimum) / options.step
	slider:Init(options.get(), options.minimum, options.maximum, steps, {})

	local function Paint(current)
		value:SetText(("%d%s"):format(current, options.suffix or ""))
	end

	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, current)
		Paint(current)
		options.set(current)
	end)

	function frame:Refresh()
		slider:SetValue(options.get())
		Paint(options.get())
	end

	frame:Refresh()

	return frame
end

---@param parent table
---@param options { width: number?, choices: fun(): PreferenceChoice[], get: fun(): string, set: fun(value: string) }
---@return table
function OptionsControls.Dropdown(parent, options)
	local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	dropdown:SetSize(options.width or Theme.COLUMN_WIDTH, Theme.INPUT_HEIGHT)

	dropdown:SetupMenu(function(_, rootDescription)
		-- Cada addon de mídia instalado soma entradas ao acervo, e a lista inteira
		-- passava da borda da tela: o que caía embaixo ficava impossível de
		-- escolher. Com a rolagem o menu para de crescer na altura.
		rootDescription:SetScrollMode(UIParent:GetHeight() * MENU_SCREEN_FRACTION)

		for _, choice in ipairs(options.choices()) do
			rootDescription:CreateRadio(choice.label, function(id)
				return id == options.get()
			end, function(id)
				options.set(id)
				dropdown:GenerateMenu()
			end, choice.id)
		end
	end)

	function dropdown:Refresh()
		dropdown:GenerateMenu()
	end

	return dropdown
end

---@param parent table
---@param options { get: fun(): number, number, number, set: fun(red: number, green: number, blue: number) }
---@return table
function OptionsControls.ColorSwatch(parent, options)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(Theme.COLUMN_WIDTH, SWATCH_SIZE)

	local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
	button:SetSize(SWATCH_SIZE, SWATCH_SIZE)
	button:SetPoint("LEFT")

	local hex = frame:CreateFontString(nil, "ARTWORK")
	hex:SetFontObject(Fonts.MONO)
	hex:SetPoint("LEFT", button, "RIGHT", SWATCH_HEX_GAP, 0)
	hex:SetTextColor(Theme.MUTED_COLOR.red, Theme.MUTED_COLOR.green, Theme.MUTED_COLOR.blue)

	function frame:Refresh()
		local red, green, blue = options.get()

		button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = Theme.RULE_THICKNESS })
		button:SetBackdropColor(red, green, blue, 1)
		button:SetBackdropBorderColor(
			Theme.BORDER_STRONG_COLOR.red,
			Theme.BORDER_STRONG_COLOR.green,
			Theme.BORDER_STRONG_COLOR.blue,
			1
		)
		hex:SetText("#" .. Addon.HexColor.FromRGB(red, green, blue))
	end

	button:SetScript("OnClick", function()
		local red, green, blue = options.get()

		Addon.ColorPicker.Open(red, green, blue, function(pickedRed, pickedGreen, pickedBlue)
			options.set(pickedRed, pickedGreen, pickedBlue)
			frame:Refresh()
		end)
	end)

	frame:Refresh()

	return frame
end

---@param parent table
---@param options { label: string, run: fun(), variant: ("primary"|"secondary"|"danger")? }
---@return table
function OptionsControls.Button(parent, options)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetText(options.label)
	button:SetSize(button:GetFontString():GetStringWidth() + BUTTON_TEXT_PAD, BUTTON_HEIGHT)

	if options.variant == "danger" then
		button:GetFontString():SetTextColor(
			Theme.DANGER_COLOR.red,
			Theme.DANGER_COLOR.green,
			Theme.DANGER_COLOR.blue
		)
	end

	button:SetScript("OnClick", options.run)

	function button:Refresh() end

	return button
end

---@param parent table
---@param options { label: string, value: string }
---@return table
function OptionsControls.Fact(parent, options)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(Theme.COLUMN_WIDTH * 2, Theme.FACT_LINE_HEIGHT)

	local label = frame:CreateFontString(nil, "ARTWORK")
	label:SetFontObject(Fonts.MONO)
	label:SetPoint("TOPLEFT")
	label:SetText(options.label)
	label:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)

	local value = frame:CreateFontString(nil, "ARTWORK")
	value:SetFontObject(Fonts.MONO)
	value:SetPoint("TOPLEFT", Theme.FACT_LABEL_WIDTH, 0)
	value:SetText(options.value)
	value:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

	function frame:Refresh() end

	return frame
end

---@param parent table
---@param text string
---@param color table
---@return table
function OptionsControls.Badge(parent, text, color)
	local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")

	local label = badge:CreateFontString(nil, "ARTWORK")
	label:SetFontObject(Fonts.HINT)
	label:SetPoint("CENTER")

	badge.label = label

	function badge:Paint(newText, newColor)
		label:SetText(newText)
		label:SetTextColor(newColor.red, newColor.green, newColor.blue)
		badge:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = Theme.RULE_THICKNESS })
		badge:SetBackdropColor(newColor.red, newColor.green, newColor.blue, 0.08)
		badge:SetBackdropBorderColor(newColor.red, newColor.green, newColor.blue, 0.25)
		badge:SetSize(label:GetStringWidth() + 16, 18)
	end

	badge:Paint(text, color)

	return badge
end


Addon.OptionsControls = OptionsControls
