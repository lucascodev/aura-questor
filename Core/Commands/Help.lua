local _, Addon = ...

--- Lists what the player can type.
---
--- Key bindings are not repeated here: the game's own binding screen already
--- shows them, with whatever keys the player actually chose.
---@class HelpCommand
---@field private logger Logger
---@field private commands { command: string, description: string }[]
local HelpCommand = {}
HelpCommand.__index = HelpCommand

---@param logger Logger
---@param commands { command: string, description: string }[]
---@return HelpCommand
function HelpCommand.New(logger, commands)
	return setmetatable({ logger = logger, commands = commands }, HelpCommand)
end

function HelpCommand:Run()
	for _, entry in ipairs(self.commands) do
		self.logger:Info(("%s - %s"):format(entry.command, entry.description))
	end
end

Addon.HelpCommand = HelpCommand
