local _, Addon = ...

--- QUEST_LOG_UPDATE fires in bursts, several times for a single quest turn-in.
--- Collapsing a burst into one refresh is what keeps the rebuild off the frame
--- budget.
local REFRESH_DELAY = 0.15

local EVENTS = {
	"QUEST_LOG_UPDATE",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_ACCEPTED",
	"QUEST_REMOVED",
	"ZONE_CHANGED_NEW_AREA",
	"QUEST_WATCH_UPDATE",
	-- Task quest progress arrives here, not through the quest log.
	"TASK_PROGRESS_UPDATE",
	-- CONTENT_TRACKING_UPDATE is the one that actually fires when an achievement
	-- stops being tracked; without it the entry stayed on screen after untracking.
	"CONTENT_TRACKING_UPDATE",
	"TRACKED_ACHIEVEMENT_LIST_CHANGED",
	"TRACKED_ACHIEVEMENT_UPDATE",
	"ACHIEVEMENT_EARNED",
	"EVENT_SCHEDULER_UPDATE",
	"TRACKED_RECIPE_UPDATE",
	-- Reagent counts are inventory, so gathering one has to redraw the line.
	"BAG_UPDATE_DELAYED",
	-- Using a quest item starts its cooldown without touching the quest log;
	-- this is what redraws the sweep on the item button.
	"BAG_UPDATE_COOLDOWN",
	"PERKS_ACTIVITIES_TRACKED_UPDATED",
	"PERKS_ACTIVITIES_TRACKED_LIST_CHANGED",
	"INITIATIVE_TASKS_TRACKED_UPDATED",
	"INITIATIVE_TASKS_TRACKED_LIST_CHANGED",
	"TRACKABLE_INFO_UPDATE",
	-- Redraws the pin so the selected one is the one actually being followed.
	"SUPER_TRACKING_CHANGED",
	"SCENARIO_UPDATE",
	"SCENARIO_CRITERIA_UPDATE",
	"CHALLENGE_MODE_START",
	"CHALLENGE_MODE_COMPLETED",
	"CHALLENGE_MODE_DEATH_COUNT_UPDATED",
	-- Quest item buttons are secure, so they cannot be touched during combat.
	-- Leaving it means rebuilding as soon as it ends.
	"PLAYER_REGEN_ENABLED",
}

--- Turns game events into a single "something changed" signal.
--- Exists so neither the domain nor the frame has to know which events matter.
---@class TrackerEvents
---@field private onChanged fun()
---@field private isScheduled boolean
local TrackerEvents = {}
TrackerEvents.__index = TrackerEvents

---@param onChanged fun()
---@return TrackerEvents
function TrackerEvents.New(onChanged)
	return setmetatable({ onChanged = onChanged, isScheduled = false }, TrackerEvents)
end

---@private
function TrackerEvents:Schedule()
	if self.isScheduled then
		return
	end

	self.isScheduled = true
	C_Timer.After(REFRESH_DELAY, function()
		self.isScheduled = false
		self.onChanged()
	end)
end

function TrackerEvents:Start()
	local listener = CreateFrame("Frame")

	for _, event in ipairs(EVENTS) do
		listener:RegisterEvent(event)
	end

	listener:SetScript("OnEvent", function()
		self:Schedule()
	end)
end

Addon.TrackerEvents = TrackerEvents
