---@meta

--- What deciding how the tracker looks is resolved against: the shared media
--- pool, and the character the player is on.
---@class AppearanceSources
---@field Font fun(name: string): string
---@field Background fun(name: string): string? Nil when the player chose none.
---@field Border fun(name: string): string? Nil when the player chose none.
---@field ProgressBar fun(name: string): string
---@field ClassColor fun(): TrackerColor
