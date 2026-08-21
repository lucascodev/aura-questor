local _, Addon = ...

--- Coordinates run 0 to 1, and half a thousandth is under a pixel on any map,
--- so a smaller change is not worth recreating the waypoint for.
local TOLERANCE = 0.0005

--- Keeps the navigation arrow pointed at the tracked target. Deciding to
--- resend, keep or clear lives here; reading the game and drawing the arrow
--- arrive from outside.
---@class WaypointSync
---@field private readTarget fun(): WaypointTarget?
---@field private arrow WaypointArrow
---@field private isEnabled fun(): boolean
---@field private lastTarget WaypointTarget?
local WaypointSync = {}
WaypointSync.__index = WaypointSync

---@param readTarget fun(): WaypointTarget?
---@param arrow WaypointArrow
---@param isEnabled fun(): boolean
---@return WaypointSync
function WaypointSync.New(readTarget, arrow, isEnabled)
	return setmetatable({
		readTarget = readTarget,
		arrow = arrow,
		isEnabled = isEnabled,
	}, WaypointSync)
end

---@private
function WaypointSync:Forget()
	if not self.lastTarget then
		return
	end

	self.lastTarget = nil
	self.arrow:Clear()
end

---@param target WaypointTarget
---@param last WaypointTarget
---@return boolean
local function IsSamePlace(target, last)
	if target.id ~= last.id or target.kind ~= last.kind or target.uiMapID ~= last.uiMapID then
		return false
	end

	return math.abs(target.x - last.x) < TOLERANCE and math.abs(target.y - last.y) < TOLERANCE
end

function WaypointSync:Sync()
	if not self.isEnabled() then
		self:Forget()
		return
	end

	local target = self.readTarget()

	if not target then
		self:Forget()
		return
	end

	if not target.x or not target.y then
		-- Same target, position not loaded yet: blinking the arrow now would be
		-- worse than waiting for the answer.
		if not (self.lastTarget and self.lastTarget.id == target.id) then
			self:Forget()
		end

		return
	end

	if self.lastTarget and self.lastTarget.x and IsSamePlace(target, self.lastTarget) then
		return
	end

	self.lastTarget = target
	self.arrow:SetWaypoint(target)
end

Addon.WaypointSync = WaypointSync
