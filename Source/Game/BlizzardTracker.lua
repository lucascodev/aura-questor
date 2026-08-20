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
---@field private didHide boolean?
local BlizzardTracker = {}
BlizzardTracker.__index = BlizzardTracker

---@return BlizzardTracker
function BlizzardTracker.New()
	return setmetatable({}, BlizzardTracker)
end

--- Refresh fires constantly and this frame is Blizzard's: every touch of ours
--- taints it a little more, so nothing is written unless the frame disagrees
--- with the answer. The frame is what gets asked, never a copy of the last
--- answer kept here, and that copy is what broke: the right side frame
--- container fades its frames back in with SetAlpha(1) every time UIParent
--- returns, after a cinematic or a vehicle, so a tracker already put away came
--- back on screen and stayed until a reload.
---@param isHidden boolean
function BlizzardTracker:SetHidden(isHidden)
	self:ApplyAlpha(isHidden)
	self:ApplyMouse(not isHidden)
end

--- Hiding is enforced every time, showing back lifts only the zero this addon
--- wrote. The same container also zeroes the tracker under an override action
--- bar, and undoing that one would put it back on screen inside a vehicle.
---@private
---@param isHidden boolean
function BlizzardTracker:ApplyAlpha(isHidden)
	local alpha = ObjectiveTrackerFrame:GetAlpha()

	if isHidden then
		self.didHide = true

		if alpha ~= HIDDEN_ALPHA then
			ObjectiveTrackerFrame:SetAlpha(HIDDEN_ALPHA)
		end

		return
	end

	if self.didHide and alpha == HIDDEN_ALPHA then
		ObjectiveTrackerFrame:SetAlpha(VISIBLE_ALPHA)
	end

	self.didHide = false
end

--- Taking the mouse away is what stops an invisible tracker from still eating
--- clicks. Skipped in combat, where the frame is protected; the alpha already
--- did the visible half of the job, and the refresh that follows combat comes
--- back here to finish it.
---@private
---@param wantsMouse boolean
function BlizzardTracker:ApplyMouse(wantsMouse)
	if InCombatLockdown() or ObjectiveTrackerFrame:IsMouseEnabled() == wantsMouse then
		return
	end

	ObjectiveTrackerFrame:EnableMouse(wantsMouse)
end

Addon.BlizzardTracker = BlizzardTracker
