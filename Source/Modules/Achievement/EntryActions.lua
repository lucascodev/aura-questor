local _, Addon = ...

local WOWHEAD_ACHIEVEMENT = "achievement"

--- EntryActions for tracked achievements.
---@class AchievementEntryActions : EntryActions
local AchievementEntryActions = {}
AchievementEntryActions.__index = AchievementEntryActions

---@return AchievementEntryActions
function AchievementEntryActions.New()
	return setmetatable({}, AchievementEntryActions)
end

---@param entry TrackerEntry
---@param entry TrackerEntry
---@return boolean
function AchievementEntryActions:InsertChatLink(entry)
	if not IsModifiedClick("CHATLINK") or not ChatFrameUtil.GetActiveWindow() then
		return false
	end

	local link = GetAchievementLink(entry.id)

	if not link then
		return false
	end

	ChatFrameUtil.InsertLink(link)

	return true
end

function AchievementEntryActions:OpenDetails(entry)
	Addon.AchievementPanel.OpenTo(entry.id)
end

--- The achievement's own description, for the tooltip.
---@param entry TrackerEntry
---@return string?
function AchievementEntryActions:Describe(entry)
	local _, _, _, _, _, _, _, description = GetAchievementInfo(entry.id)

	if description and description ~= "" then
		return description
	end

	return nil
end

---@param entry TrackerEntry
function AchievementEntryActions:Untrack(entry)
	C_ContentTracking.StopTracking(
		Enum.ContentTrackingType.Achievement,
		entry.id,
		Enum.ContentTrackingStopType.Manual
	)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function AchievementEntryActions:MenuItems(entry)
	return {
		{
			label = OBJECTIVES_VIEW_ACHIEVEMENT,
			run = function()
				self:OpenDetails(entry)
			end,
		},
		{
			label = Addon.L.MENU_WOWHEAD,
			run = function()
				Addon.NamePrompt.Show(
					Addon.L.MENU_WOWHEAD_MESSAGE,
					Addon.WowheadLink.For(WOWHEAD_ACHIEVEMENT, entry.id, GetLocale())
				)
			end,
		},
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}
end

Addon.AchievementEntryActions = AchievementEntryActions
