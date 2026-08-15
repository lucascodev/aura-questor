local _, Addon = ...

local TICK_SECONDS = 1

--- Drives a refresh once a second while a Mythic+ run is going. A scenario
--- clock does not need it: the game keeps the embedded widget alive on its own.
---
--- The tracker is otherwise event-driven, and a clock has no event: nothing
--- fires when a second passes. This is the one place that needs a ticker, and it
--- only exists while there is a run to time, a permanent one-second refresh
--- would cost the frame budget all day for a number nobody is reading.
---@class ChallengeTimer
---@field private onTick fun()
---@field private ticker table?
local ChallengeTimer = {}
ChallengeTimer.__index = ChallengeTimer

---@param onTick fun()
---@return ChallengeTimer
function ChallengeTimer.New(onTick)
	return setmetatable({ onTick = onTick }, ChallengeTimer)
end

---@private
function ChallengeTimer:Sync()
	local isRunning = C_ChallengeMode.GetActiveChallengeMapID() ~= nil

	if isRunning and not self.ticker then
		self.ticker = C_Timer.NewTicker(TICK_SECONDS, self.onTick)
		return
	end

	if not isRunning and self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
end

function ChallengeTimer:Start()
	local listener = CreateFrame("Frame")

	listener:RegisterEvent("CHALLENGE_MODE_START")
	listener:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	listener:RegisterEvent("CHALLENGE_MODE_RESET")
	-- Also on arrival: reloading inside a running key has no start event left.
	listener:RegisterEvent("PLAYER_ENTERING_WORLD")

	listener:SetScript("OnEvent", function()
		self:Sync()
	end)

	self:Sync()
end

Addon.ChallengeTimer = ChallengeTimer
