local _, Addon = ...

local TRACKING_TYPE = Enum.ContentTrackingType.Achievement

--- Bulk operations on tracked achievements, which the per-entry actions have no
--- business knowing about.
---@class AchievementTracking
local AchievementTracking = {}

function AchievementTracking.UntrackAll()
	-- Copied out first: StopTracking mutates the list the game hands back.
	local trackedIDs = { unpack(C_ContentTracking.GetTrackedIDs(TRACKING_TYPE) or {}) }

	for _, achievementID in ipairs(trackedIDs) do
		C_ContentTracking.StopTracking(
			TRACKING_TYPE,
			achievementID,
			Enum.ContentTrackingStopType.Manual
		)
	end
end

Addon.AchievementTracking = AchievementTracking
