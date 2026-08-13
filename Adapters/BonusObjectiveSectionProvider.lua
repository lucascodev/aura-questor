local _, Addon = ...

local Keys = Addon.PreferenceKeys

local ENTRY_KIND = "bonus"
local SECTION_ORDER = 40

--- What the game draws inside a bonus objective's pin.
local STAR_ATLAS = "Bonus-Objective-Star"

--- SectionProvider for bonus objectives.
---
--- Bonus objectives are task quests, and so are world quests, so the two have
--- to be told apart. The test used here is the one Blizzard's own bonus tracker
--- uses: a trackable task that is not a world quest.
---@class BonusObjectiveSectionProvider : SectionProvider
---@field private preferences Preferences
local BonusObjectiveSectionProvider = {}
BonusObjectiveSectionProvider.__index = BonusObjectiveSectionProvider

---@param preferences Preferences
---@return BonusObjectiveSectionProvider
function BonusObjectiveSectionProvider.New(preferences)
	return setmetatable({ preferences = preferences }, BonusObjectiveSectionProvider)
end

--- Mirrors the two tests Blizzard's own enumeration applies: skip world quests,
--- which own a section, and skip anything already in the regular watch list,
--- which would otherwise be drawn twice.
---@param questID number
---@return boolean
local function IsBonusObjective(questID)
	if QuestUtils_IsQuestWorldQuest(questID) or QuestUtils_IsQuestWatched(questID) then
		return false
	end

	return QuestUtil.IsQuestTrackableTask(questID)
end

--- GetTaskInfo reports proximity twice: isInArea means standing in the task's
--- own area, isOnMap means merely somewhere in its zone. Blizzard uses the
--- strict one, which is why a task from another continent was never meant to be
--- on screen; the loose one turns the section into "what is on offer around
--- here" instead.
---@param questID number
---@param isZoneWide boolean
---@return TrackerEntry?
local function ReadEntry(questID, isZoneWide)
	local isInArea, isOnMap, numObjectives, taskName = GetTaskInfo(questID)
	local isNearby = isInArea or (isZoneWide and isOnMap)

	-- Only nil is disqualifying, never zero. A progress-bar task reports no
	-- discrete objectives, and demanding at least one silently threw away
	-- exactly the kind that shows a percentage.
	if not isNearby or not numObjectives then
		return nil
	end

	-- A nameless task has nothing to head its block with, so it is left out
	-- rather than drawn as a blank line.
	if not taskName or taskName == "" then
		return nil
	end

	return {
		id = questID,
		kind = ENTRY_KIND,
		title = taskName,
		objectives = Addon.QuestObjectiveReader.Read(questID),
		isComplete = C_QuestLog.IsComplete(questID),
		canFindGroup = false,
		pinStyle = "bonus",
		pinIcon = { atlas = STAR_ATLAS },
		isSuperTrackable = true,
		isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == questID,
	}
end

---@return TrackerSection[]
function BonusObjectiveSectionProvider:Collect()
	local entries = {}
	local isZoneWide = self.preferences:Get(Keys.BONUS_ZONE_WIDE)

	for _, questID in ipairs(GetTasksTable()) do
		if IsBonusObjective(questID) then
			local entry = ReadEntry(questID, isZoneWide)
			if entry then
				table.insert(entries, entry)
			end
		end
	end

	return {
		{
			id = "bonus",
			title = TRACKER_HEADER_BONUS_OBJECTIVES,
			order = SECTION_ORDER,
			entries = entries,
		},
	}
end

Addon.BonusObjectiveSectionProvider = BonusObjectiveSectionProvider
