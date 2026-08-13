local _, Addon = ...

local ENTRY_KIND = "achievement"
local TRACKING_TYPE = Enum.ContentTrackingType.Achievement
local SECTION_ORDER = 50

--- SectionProvider for tracked achievements.
---
--- Achievements are tracked through the content tracking system, not the quest
--- log, and their progress lines are criteria rather than objectives.
---@class AchievementSectionProvider : SectionProvider
---@field private hiddenCategories table<number, boolean>
local AchievementSectionProvider = {}
AchievementSectionProvider.__index = AchievementSectionProvider

---@param hiddenCategories table<number, boolean> Persisted; empty means show all.
---@return AchievementSectionProvider
function AchievementSectionProvider.New(hiddenCategories)
	return setmetatable({ hiddenCategories = hiddenCategories }, AchievementSectionProvider)
end

--- Criteria come in two shapes: a sentence, or a bare count with no wording.
--- The count is spelled out here so a progress-bar achievement still reads as
--- something rather than as an empty line.
---@param achievementID number
---@return TrackerObjective[]
local function ReadCriteria(achievementID)
	local objectives = {}

	for index = 1, GetAchievementNumCriteria(achievementID) do
		local text, _, isCompleted, quantity, totalQuantity =
			GetAchievementCriteriaInfo(achievementID, index)

		if (not text or text == "") and totalQuantity and totalQuantity > 0 then
			text = ("%d/%d"):format(quantity or 0, totalQuantity)
		end

		if text and text ~= "" then
			table.insert(objectives, { text = text, isComplete = isCompleted })
		end
	end

	return objectives
end

--- Asks the tracking system first, since that is where the achievement came
--- from, and only then the achievement API, whose data is not always loaded
--- and answers with an empty name when it is not.
---@param achievementID number
---@return string?
local function ReadName(achievementID)
	local name = C_ContentTracking.GetTitle(TRACKING_TYPE, achievementID)

	if name and name ~= "" then
		return name
	end

	local _, fallback = GetAchievementInfo(achievementID)

	if fallback and fallback ~= "" then
		return fallback
	end

	return nil
end

---@param achievementID number
---@return TrackerEntry?
local function ReadEntry(achievementID)
	local name = ReadName(achievementID)
	if not name then
		return nil
	end

	local _, _, _, isCompleted = GetAchievementInfo(achievementID)
	local objectives = ReadCriteria(achievementID)

	-- Criteria come from the achievement system, which may have nothing loaded.
	-- The tracking system always has at least a line describing the target.
	if #objectives == 0 then
		local objectiveText = C_ContentTracking.GetObjectiveText(TRACKING_TYPE, achievementID)

		if objectiveText and objectiveText ~= "" then
			objectives = { { text = objectiveText, isComplete = false } }
		end
	end

	return {
		id = achievementID,
		kind = ENTRY_KIND,
		title = name,
		objectives = objectives,
		isComplete = isCompleted,
		canFindGroup = false,
		-- Nothing to click: an achievement has no place on the map.
		pinStyle = "none",
	}
end

---@return TrackerSection[]
function AchievementSectionProvider:Collect()
	local entries = {}
	local trackedIDs = C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
	local parents = Addon.AchievementCategoryReader.ReadParents()

	for _, achievementID in ipairs(trackedIDs) do
		local categoryID = Addon.AchievementCategoryReader.TopLevelOf(parents, achievementID)

		if not categoryID or not self.hiddenCategories[categoryID] then
			local entry = ReadEntry(achievementID)
			if entry then
				table.insert(entries, entry)
			end
		end
	end

	return {
		{
			id = "achievements",
			title = TRACKER_HEADER_ACHIEVEMENTS,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.AchievementSectionProvider = AchievementSectionProvider
