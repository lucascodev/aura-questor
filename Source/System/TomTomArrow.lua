local _, Addon = ...

--- WaypointArrow sobre o TomTom.
---
--- TomTom is a plain global that only exists after it loads, so its presence is
--- checked on every call instead of decided once. Without it every method here
--- does nothing.
---@class TomTomArrow : WaypointArrow
---@field private fromTitle string
---@field private uid table?
local TomTomArrow = {}
TomTomArrow.__index = TomTomArrow

---@return boolean
function TomTomArrow.IsAvailable()
	return TomTom ~= nil and type(TomTom.AddWaypoint) == "function"
end

---@return string
function TomTomArrow.Version()
	return tostring(TomTom and TomTom.version or "?")
end

--- The version from the addon metadata, which is there even when it is
--- disabled: it tells "installed but off" from "not on disk".
---@return string?
function TomTomArrow.InstalledVersion()
	return C_AddOns.GetAddOnMetadata("TomTom", "Version")
end

---@param fromTitle string Aparece no tooltip do waypoint como origem.
---@return TomTomArrow
function TomTomArrow.New(fromTitle)
	return setmetatable({ fromTitle = fromTitle }, TomTomArrow)
end

--- TomTom may have removed the waypoint on its own once the player arrived, so
--- the reference is checked before removing anything.
---@private
function TomTomArrow:RemoveCurrent()
	if self.uid and TomTom:IsValidWaypoint(self.uid) then
		TomTom:RemoveWaypoint(self.uid)
	end

	self.uid = nil
end

---@param target WaypointTarget
function TomTomArrow:SetWaypoint(target)
	if not TomTomArrow.IsAvailable() then
		return
	end

	self:RemoveCurrent()

	self.uid = TomTom:AddWaypoint(target.uiMapID, target.x, target.y, {
		title = target.title,
		from = self.fromTitle,
		silent = true,
		persistent = false,
		minimap = false,
		world = false,
		crazy = true,
	})
end

function TomTomArrow:Clear()
	if not TomTomArrow.IsAvailable() then
		return
	end

	self:RemoveCurrent()
end

Addon.TomTomArrow = TomTomArrow
