local _, Addon = ...

--- A Inter e a JetBrains Mono acompanham o addon, mas não têm glifo CJK: num
--- cliente chinês, japonês ou coreano todo texto delas vira quadrado. O jogo
--- publica em STANDARD_TEXT_FONT a fonte certa do idioma do cliente.
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
