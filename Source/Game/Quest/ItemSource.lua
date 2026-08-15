local _, Addon = ...

--- Toda entrada que vive no diário de missões pode carregar item, não só a
--- missão comum. A lista existe para não consultar o diário com o id de uma
--- conquista, que por acaso pode coincidir com o de alguma missão.
local QUEST_LOG_KINDS = {
	quest = true,
	worldQuest = true,
	bonus = true,
}

--- Reads the usable item a quest carries, if it has one.
---@class QuestItemSource
local QuestItemSource = {}

---@param entry TrackerEntry
---@return EntryItem?
function QuestItemSource.Read(entry)
	if not QUEST_LOG_KINDS[entry.kind] then
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

	local cooldownStart, cooldownDuration = GetQuestLogSpecialItemCooldown(questLogIndex)

	return {
		link = link,
		texture = texture,
		charges = charges or 0,
		cooldownStart = cooldownStart or 0,
		cooldownDuration = cooldownDuration or 0,
	}
end

--- Nil quando o item não tem restrição de alcance nenhuma, e aí não há o que
--- pintar de vermelho.
---@param entry TrackerEntry
---@return boolean?
function QuestItemSource.InRange(entry)
	if not QUEST_LOG_KINDS[entry.kind] then
		return nil
	end

	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(entry.id)
	if not questLogIndex then
		return nil
	end

	local inRange = IsQuestLogSpecialItemInRange(questLogIndex)
	if inRange == nil then
		return nil
	end

	return inRange == 1
end

Addon.QuestItemSource = QuestItemSource
