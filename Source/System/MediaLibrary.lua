local _, Addon = ...

local FONT_MEDIA = "font"
local BACKGROUND_MEDIA = "background"
local BORDER_MEDIA = "border"
local STATUS_BAR_MEDIA = "statusbar"
local SOUND_MEDIA = "sound"

local SOLID_NAME = "Solid"
local SOLID_TEXTURE = [[Interface\Buttons\WHITE8X8]]

local NO_TEXTURE = ""

--- The shared media pool, where every addon that registers a font, a background
--- or a border puts it.
---@class MediaLibrary
local MediaLibrary = {}

---@return table
local function Media()
	return LibStub("LibSharedMedia-3.0")
end

---@param mediaType string
---@return PreferenceChoice[]
local function ChoicesFor(mediaType)
	local choices = {}

	for _, name in ipairs(Media():List(mediaType)) do
		table.insert(choices, { id = name, label = name })
	end

	return choices
end

---@param mediaType string
---@param name string
---@return string
local function PathFor(mediaType, name)
	local media = Media()

	return media:Fetch(mediaType, name) or media:Fetch(mediaType, media:GetDefault(mediaType))
end

---@param mediaType string
---@param name string
---@return string?
local function TexturePathFor(mediaType, name)
	local path = PathFor(mediaType, name)

	if path == NO_TEXTURE then
		return nil
	end

	return path
end

--- Called once at startup, before anything reads a list.
function MediaLibrary.RegisterOwnMedia()
	Media():Register(BORDER_MEDIA, SOLID_NAME, SOLID_TEXTURE)
	Media():Register(FONT_MEDIA, "Inter", [[Interface\AddOns\AuraQuestor\Media\Fonts\Inter-Regular.ttf]])
	Media():Register(FONT_MEDIA, "Inter SemiBold", [[Interface\AddOns\AuraQuestor\Media\Fonts\Inter-SemiBold.ttf]])
	Media():Register(FONT_MEDIA, "JetBrains Mono", [[Interface\AddOns\AuraQuestor\Media\Fonts\JetBrainsMono-Regular.ttf]])
end

---@return PreferenceChoice[]
function MediaLibrary.FontChoices()
	return ChoicesFor(FONT_MEDIA)
end

---@return PreferenceChoice[]
function MediaLibrary.BackgroundChoices()
	return ChoicesFor(BACKGROUND_MEDIA)
end

---@return PreferenceChoice[]
function MediaLibrary.BorderChoices()
	return ChoicesFor(BORDER_MEDIA)
end

---@return PreferenceChoice[]
function MediaLibrary.ProgressBarChoices()
	return ChoicesFor(STATUS_BAR_MEDIA)
end

---@param name string
---@return string
function MediaLibrary.ProgressBarPath(name)
	return PathFor(STATUS_BAR_MEDIA, name)
end

---@return PreferenceChoice[]
function MediaLibrary.SoundChoices()
	return ChoicesFor(SOUND_MEDIA)
end

---@param name string
---@return string?
function MediaLibrary.SoundPath(name)
	return Media():Fetch(SOUND_MEDIA, name)
end

---@param name string
---@return string
function MediaLibrary.FontPath(name)
	return PathFor(FONT_MEDIA, name)
end

---@param name string
---@return string?
function MediaLibrary.BackgroundPath(name)
	return TexturePathFor(BACKGROUND_MEDIA, name)
end

---@param name string
---@return string?
function MediaLibrary.BorderPath(name)
	return TexturePathFor(BORDER_MEDIA, name)
end

Addon.MediaLibrary = MediaLibrary
