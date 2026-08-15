---@meta

--- Output channel for user-facing messages.
--- Declared by Core, implemented by Adapters, injected at the composition root.
---@class Logger
---@field Info fun(self: Logger, message: string)
---@field Warn fun(self: Logger, message: string)
