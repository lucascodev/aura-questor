local _, Addon = ...

local DIALOG_KEY = "AURAQUESTOR_CONFIRM"

--- Asks yes or no before something that cannot be undone.
---
--- Its own dialog rather than the name prompt with the text box hidden: turning
--- fields on and off per use breaks the first time someone forgets one.
---@class ConfirmPrompt
local ConfirmPrompt = {}

StaticPopupDialogs[DIALOG_KEY] = {
	text = "",
	button1 = YES,
	button2 = NO,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
}

---@param question string
---@param onAccept fun()
function ConfirmPrompt.Ask(question, onAccept)
	local dialog = StaticPopupDialogs[DIALOG_KEY]

	dialog.text = question
	dialog.OnAccept = onAccept

	StaticPopup_Show(DIALOG_KEY)
end

Addon.ConfirmPrompt = ConfirmPrompt
