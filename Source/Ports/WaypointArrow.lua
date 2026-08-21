---@meta

--- Where the arrow should point. Without x/y the target exists but has no
--- position yet, and WaypointSync decides what to do about it.
---@class WaypointTarget
---@field id number
---@field kind string
---@field uiMapID number?
---@field x number? Normalizado 0-1.
---@field y number? Normalizado 0-1.
---@field title string?

--- A navigation arrow from another addon.
---@class WaypointArrow
---@field SetWaypoint fun(self: WaypointArrow, target: WaypointTarget)
---@field Clear fun(self: WaypointArrow)
