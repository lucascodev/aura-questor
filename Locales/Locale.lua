local _, Addon = ...

local DEFAULT_LOCALE = "enUS"

--- A missing key answers with its own name rather than nil, so a translation
--- that was never written shows up as readable text instead of erroring out
--- somewhere far from the cause.
local L = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})

Addon.L = L

--- enUS always applies and is the floor every other locale is written over, so
--- a partial translation falls back phrase by phrase instead of all at once.
---@param locale string
---@param entries table<string, string>
function Addon.RegisterLocale(locale, entries)
	if locale ~= DEFAULT_LOCALE and locale ~= GetLocale() then
		return
	end

	for key, text in pairs(entries) do
		L[key] = text
	end
end
