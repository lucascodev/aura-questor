local _, Addon = ...

local VISIBLE_ALPHA = 1
local HIDDEN_ALPHA = 0

--- TrackerVisibility port for the Blizzard objective tracker.
---
--- Alpha and mouse input only. Hide, SetScale and SetPoint are blocked or
--- taint-prone on a frame that owns quest item buttons, that is what broke
--- Carrot Objective Tracker on 12.1. At zero alpha the frame still exists and
--- still updates, so this is reversible with no reload and no side effects.
---@class BlizzardTracker : TrackerVisibility
local BlizzardTracker = {}
BlizzardTracker.__index = BlizzardTracker

---@return BlizzardTracker
function BlizzardTracker.New()
	return setmetatable({}, BlizzardTracker)
end

--- Refresh fires constantly and this frame is Blizzard's: every touch of ours
--- taints it a little more, so nothing is written unless the answer changed.
--- Alpha and mouse remember separately, because combat can let one through and
--- hold the other back.
---@param isHidden boolean
function BlizzardTracker:SetHidden(isHidden)
	if self.isHidden ~= isHidden then
		self.isHidden = isHidden
		ObjectiveTrackerFrame:SetAlpha(isHidden and HIDDEN_ALPHA or VISIBLE_ALPHA)
	end

	-- Taking the mouse away is what stops an invisible tracker from still eating
	-- clicks. Skipped in combat, where the frame is protected; the alpha already
	-- did the visible half of the job, and the refresh that follows combat comes
	-- back here to finish it.
	local wantsMouse = not isHidden

	if self.hasMouse == wantsMouse or InCombatLockdown() then
		return
	end

	self.hasMouse = wantsMouse
	ObjectiveTrackerFrame:EnableMouse(wantsMouse)
end

Addon.BlizzardTracker = BlizzardTracker
