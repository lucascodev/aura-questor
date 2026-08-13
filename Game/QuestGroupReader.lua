local _, Addon = ...

--- Maps each quest to the heading it sits under in the quest log.
---
--- The log is a flat list where headers introduce the quests beneath them, a
--- zone, a campaign, a category. Walking it once yields the grouping, which the
--- tracker shows under each title and the filters use to offer them by group.
---@class QuestGroupReader
local QuestGroupReader = {}

---@return table<number, string>
function QuestGroupReader.ReadAll()
	local groupNames = {}
	local currentHeader = nil

	for index = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(index)

		if info then
			if info.isHeader then
				currentHeader = info.title
			elseif info.questID then
				groupNames[info.questID] = currentHeader
			end
		end
	end

	return groupNames
end

Addon.QuestGroupReader = QuestGroupReader
