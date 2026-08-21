local _, Addon = ...
local L = Addon.L

---@class ProgressBarStyles
local ProgressBarStyles = {}

ProgressBarStyles.GAME = "game"
ProgressBarStyles.OWN = "own"

---@type PreferenceChoice[]
ProgressBarStyles.Choices = {
	{ id = ProgressBarStyles.GAME, label = L.PROGRESS_BAR_STYLE_GAME },
	{ id = ProgressBarStyles.OWN, label = L.PROGRESS_BAR_STYLE_OWN },
}

Addon.ProgressBarStyles = ProgressBarStyles
