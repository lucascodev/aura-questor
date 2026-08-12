local _, Addon = ...

--- Announces that the addon finished loading.
--- Depends on the Logger port, never on the chat frame itself.
---@class Startup
---@field private logger Logger
local Startup = {}
Startup.__index = Startup

---@param logger Logger
---@return Startup
function Startup.New(logger)
	return setmetatable({ logger = logger }, Startup)
end

---@param title string
---@param version string
function Startup:Run(title, version)
	self.logger:Info(("%s v%s carregado."):format(title, version))
end

Addon.Startup = Startup
