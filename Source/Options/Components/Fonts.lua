local _, Addon = ...

--- Num cliente CJK as três viram a fonte do jogo: o painel inteiro é texto
--- localizado, e fonte sem os glifos renderiza quadrados.
local hasGameFont = Addon.ClientFont.PrefersGameFont()
local INTER = hasGameFont and Addon.ClientFont.GamePath()
	or [[Interface\AddOns\AuraQuestor\Media\Fonts\Inter-Regular.ttf]]
local INTER_SEMIBOLD = hasGameFont and Addon.ClientFont.GamePath()
	or [[Interface\AddOns\AuraQuestor\Media\Fonts\Inter-SemiBold.ttf]]
local MONO = hasGameFont and Addon.ClientFont.GamePath()
	or [[Interface\AddOns\AuraQuestor\Media\Fonts\JetBrainsMono-Regular.ttf]]

---@param name string
---@param path string
---@param size number
---@return table
local function Make(name, path, size)
	local font = CreateFont("AuraQuestor" .. name)
	font:SetFont(path, size, "")

	return font
end

---@class OptionsFonts
local OptionsFonts = {
	TITLE = Make("OptionsTitle", INTER_SEMIBOLD, 18),
	SUBTITLE = Make("OptionsSubtitle", INTER, 12),
	LABEL = Make("OptionsLabel", INTER, 12),
	STRONG = Make("OptionsStrong", INTER_SEMIBOLD, 12),
	BIG = Make("OptionsBig", MONO, 16),
	EYEBROW = Make("OptionsEyebrow", MONO, 10),
	HINT = Make("OptionsHint", MONO, 10),
	MONO = Make("OptionsMono", MONO, 11),
	EDGE = Make("OptionsEdge", MONO, 9),
}

Addon.OptionsFonts = OptionsFonts
