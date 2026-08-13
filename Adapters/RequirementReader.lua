local _, Addon = ...

--- Reads a requirement list into objective lines.
---
--- Monthly activities and neighbourhood tasks describe progress the same way —
--- a list of { requirementText, completed } — so the translation lives once.
---@class RequirementReader
local RequirementReader = {}

---@param requirements table[]?
---@return TrackerObjective[]
function RequirementReader.Read(requirements)
	local objectives = {}

	for _, requirement in ipairs(requirements or {}) do
		local text = requirement.requirementText

		if text and text ~= "" then
			-- The game writes "3 / 5"; the tracker has no room for the spaces.
			table.insert(objectives, {
				text = text:gsub(" / ", "/"),
				isComplete = requirement.completed == true,
			})
		end
	end

	return objectives
end

Addon.RequirementReader = RequirementReader
