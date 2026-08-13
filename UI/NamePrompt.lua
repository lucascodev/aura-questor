local _, Addon = ...

local DIALOG_KEY = "AURATRACKERQUESTOR_NAME_PROMPT"

--- Asks the player to type a name.
---
--- The dialog is registered once and its text and handler are swapped per use:
--- StaticPopup keys are a global namespace, and one addon holding several of
--- them differing only in wording is how that namespace gets crowded.
---@class NamePrompt
local NamePrompt = {}

StaticPopupDialogs[DIALOG_KEY] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

---@param question string
---@param onAccept fun(name: string)
function NamePrompt.Ask(question, onAccept)
	local dialog = StaticPopupDialogs[DIALOG_KEY]

	dialog.text = question

	-- Cleared explicitly: the dialog is shared, and a handler left over from the
	-- previous use would prefill this one with the last thing shown.
	dialog.OnShow = nil
	dialog.OnAccept = function(popup)
		-- The edit box is reached through the accessor, not a field: the dialog
		-- builds its widgets on demand, so there is nothing at popup.editBox.
		local name = strtrim(popup:GetEditBox():GetText())

		-- An empty name would create a profile nobody can point at again.
		if name ~= "" then
			onAccept(name)
		end
	end

	StaticPopup_Show(DIALOG_KEY)
end

--- Shows text for the player to copy. The same dialog is reused with its accept
--- handler emptied, since there is nothing to accept, only something to read.
---@param question string
---@param text string
function NamePrompt.Show(question, text)
	local dialog = StaticPopupDialogs[DIALOG_KEY]

	dialog.text = question
	dialog.OnAccept = nil
	dialog.OnShow = function(popup)
		local editBox = popup:GetEditBox()

		editBox:SetText(text)
		editBox:HighlightText()
	end

	StaticPopup_Show(DIALOG_KEY)
end

Addon.NamePrompt = NamePrompt
