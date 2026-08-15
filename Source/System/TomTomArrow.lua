local _, Addon = ...

--- WaypointArrow sobre o TomTom.
---
--- O TomTom é um global puro que só existe depois do carregamento dele, então a
--- presença é reavaliada a cada chamada em vez de decidida uma vez. Sem ele,
--- todo método vira no-op.
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

--- A versão pela ficha do addon, que existe mesmo com ele desativado: separa
--- "instalado mas desligado" de "não existe no disco".
---@return string?
function TomTomArrow.InstalledVersion()
	return C_AddOns.GetAddOnMetadata("TomTom", "Version")
end

---@param fromTitle string Aparece no tooltip do waypoint como origem.
---@return TomTomArrow
function TomTomArrow.New(fromTitle)
	return setmetatable({ fromTitle = fromTitle }, TomTomArrow)
end

--- O TomTom pode ter removido o waypoint sozinho, pela distância de chegada,
--- então a referência é validada antes de qualquer remoção.
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
