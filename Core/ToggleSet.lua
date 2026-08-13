local _, Addon = ...

--- A set that only ever holds what differs from the default, so switching
--- something back on drops its key instead of storing false.
---@class ToggleSet
local ToggleSet = {}

---@param set table<string|number, boolean>
---@param key string|number
function ToggleSet.Toggle(set, key)
	if set[key] then
		set[key] = nil
		return
	end

	set[key] = true
end

---@param set table<string|number, boolean>
function ToggleSet.Clear(set)
	for key in pairs(set) do
		set[key] = nil
	end
end

Addon.ToggleSet = ToggleSet
