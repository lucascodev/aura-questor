local _, Addon = ...

local COMPLETE_POPUP = "COMPLETE"

--- Quests that complete from a distance go into a client popup queue, outside
--- the watch list. The one filling that queue on QUEST_AUTOCOMPLETE is
--- Blizzard's tracker, which this addon hides, so registering on our own keeps
--- the popup coming. AddAutoQuestPopUp ignores repeats, so the sound plays once
--- no matter who filled the queue.
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
