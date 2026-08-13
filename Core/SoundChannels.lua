local _, Addon = ...

---@type PreferenceChoice[]
local SoundChannels = {
	{ id = "Master", label = "Principal" },
	{ id = "SFX", label = "Efeitos sonoros" },
	{ id = "Music", label = "Música" },
	{ id = "Ambience", label = "Ambiente" },
	{ id = "Dialog", label = "Diálogo" },
}

Addon.SoundChannels = SoundChannels
