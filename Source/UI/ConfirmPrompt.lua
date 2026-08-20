local _, Addon = ...

local DIALOG_KEY = "AURAQUESTOR_CONFIRM"

--- Pergunta sim ou não antes do que não tem como desfazer.
---
--- Dialog próprio, e não o de nome com a caixa de texto escondida: os dois
--- respondem coisas diferentes, e um só com campos ligados e desligados a cada
--- uso erra na primeira vez que alguém esquecer de desligar.
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
