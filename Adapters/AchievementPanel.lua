local _, Addon = ...

--- The achievement panel, which is load-on-demand: it has to be pulled in
--- before anything can be shown or selected inside it. Calling into it first is
--- what broke the first attempt at opening an achievement.
---@class AchievementPanel
local AchievementPanel = {}

function AchievementPanel.Open()
	if not AchievementFrame then
		AchievementFrame_LoadUI()
	end

	if not AchievementFrame:IsShown() then
		AchievementFrame_ToggleAchievementFrame()
	end
end

---@param achievementID number
function AchievementPanel.OpenTo(achievementID)
	AchievementPanel.Open()
	AchievementFrame_SelectAchievement(achievementID)
end

Addon.AchievementPanel = AchievementPanel
