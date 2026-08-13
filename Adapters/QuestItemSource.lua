local _, Addon = ...

local QUEST_KIND = "quest"

--- Reads the usable item a quest carries, if it has one.
---@class QuestItemSource
local QuestItemSource = {}

---@param entry TrackerEntry
---@return EntryItem?
function QuestItemSource.Read(entry)
	if entry.kind ~= QUEST_KIND then
		return nil
	end

	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(entry.id)
	if not questLogIndex then
		return nil
	end

	local link, texture, charges = GetQuestLogSpecialItemInfo(questLogIndex)
	if not link then
		return nil
	end

	return { link = link, texture = texture, charges = charges or 0 }
end

Addon.QuestItemSource = QuestItemSource
