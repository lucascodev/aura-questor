local _, Addon = ...

local ENTRY_KIND = "zoneWidget"

--- The two sets the game's own tracker keeps registered whatever else is going
--- on. The zone publishes into them, and that is how content like a temple
--- offensive shows a timer and a line without being a scenario at all: asking
--- C_Scenario about it answers nothing.
local TOP_WIDGET_SET = 514
local BOTTOM_WIDGET_SET = 252

--- SectionProvider for what the zone itself publishes as widgets.
---@class ZoneWidgetSectionProvider : SectionProvider
local ZoneWidgetSectionProvider = {}
ZoneWidgetSectionProvider.__index = ZoneWidgetSectionProvider

---@return ZoneWidgetSectionProvider
function ZoneWidgetSectionProvider.New()
	return setmetatable({}, ZoneWidgetSectionProvider)
end

--- An empty set would open a hole where its block is, so only a set with
--- something in it becomes an entry.
---@param widgetSetID number
---@return boolean
local function HasWidgets(widgetSetID)
	local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(widgetSetID)

	return widgets ~= nil and #widgets > 0
end

---@param entries TrackerEntry[]
---@param widgetSetID number
local function AddSet(entries, widgetSetID)
	if not HasWidgets(widgetSetID) then
		return
	end

	table.insert(entries, {
		id = widgetSetID,
		kind = ENTRY_KIND,
		title = "",
		objectives = { { text = "", widgetSetID = widgetSetID, isComplete = false } },
		isComplete = false,
		canFindGroup = false,
		isSuperTrackable = false,
		pinStyle = "none",
	})
end

---@return TrackerSection[]
function ZoneWidgetSectionProvider:Collect()
	local entries = {}

	AddSet(entries, TOP_WIDGET_SET)
	AddSet(entries, BOTTOM_WIDGET_SET)

	return {
		{
			id = "zoneWidgets",
			title = TRACKER_HEADER_SCENARIO,
			order = Addon.SectionOrder.zoneWidgets,
			entries = entries,
		},
	}
end

Addon.ZoneWidgetSectionProvider = ZoneWidgetSectionProvider
