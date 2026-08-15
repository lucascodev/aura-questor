local _, Addon = ...

--- Answers whether the addon is alive, on demand.
--- The load message can be missed; this one is asked for, so it always lands.
---@class StatusCommand
---@field private logger Logger
---@field private addonInfo AddonInfo
local StatusCommand = {}
StatusCommand.__index = StatusCommand

---@param logger Logger
---@param addonInfo AddonInfo
---@return StatusCommand
function StatusCommand.New(logger, addonInfo)
	return setmetatable({ logger = logger, addonInfo = addonInfo }, StatusCommand)
end

function StatusCommand:Run()
	self.logger:Info((Addon.L.STATUS_ACTIVE):format(self.addonInfo.title, self.addonInfo.version))
end

Addon.StatusCommand = StatusCommand
