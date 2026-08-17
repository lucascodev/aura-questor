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

--- Whether the quest can be turned in from here, without walking to anyone.
--- The flag lives on the quest log entry and stays there whether or not the
--- banner ever showed, so the popup queue alone misses a quest completed
--- before login or one whose announcement was already dismissed.
---@param questID number
---@return boolean
function QuestPopupSource.CanComplete(questID)
	if not C_QuestLog.IsComplete(questID) then
		return false
	end

	if QuestPopupSource.Find(questID) == COMPLETE_POPUP then
		return true
	end

	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	local info = questLogIndex and C_QuestLog.GetInfo(questLogIndex)

	return info ~= nil and info.isAutoComplete == true
end

--- Turns the quest in from the tracker and drops its banner from the queue.
---@param questID number
function QuestPopupSource.Complete(questID)
	RemoveAutoQuestPopUp(questID)
	ShowQuestComplete(questID)
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
