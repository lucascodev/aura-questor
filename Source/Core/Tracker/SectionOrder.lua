local _, Addon = ...

--- Where each section sits in the tracker, in one place. Reading it is how you
--- learn the order without opening ten providers.
---@type table<string, number>
local SectionOrder = {
	zoneWidgets = 3,
	scenario = 5,
	campaign = 10,
	quests = 20,
	worldQuests = 30,
	events = 35,
	bonus = 40,
	achievements = 50,
	recipes = 60,
	monthlyActivities = 70,
	collectables = 80,
	initiativeTasks = 90,
}

Addon.SectionOrder = SectionOrder
