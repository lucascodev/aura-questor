local _, Addon = ...

--- Feeds the arrival counter from the game.
---
--- Two sources, and the first is what makes the ordering usable on day one: the
--- log as it stands when the addon loads, then every quest accepted from there
--- on. Without adopting the log first, a character would need a whole new quest
--- log before "newest first" meant anything.
---@class QuestArrivals
local QuestArrivals = {}

---@param quests QuestSource
---@return number[]
local function ReadLogIDs(quests)
	local questIDs = {}

	for _, quest in ipairs(quests:ListAll()) do
		table.insert(questIDs, quest.questID)
	end

	return questIDs
end

---@param recency QuestRecency
---@param quests QuestSource
function QuestArrivals.Start(recency, quests)
	recency:Adopt(ReadLogIDs(quests))

	local listener = CreateFrame("Frame")

	listener:RegisterEvent("QUEST_ACCEPTED")
	listener:SetScript("OnEvent", function(_, _, questID)
		recency:Record(questID)
	end)
end

Addon.QuestArrivals = QuestArrivals
