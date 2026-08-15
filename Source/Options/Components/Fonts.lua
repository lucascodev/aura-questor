local _, Addon = ...

local INTER = [[Interface\AddOns\AuraTrackerQuestor\Media\Fonts\Inter-Regular.ttf]]
local INTER_SEMIBOLD = [[Interface\AddOns\AuraTrackerQuestor\Media\Fonts\Inter-SemiBold.ttf]]
local MONO = [[Interface\AddOns\AuraTrackerQuestor\Media\Fonts\JetBrainsMono-Regular.ttf]]

---@param name string
---@param path string
---@param size number
---@return table
local function Make(name, path, size)
	local font = CreateFont("AuraTrackerQuestor" .. name)
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
