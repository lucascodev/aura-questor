local _, Addon = ...

--- Limits that depend on something measured on the client, which is why they
--- do not fit in the catalog.
---@class PreferenceBounds
local PreferenceBounds = {}

--- The screen sets the ceiling, so a tall monitor reaches its bottom edge. The
--- catalog ceiling becomes the floor, so a short screen never shrinks a saved
--- height, and the value lands on a multiple of the step, otherwise the last
--- point of the control cannot be reached.
---@param preference Preference
---@param available number
---@return number
function PreferenceBounds.Maximum(preference, available)
	local steps = math.floor(available / preference.step)

	return math.max(preference.maximum, steps * preference.step)
end

Addon.PreferenceBounds = PreferenceBounds
