---@meta

--- Entry point for player-typed commands.
--- Declared by Core, implemented by Adapters, injected at the composition root.
---@class CommandRegistry
---@field Register fun(self: CommandRegistry, command: string, handler: fun(argument: string))
