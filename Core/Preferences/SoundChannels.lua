local _, Addon = ...
local L = Addon.L

---@type PreferenceChoice[]
local SoundChannels = {
	{ id = "Master", label = L.CHANNEL_MASTER },
	{ id = "SFX", label = L.CHANNEL_SFX },
	{ id = "Music", label = L.CHANNEL_MUSIC },
	{ id = "Ambience", label = L.CHANNEL_AMBIENCE },
	{ id = "Dialog", label = L.CHANNEL_DIALOG },
}

Addon.SoundChannels = SoundChannels
