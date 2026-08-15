local _, Addon = ...

local Keys = Addon.PreferenceKeys

--- Announces that the addon finished loading, when the player wants it.
--- Depends on the Logger port, never on the chat frame itself.
---@class Startup
---@field private logger Logger
---@field private addonInfo AddonInfo
---@field private preferences Preferences
local Startup = {}
Startup.__index = Startup

---@param logger Logger
---@param addonInfo AddonInfo
---@param preferences Preferences
---@return Startup
function Startup.New(logger, addonInfo, preferences)
	return setmetatable({
		logger = logger,
		addonInfo = addonInfo,
		preferences = preferences,
	}, Startup)
end

function Startup:Run()
	if not self.preferences:Get(Keys.ANNOUNCE_ON_LOAD) then
		return
	end

	self.logger:Info((Addon.L.STARTUP_LOADED):format(
		self.addonInfo.title,
		self.addonInfo.version
	))
end

Addon.Startup = Startup
