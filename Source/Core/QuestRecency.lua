local _, Addon = ...

--- Which quests arrived last, since the game does not remember.
---
--- There is no API for when a quest was accepted: the log is ordered by zone
--- and says nothing about the past. So arrival is counted here, one number per
--- quest, kept per character and handed to the sorting as a plain field.
---@class QuestRecency
---@field private store table
local QuestRecency = {}
QuestRecency.__index = QuestRecency

---@param store table Survives between sessions, so the order survives with it.
---@return QuestRecency
function QuestRecency.New(store)
	store.arrivals = type(store.arrivals) == "table" and store.arrivals or {}
	store.lastArrival = tonumber(store.lastArrival) or 0

	return setmetatable({ store = store }, QuestRecency)
end

--- Numbers a quest on first sight and never again: rebuilding the list happens
--- constantly, and it may not reshuffle what the player is reading.
---@param questID number
function QuestRecency:Record(questID)
	if self.store.arrivals[questID] then
		return
	end

	self.store.lastArrival = self.store.lastArrival + 1
	self.store.arrivals[questID] = self.store.lastArrival
end

--- Higher means more recent. Nil for a quest never seen, which is every quest
--- of a character that has not logged in since this was added.
---@param questID number
---@return number?
function QuestRecency:Arrival(questID)
	return self.store.arrivals[questID]
end

--- Drops what left the log, so a character does not carry quests turned in
--- expansions ago. The numbers already handed out stay as they are: they only
--- have to be comparable, never contiguous.
---@param arrivals table<number, number>
---@param questIDs number[]
local function Prune(arrivals, questIDs)
	local isActive = {}

	for _, questID in ipairs(questIDs) do
		isActive[questID] = true
	end

	for questID in pairs(arrivals) do
		if not isActive[questID] then
			arrivals[questID] = nil
		end
	end
end

--- Takes the log as it stands: numbers whatever is new and forgets whatever is
--- gone. Called once per session, which is also what gives a character its
--- first ordering, since nothing before this existed to be recorded.
---@param questIDs number[] Everything in the log right now.
function QuestRecency:Adopt(questIDs)
	-- A log that reads empty at login is the client not being ready yet, not a
	-- player without quests. Pruning against it would throw away the whole
	-- history, and there would be nothing to record in exchange.
	if #questIDs == 0 then
		return
	end

	for _, questID in ipairs(questIDs) do
		self:Record(questID)
	end

	Prune(self.store.arrivals, questIDs)
end

Addon.QuestRecency = QuestRecency
