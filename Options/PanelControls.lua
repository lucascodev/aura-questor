local _, Addon = ...

local LABEL_GAP = 4
local CONTROL_WIDTH = 200
local DROPDOWN_HEIGHT = 24
local SLIDER_HEIGHT = 20
local BUTTON_HEIGHT = 24
local SWATCH_SIZE = 22
local SWATCH_BORDER = 1
local SWATCH_LABEL_GAP = 8
local CHECKBOX_LABEL_GAP = 4
local CLASSIC_CHECK_SIZE = 28
local CLASSIC_LABEL_GAP = 2
local DISABLED_ALPHA = 0.5

local LABEL_COLOR = { red = 0.95, green = 0.72, blue = 0.25 }
local SWATCH_BORDER_COLOR = { red = 0.35, green = 0.33, blue = 0.28, alpha = 1 }

--- The controls a hand-built options page is made of.
---@class PanelControls
local PanelControls = {}

---@param parent table
---@param text string
---@return table
local function AddLabel(parent, text)
	local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	label:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, LABEL_GAP)
	label:SetText(text)
	label:SetTextColor(LABEL_COLOR.red, LABEL_COLOR.green, LABEL_COLOR.blue)

	return label
end

---@param parent table
---@param options { label: string, choices: fun(): PreferenceChoice[], get: fun(): string, set: fun(value: string) }
---@return table
function PanelControls.Dropdown(parent, options)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(CONTROL_WIDTH, DROPDOWN_HEIGHT)

	AddLabel(frame, options.label)

	local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
	dropdown:SetAllPoints()

	dropdown:SetupMenu(function(_, rootDescription)
		for _, choice in ipairs(options.choices()) do
			rootDescription:CreateRadio(choice.label, function(value)
				return value == options.get()
			end, function(value)
				options.set(value)
				dropdown:GenerateMenu()
			end, choice.id)
		end
	end)

	function frame:Refresh()
		dropdown:GenerateMenu()
	end

	return frame
end

---@param parent table
---@param options { label: string, get: fun(): number, number, number, set: fun(red: number, green: number, blue: number) }
---@return table
function PanelControls.ColorSwatch(parent, options)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(SWATCH_SIZE, SWATCH_SIZE)

	local edge = button:CreateTexture(nil, "BACKGROUND")
	edge:SetColorTexture(
		SWATCH_BORDER_COLOR.red,
		SWATCH_BORDER_COLOR.green,
		SWATCH_BORDER_COLOR.blue,
		SWATCH_BORDER_COLOR.alpha
	)
	edge:SetAllPoints()

	local fill = button:CreateTexture(nil, "ARTWORK")
	fill:SetPoint("TOPLEFT", SWATCH_BORDER, -SWATCH_BORDER)
	fill:SetPoint("BOTTOMRIGHT", -SWATCH_BORDER, SWATCH_BORDER)

	local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	label:SetPoint("LEFT", button, "RIGHT", SWATCH_LABEL_GAP, 0)
	label:SetText(options.label)

	function button:Refresh()
		fill:SetColorTexture(options.get())
	end

	button:SetScript("OnClick", function(owner)
		local red, green, blue = options.get()

		Addon.ColorPicker.Open(red, green, blue, function(pickedRed, pickedGreen, pickedBlue)
			options.set(pickedRed, pickedGreen, pickedBlue)
			owner:Refresh()
		end)
	end)

	button:Refresh()

	return button
end

--- Refreshes into nothing: a button holds no value to catch up on, and every
--- control on a page is asked alike when it opens.
---@param parent table
---@param options { label: string, run: fun() }
---@return table
function PanelControls.Button(parent, options)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(CONTROL_WIDTH, BUTTON_HEIGHT)
	button:SetText(options.label)

	function button:Refresh() end

	button:SetScript("OnClick", options.run)

	return button
end

--- O checkbox clássico de marca dourada, o mesmo das páginas de opções dos
--- addons tradicionais. Desabilitado aparece desmarcado e escurecido: o
--- template não tem arte própria de desabilitado, e uma marca acesa num
--- controle que não pode agir afirmaria um estado que não existe.
---@param parent table
---@param options { label: string, get: fun(): boolean, set: fun(value: boolean), isEnabled: (fun(): boolean)?, tooltip: string? }
---@return table
function PanelControls.ClassicCheckbox(parent, options)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox:SetSize(CLASSIC_CHECK_SIZE, CLASSIC_CHECK_SIZE)

	local label = checkbox.Text

	if not label then
		label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		label:SetPoint("LEFT", checkbox, "RIGHT", CLASSIC_LABEL_GAP, 0)
	end

	label:SetText(options.label)

	checkbox:SetScript("OnClick", function(owner)
		options.set(owner:GetChecked() == true)
	end)

	if options.tooltip then
		checkbox:SetScript("OnEnter", function(owner)
			GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
			GameTooltip:SetText(options.label)
			GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		checkbox:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	function checkbox:Refresh()
		local isEnabled = options.isEnabled == nil or options.isEnabled()

		checkbox:SetChecked(isEnabled and options.get())
		checkbox:SetEnabled(isEnabled)
		checkbox:SetAlpha(isEnabled and 1 or DISABLED_ALPHA)
		label:SetFontObject(isEnabled and GameFontHighlight or GameFontDisable)
	end

	checkbox:Refresh()

	return checkbox
end

---@param parent table
---@param options { label: string, get: fun(): boolean, set: fun(value: boolean) }
---@return table
function PanelControls.Checkbox(parent, options)
	local checkbox = CreateFrame("CheckButton", nil, parent, "SettingsCheckboxTemplate")
	checkbox:SetText(options.label)
	checkbox:SetNormalFontObject(GameFontHighlight)
	checkbox:GetFontString():SetPoint("LEFT", checkbox, "RIGHT", CHECKBOX_LABEL_GAP, 0)

	function checkbox:Refresh()
		checkbox:SetChecked(options.get())
	end

	checkbox:SetScript("OnClick", function(owner)
		options.set(owner:GetChecked())
	end)

	checkbox:Refresh()

	return checkbox
end

---@param parent table
---@param options { label: string, minimum: number, maximum: number, step: number, get: fun(): number, set: fun(value: number) }
---@return table
function PanelControls.Slider(parent, options)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(CONTROL_WIDTH, SLIDER_HEIGHT)

	AddLabel(frame, options.label)

	local slider = CreateFrame("Slider", nil, frame, "MinimalSliderWithSteppersTemplate")
	slider:SetAllPoints()

	local steps = (options.maximum - options.minimum) / options.step

	slider:Init(options.get(), options.minimum, options.maximum, steps, {
		[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
			MinimalSliderWithSteppersMixin.Label.Right,
			function(value)
				return WHITE_FONT_COLOR:WrapTextInColorCode(tostring(value))
			end
		),
	})

	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		options.set(value)
	end)

	function frame:Refresh()
		slider:SetValue(options.get())
	end

	return frame
end

Addon.PanelControls = PanelControls
