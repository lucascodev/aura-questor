local _, Addon = ...

local SOUND_MEDIA = "sound"
local NONE_ID = "none"
local NONE_LABEL = "Nenhum"

local SHARED_NONE = "None"

local BUILT_IN = {
	{ id = "questComplete", label = "Missão concluída", kit = "UI_AUTO_QUEST_COMPLETE" },
	{ id = "questForward", label = "Objetivo cumprido", kit = "UI_QUEST_ROLLING_FORWARD_01" },
	{ id = "worldQuest", label = "Missão mundial", kit = "UI_WORLDQUEST_START" },
	{ id = "stageEnd", label = "Fim de estágio", kit = "UI_SCENARIO_STAGE_END" },
	{ id = "activity", label = "Atividade concluída", kit = "TRADING_POST_UI_COMPLETING_ACTIVITIES" },
	{ id = "talent", label = "Confirmação", kit = "UI_CLASS_TALENT_APPLY_COMPLETE" },
	{ id = "popup", label = "Aviso", kit = "TUTORIAL_POPUP" },
	{ id = "ping", label = "Ping do mapa", kit = "MAP_PING" },
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
