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
---@field private parked table<table, table>?
local BlizzardTracker = {}
BlizzardTracker.__index = BlizzardTracker

---@return BlizzardTracker
function BlizzardTracker.New()
	return setmetatable({}, BlizzardTracker)
end

--- Refresh fires constantly and this frame is Blizzard's, so nothing is written
--- unless the frame disagrees with the answer. The frame is what gets asked,
--- never a copy kept here: the right side container fades its frames back in
--- with SetAlpha(1) every time UIParent returns, after a cinematic or a
--- vehicle, and a tracker already put away came back until a reload.
---@param isHidden boolean
function BlizzardTracker:SetHidden(isHidden)
	self:ApplyAlpha(isHidden)
	self:ApplyMouse(not isHidden)
	self:ApplyModules(isHidden)
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

--- Out of sight was not enough. An invisible tracker kept laying out its blocks
--- every update, and inside an instance that layout reads aura data the client
--- refuses to hand to code an addon has touched: a player in a dungeon got the
--- error while nothing was even on screen.
---
--- Taking each module off its container ends it at the source. The container
--- only updates the modules on its list, so the layout that reads auras never
--- runs, and the work of drawing a tracker nobody can see stops with it.
---
--- Reversible on purpose: where each module came from is kept here, and putting
--- them back is the same call the game makes itself. Skipped in combat, where
--- the frame is protected, and the refresh that follows finishes the job.
---@private
---@param isHidden boolean
function BlizzardTracker:ApplyModules(isHidden)
	if InCombatLockdown() then
		return
	end

	if isHidden then
		self:ParkModules()
		return
	end

	self:RestoreModules()
end

--- Runs on every refresh instead of once, because the game hands modules back
--- to their containers on its own, and a module that returned would start
--- laying out again.
---@private
function BlizzardTracker:ParkModules()
	local containers = ObjectiveTrackerManager and ObjectiveTrackerManager.containers

	if type(containers) ~= "table" then
		return
	end

	for container in pairs(containers) do
		self:ParkContainer(container)
	end
end

--- The container is asked what it holds, instead of the map of who belongs
--- where: a module handed back by any other route is still on this list, and
--- this list is the one the update walks.
---@private
---@param container table
function BlizzardTracker:ParkContainer(container)
	if type(container) ~= "table" or type(container.RemoveModule) ~= "function" then
		return
	end

	local attached = {}

	for _, module in ipairs(container.modules or {}) do
		table.insert(attached, module)
	end

	for _, module in ipairs(attached) do
		self.parked = self.parked or {}
		self.parked[module] = self.parked[module] or container
		container:RemoveModule(module)
	end
end

---@private
function BlizzardTracker:RestoreModules()
	if not self.parked or not ObjectiveTrackerManager then
		return
	end

	for module, container in pairs(self.parked) do
		ObjectiveTrackerManager:SetModuleContainer(module, container)
	end

	self.parked = nil
end

Addon.BlizzardTracker = BlizzardTracker
