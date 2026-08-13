local _, Addon = ...

--- Applies a filter by rewriting what the tracker watches.
---
--- Filtering is an action, not a mode: nothing here runs on its own. The player
--- clicks a filter, the watch list is rebuilt once, and that is the end of it,
--- which is why there is no "off" to go back to.
---
--- Nothing touches a frame either. The tracker redraws itself from the watch
--- list, which is why filtering survives Blizzard reworking the tracker UI.
---@class QuestFiltering
---@field private source QuestSource
---@field private filters QuestFilter[]
---@field private logger Logger
local QuestFiltering = {}
QuestFiltering.__index = QuestFiltering

---@param source QuestSource
---@param filters QuestFilter[]
---@param logger Logger
---@return QuestFiltering
function QuestFiltering.New(source, filters, logger)
	return setmetatable({ source = source, filters = filters, logger = logger }, QuestFiltering)
end

---@param quests Quest[]
---@param filter QuestFilter
---@return number
local function CountMatching(quests, filter)
	local matching = 0

	for _, quest in ipairs(quests) do
		if filter.matches(quest) then
			matching = matching + 1
		end
	end

	return matching
end

--- How many quests each filter would keep, so the player can see the cost of a
--- choice before making it.
---@return table<string, number>
function QuestFiltering:Counts()
	local quests = self.source:ListAll()
	local counts = {}

	for _, filter in ipairs(self.filters) do
		counts[filter.id] = CountMatching(quests, filter)
	end

	return counts
end

--- The quest log's own headings, with how many quests sit under each, in the
--- order the log lists them.
---@return { name: string, count: number }[]
function QuestFiltering:Groups()
	local groups = {}
	local indexByName = {}

	for _, quest in ipairs(self.source:ListAll()) do
		local name = quest.groupName

		if name then
			local index = indexByName[name]

			if index then
				groups[index].count = groups[index].count + 1
			else
				table.insert(groups, { name = name, count = 1 })
				indexByName[name] = #groups
			end
		end
	end

	return groups
end

---@private
---@param decide fun(quest: Quest): boolean
function QuestFiltering:Rewrite(decide)
	local refusedCount = 0

	for _, quest in ipairs(self.source:ListAll()) do
		if not self.source:SetWatched(quest.questID, decide(quest)) then
			refusedCount = refusedCount + 1
		end
	end

	if refusedCount > 0 then
		self.logger:Warn(("%d missões ficaram de fora: o jogo limita quantas dá para rastrear.")
			:format(refusedCount))
	end
end

---@param filterID string
function QuestFiltering:Apply(filterID)
	for _, filter in ipairs(self.filters) do
		if filter.id == filterID then
			self:Rewrite(filter.matches)
			return
		end
	end

	self.logger:Warn(("Filtro desconhecido: %s."):format(tostring(filterID)))
end

---@param groupName string
function QuestFiltering:ApplyGroup(groupName)
	self:Rewrite(function(quest)
		return quest.groupName == groupName
	end)
end

function QuestFiltering:UntrackAll()
	self:Rewrite(function()
		return false
	end)
end

Addon.QuestFiltering = QuestFiltering
