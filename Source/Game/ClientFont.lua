local _, Addon = ...

--- Inter and JetBrains Mono ship with the addon but have no CJK glyphs: on a
--- Chinese, Japanese or Korean client every character drawn with them turns
--- into a box. The game publishes the right font for the client language in
--- STANDARD_TEXT_FONT.
---@class ClientFont
local ClientFont = {}

local CJK_LOCALES = {
	zhCN = true,
	zhTW = true,
	koKR = true,
}

---@return boolean
function ClientFont.PrefersGameFont()
	return CJK_LOCALES[GetLocale()] == true
end

---@return string
function ClientFont.GamePath()
	return STANDARD_TEXT_FONT
end

Addon.ClientFont = ClientFont
