local _, Addon = ...

local Keys = Addon.PreferenceKeys

--- Announces that the addon finished loading, when the player wants it, and
--- that settings saved under the old name were taken over, whether they want
--- it or not: a one-time migration is news even to someone who muted the
--- greeting.
--- Depends on the Logger port, never on the chat frame itself.
---@class Startup
---@field private logger Logger
---@field private addonInfo AddonInfo
---@field private preferences Preferences
---@field private hasAdoptedLegacy boolean
local Startup = {}
Startup.__index = Startup

---@param logger Logger
---@param addonInfo AddonInfo
---@param preferences Preferences
---@param hasAdoptedLegacy boolean
---@return Startup
function Startup.New(logger, addonInfo, preferences, hasAdoptedLegacy)
	return setmetatable({
		logger = logger,
		addonInfo = addonInfo,
		preferences = preferences,
		hasAdoptedLegacy = hasAdoptedLegacy == true,
	}, Startup)
end

function Startup:Run()
	if self.hasAdoptedLegacy then
		self.logger:Info(Addon.L.LEGACY_ADOPTED)
	end

	if not self.preferences:Get(Keys.ANNOUNCE_ON_LOAD) then
		return
	end

	self.logger:Info((Addon.L.STARTUP_LOADED):format(
		self.addonInfo.title,
		self.addonInfo.version
	))
end

Addon.Startup = Startup
