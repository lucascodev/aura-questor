local _, Addon = ...

--- The address of a quest or achievement on Wowhead, in the language of the
--- client when the site has one.
---
--- Nothing is opened from here: the game has no way to reach a browser, so the
--- address is shown for the player to copy.
---@class WowheadLink
local WowheadLink = {}

local DEFAULT_SUBDOMAIN = "www"

--- The site's own subdomains, which are not the client locale codes.
local SUBDOMAIN_BY_LOCALE = {
	ptBR = "pt",
	esES = "es",
	esMX = "es",
	frFR = "fr",
	deDE = "de",
	itIT = "it",
	ruRU = "ru",
	koKR = "ko",
	zhCN = "cn",
}

---@param kind string "quest" or "achievement".
---@param id number
---@param locale string
---@return string
function WowheadLink.For(kind, id, locale)
	return ("https://%s.wowhead.com/%s=%d"):format(
		SUBDOMAIN_BY_LOCALE[locale] or DEFAULT_SUBDOMAIN,
		kind,
		id
	)
end

Addon.WowheadLink = WowheadLink
