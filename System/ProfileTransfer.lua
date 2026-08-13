local _, Addon = ...
local L = Addon.L

local DECODE_FAILURE = Addon.L.PROFILE_DECODE_FAILURE
local DECOMPRESS_FAILURE = Addon.L.PROFILE_DECOMPRESS_FAILURE
local SHAPE_FAILURE = Addon.L.PROFILE_SHAPE_FAILURE

--- Turns a profile into text and back.
---
--- Three steps, each undoing the one before on the way in: serialise the table,
--- compress it, then encode to characters safe to paste. Skipping the encoding
--- would produce bytes a chat box or a text editor would mangle.
---@class ProfileTransfer
local ProfileTransfer = {}

---@return table
local function Serializer()
	return LibStub("LibSerialize")
end

---@return table
local function Compressor()
	return LibStub("LibDeflate")
end

---@param profile table
---@return string
function ProfileTransfer.Export(profile)
	local serialized = Serializer():Serialize(profile)
	local compressed = Compressor():CompressDeflate(serialized)

	return Compressor():EncodeForPrint(compressed)
end

--- Every step is checked because the input is whatever the player pasted, and a
--- wrong paste is the normal case rather than an exception.
---@param text string
---@return table? profile, string? failure
function ProfileTransfer.Import(text)
	local decoded = Compressor():DecodeForPrint(text)
	if not decoded then
		return nil, DECODE_FAILURE
	end

	local decompressed = Compressor():DecompressDeflate(decoded)
	if not decompressed then
		return nil, DECOMPRESS_FAILURE
	end

	local isValid, profile = Serializer():Deserialize(decompressed)
	if not isValid or type(profile) ~= "table" then
		return nil, SHAPE_FAILURE
	end

	return profile, nil
end

Addon.ProfileTransfer = ProfileTransfer
