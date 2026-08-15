local _, Addon = ...

local COMPLETE_POPUP = "COMPLETE"

--- Missões que se completam à distância entram numa fila de avisos do cliente,
--- fora da lista de observadas. Quem alimenta a fila no QUEST_AUTOCOMPLETE é o
--- rastreador da Blizzard, que este addon esconde; registrar por conta própria
--- garante o aviso sem depender dele. AddAutoQuestPopUp ignora repetidos, então
--- o som toca uma vez só, alimente a fila quem alimentar.
---@class QuestPopupSource
local QuestPopupSource = {}

function QuestPopupSource.Start()
	local listener = CreateFrame("Frame")

	listener:RegisterEvent("QUEST_AUTOCOMPLETE")
	listener:SetScript("OnEvent", function(_, _, questID)
		if AddAutoQuestPopUp(questID, COMPLETE_POPUP) then
			PlaySound(SOUNDKIT.UI_AUTO_QUEST_COMPLETE)
		end
	end)
end

---@class QuestPopup
---@field questID number
---@field popUpType string COMPLETE ou OFFER.

---@return QuestPopup[]
function QuestPopupSource.ReadAll()
	local popups = {}

	for index = 1, GetNumAutoQuestPopUps() do
		local questID, popUpType = GetAutoQuestPopUp(index)

		table.insert(popups, { questID = questID, popUpType = popUpType })
	end

	return popups
end

---@param questID number
---@return string?
function QuestPopupSource.Find(questID)
	for index = 1, GetNumAutoQuestPopUps() do
		local popupQuestID, popUpType = GetAutoQuestPopUp(index)

		if popupQuestID == questID then
			return popUpType
		end
	end

	return nil
end

Addon.QuestPopupSource = QuestPopupSource
