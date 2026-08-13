local _, Addon = ...

--- Reads a recipe's reagents as progress lines.
---
--- Only required slots count: optional and finishing reagents are choices the
--- player makes at the forge, not something to gather towards.
---@class ReagentReader
local ReagentReader = {}

---@param reagentSlotSchematic table
---@return string?
local function ReadName(reagentSlotSchematic)
	local reagent = reagentSlotSchematic.reagents[1]

	if ProfessionsUtil.IsReagentSlotBasicRequired(reagentSlotSchematic) then
		if reagent.itemID then
			-- Nil while the item is still uncached; the next bag update brings
			-- the line back with a name.
			return Item:CreateFromItemID(reagent.itemID):GetItemName()
		end

		if reagent.currencyID then
			local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)

			return currencyInfo and currencyInfo.name
		end

		return nil
	end

	if ProfessionsUtil.IsReagentSlotModifyingRequired(reagentSlotSchematic) then
		return reagentSlotSchematic.slotInfo and reagentSlotSchematic.slotInfo.slotText
	end

	return nil
end

---@param reagentSlotSchematic table
---@param name string
---@return TrackerObjective
local function ReadObjective(reagentSlotSchematic, name)
	local reagent = reagentSlotSchematic.reagents[1]

	-- How much a variable-quantity reagent needs depends on choices made in the
	-- crafting form, and nothing here remembers those. The range is the honest
	-- answer; a count would be invented.
	if reagentSlotSchematic:IsVariableQuantityReagent(reagent) then
		local minimum, maximum = reagentSlotSchematic:GetVariableQuantityRange(reagent)
		local range = PROFESSIONS_TRACKER_REAGENT_RANGE_FORMAT:format(minimum, maximum)

		return {
			text = PROFESSIONS_TRACKER_REAGENT_FORMAT:format(range, name),
			isComplete = false,
		}
	end

	local required = reagentSlotSchematic:GetQuantityRequired(reagent)
	local owned = ProfessionsUtil.AccumulateReagentsInPossession(reagentSlotSchematic.reagents)
	local count = PROFESSIONS_TRACKER_REAGENT_COUNT_FORMAT:format(owned, required)

	return {
		text = PROFESSIONS_TRACKER_REAGENT_FORMAT:format(count, name),
		isComplete = owned >= required,
	}
end

---@param schematic table
---@return TrackerObjective[]
function ReagentReader.Read(schematic)
	local objectives = {}

	for _, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics or {}) do
		if ProfessionsUtil.IsReagentSlotRequired(reagentSlotSchematic) then
			local name = ReadName(reagentSlotSchematic)

			if name then
				local objective = ReadObjective(reagentSlotSchematic, name)

				-- A modifying slot gates what the rest of the craft can even be,
				-- so it reads before the plain ingredients.
				if ProfessionsUtil.IsReagentSlotModifyingRequired(reagentSlotSchematic) then
					table.insert(objectives, 1, objective)
				else
					table.insert(objectives, objective)
				end
			end
		end
	end

	return objectives
end

Addon.ReagentReader = ReagentReader
