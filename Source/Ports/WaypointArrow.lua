---@meta

--- Para onde a seta deve apontar. Sem x/y o alvo existe mas ainda não tem
--- posição resolvida, e quem decide o que fazer com isso é o WaypointSync.
---@class WaypointTarget
---@field id number
---@field kind string
---@field uiMapID number?
---@field x number? Normalizado 0-1.
---@field y number? Normalizado 0-1.
---@field title string?

--- Uma seta de navegação de outro addon.
---@class WaypointArrow
---@field SetWaypoint fun(self: WaypointArrow, target: WaypointTarget)
---@field Clear fun(self: WaypointArrow)
