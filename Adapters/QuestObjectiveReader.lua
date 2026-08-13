local _, Addon = ...

--- Reads a quest's objective lines.
---
--- Shared by every provider that deals in quests — regular, world and bonus —
--- so what counts as an objective is decided in exactly one place.
---@class QuestObjectiveReader
local QuestObjectiveReader = {}

local PROGRESS_BAR_TYPE = "progressbar"
local FULL_PERCENT = 100

---@param questID number
---@param objective table
---@return number?
local function ReadPercent(questID, objective)
	if objective.type ~= PROGRESS_BAR_TYPE then
		return nil
	end

	if objective.finished then
		return FULL_PERCENT
	end

	return GetQuestProgressBarPercent(questID)
end

---@param questID number
---@return TrackerObjective[]
function QuestObjectiveReader.Read(questID)
	local objectives = {}

	for _, objective in ipairs(C_QuestLog.GetQuestObjectives(questID) or {}) do
		local percent = ReadPercent(questID, objective)

		if percent or (objective.text and objective.text ~= "") then
			table.insert(objectives, {
				text = objective.text,
				isComplete = objective.finished,
				percent = percent,
			})
		end
	end

	return objectives
end

Addon.QuestObjectiveReader = QuestObjectiveReader
