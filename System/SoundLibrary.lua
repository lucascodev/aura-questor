local _, Addon = ...
local L = Addon.L

local SOUND_MEDIA = "sound"
local NONE_ID = "none"
local NONE_LABEL = Addon.L.SOUND_NONE

local SHARED_NONE = "None"

local BUILT_IN = {
	{ id = "questComplete", label = Addon.L.SOUND_QUEST_COMPLETE, kit = "UI_AUTO_QUEST_COMPLETE" },
	{ id = "questForward", label = Addon.L.SOUND_QUEST_FORWARD, kit = "UI_QUEST_ROLLING_FORWARD_01" },
	{ id = "worldQuest", label = Addon.L.SOUND_WORLD_QUEST, kit = "UI_WORLDQUEST_START" },
	{ id = "stageEnd", label = Addon.L.SOUND_STAGE_END, kit = "UI_SCENARIO_STAGE_END" },
	{ id = "activity", label = Addon.L.SOUND_ACTIVITY, kit = "TRADING_POST_UI_COMPLETING_ACTIVITIES" },
	{ id = "talent", label = Addon.L.SOUND_TALENT, kit = "UI_CLASS_TALENT_APPLY_COMPLETE" },
	{ id = "popup", label = Addon.L.SOUND_POPUP, kit = "TUTORIAL_POPUP" },
	{ id = "ping", label = Addon.L.SOUND_PING, kit = "MAP_PING" },
}

---@class SoundLibrary
local SoundLibrary = {}

---@return table
local function Media()
	return LibStub("LibSharedMedia-3.0")
end

---@param id string
---@return table?
local function FindBuiltIn(id)
	for _, sound in ipairs(BUILT_IN) do
		if sound.id == id then
			return sound
		end
	end

	return nil
end

---@return PreferenceChoice[]
function SoundLibrary.Choices()
	local choices = { { id = NONE_ID, label = NONE_LABEL } }

	for _, sound in ipairs(BUILT_IN) do
		table.insert(choices, { id = sound.id, label = sound.label })
	end

	for _, name in ipairs(Media():List(SOUND_MEDIA)) do
		if name ~= SHARED_NONE then
			table.insert(choices, { id = name, label = name })
		end
	end

	return choices
end

---@param id string
---@param channel string
function SoundLibrary.Play(id, channel)
	if id == NONE_ID then
		return
	end

	local builtIn = FindBuiltIn(id)

	if builtIn then
		PlaySound(SOUNDKIT[builtIn.kit], channel)
		return
	end

	local path = Media():Fetch(SOUND_MEDIA, id)

	if path then
		PlaySoundFile(path, channel)
	end
end

Addon.SoundLibrary = SoundLibrary
