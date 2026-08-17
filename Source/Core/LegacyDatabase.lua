local _, Addon = ...

--- The addon used to be AuraTrackerQuestor, and the client keys saved
--- variables by addon name: a rename alone would start every player from zero.
--- The old name ships as a bridge addon that only keeps its saved table alive,
--- and the first load under the new name takes that table over.
---
--- Taken over by reference, not copied: each global is serialized on its own at
--- logout, so both files end up with the same content, and from the next
--- session on the two are separate tables anyway. The legacy table is never
--- cleared, so going back to the old version loses nothing.
---@class LegacyDatabase
local LegacyDatabase = {}

---@param current table? The table saved under the new name.
---@param legacy table? The table saved under the old name, if the bridge loaded.
---@return table database
---@return boolean adopted
function LegacyDatabase.Resolve(current, legacy)
	if type(current) == "table" and next(current) ~= nil then
		return current, false
	end

	if type(legacy) == "table" then
		return legacy, true
	end

	return current or {}, false
end

Addon.LegacyDatabase = LegacyDatabase
