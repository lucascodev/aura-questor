local _, Addon = ...

local COOLDOWN_SECONDS = 1

---@class SoundPlayer
---@field private isLocked boolean
local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

---@return SoundPlayer
function SoundPlayer.New()
	return setmetatable({ isLocked = false }, SoundPlayer)
end

---@param id string
---@param channel string
function SoundPlayer:Play(id, channel)
	if self.isLocked then
		return
	end

	self.isLocked = true
	Addon.SoundLibrary.Play(id, channel)

	C_Timer.After(COOLDOWN_SECONDS, function()
		self.isLocked = false
	end)
end

Addon.SoundPlayer = SoundPlayer
