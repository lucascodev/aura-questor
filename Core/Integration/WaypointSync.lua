local _, Addon = ...

--- Coordenadas normalizadas 0-1: meio milésimo é sub-pixel em qualquer mapa,
--- então variação menor que isso não merece recriar o waypoint.
local TOLERANCE = 0.0005

--- Mantém a seta de navegação apontada para o alvo supervisionado.
---
--- Toda a decisão de reenviar, manter ou limpar mora aqui; quem lê o jogo e
--- quem desenha a seta chegam injetados.
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
		-- O alvo continua o mesmo e a posição ainda não carregou: piscar a seta
		-- agora seria pior do que esperar a resposta chegar.
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
