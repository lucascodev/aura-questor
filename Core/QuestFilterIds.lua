local _, Addon = ...

--- Stable identifiers for the filters.
---
--- There is no "off": a filter is something the player does, not a mode they
--- sit in. Nothing is applied until one of these is clicked.
local QuestFilterIds = {
	ALL = "all",
	ZONE = "zone",
	CAMPAIGN = "campaign",
	RECURRING = "recurring",
	INSTANCE = "instance",
	UNFINISHED = "unfinished",
	COMPLETE = "complete",
}

Addon.QuestFilterIds = QuestFilterIds
