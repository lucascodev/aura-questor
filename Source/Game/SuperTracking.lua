local _, Addon = ...

--- The arrow that follows one objective at a time.
---
--- Clearing is not a per-entry action: there is a single super-tracked thing in
--- the game, and letting go of it is the same call whatever was being followed.
---@class SuperTracking
local SuperTracking = {}

function SuperTracking.Clear()
	C_SuperTrack.ClearAllSuperTracked()
end

Addon.SuperTracking = SuperTracking
