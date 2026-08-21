local _, Addon = ...

local ROW_HEIGHT = 22
local BUTTON_GAP = 8
local UP = -1
local DOWN = 1

--- The names the tracker gives each section, so the options list reads the same
--- as the tracker itself. A section the game has no name for is left out rather
--- than shown by its internal id.
local LABEL_BY_SECTION = {
	scenario = TRACKER_HEADER_SCENARIO,
	campaign = TRACKER_HEADER_CAMPAIGN_QUESTS,
	quests = TRACKER_HEADER_QUESTS,
	worldQuests = TRACKER_HEADER_WORLD_QUESTS,
	events = EVENTS_LABEL,
	bonus = TRACKER_HEADER_BONUS_OBJECTIVES,
	achievements = TRACKER_HEADER_ACHIEVEMENTS,
	recipes = PROFESSIONS_TRACKER_HEADER_PROFESSION,
	monthlyActivities = TRACKER_HEADER_MONTHLY_ACTIVITIES,
	collectables = ADVENTURE_TRACKING_MODULE_HEADER_TEXT,
	initiativeTasks = TRACKER_HEADER_INITIATIVE_TASKS,
}

--- Arranging the sections: one row per section, in the order the tracker draws
--- them, with the picked one moved by the two buttons under the list.
---
--- Moving is a pair of buttons and not a drag: a dragged row inside a scrolling
--- options page fights the page for the mouse.
---@class OptionsSectionList
local OptionsSectionList = {}

---@param commands table
---@return fun(parent: table, width: number): table
function OptionsSectionList.Cell(commands)
	return function(parent, width)
		local Theme = Addon.OptionsTheme
		local Fonts = Addon.OptionsFonts

		local frame = CreateFrame("Frame", nil, parent)
		local rows = {}
		local picked

		local function Paint()
			for index, sectionID in ipairs(commands.sectionOrder()) do
				local row = rows[index]

				row.sectionID = sectionID
				row.text:SetText(LABEL_BY_SECTION[sectionID] or sectionID)
				row.highlight:SetShown(sectionID == picked)
				row:Show()
			end
		end

		for index = 1, #commands.sectionOrder() do
			local row = CreateFrame("Button", nil, frame)
			row:SetHeight(ROW_HEIGHT)
			row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
			row:SetPoint("TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)

			local highlight = row:CreateTexture(nil, "BACKGROUND")
			highlight:SetAllPoints()
			highlight:SetColorTexture(
				Theme.ACCENT_COLOR.red,
				Theme.ACCENT_COLOR.green,
				Theme.ACCENT_COLOR.blue,
				0.25
			)
			highlight:Hide()

			local text = row:CreateFontString(nil, "ARTWORK")
			text:SetFontObject(Fonts.LABEL)
			text:SetPoint("LEFT", 6, 0)
			text:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

			row:SetScript("OnClick", function(owner)
				picked = owner.sectionID
				Paint()
			end)

			row.text = text
			row.highlight = highlight
			rows[index] = row
		end

		local listHeight = #rows * ROW_HEIGHT

		local function Move(step)
			if not picked or not commands.moveSection(picked, step) then
				return
			end

			Paint()
		end

		local up = Addon.OptionsControls.Button(frame, {
			label = Addon.L.PREF_SECTION_ORDER_UP,
			run = function()
				Move(UP)
			end,
		})
		up:SetPoint("TOPLEFT", 0, -(listHeight + BUTTON_GAP))

		local down = Addon.OptionsControls.Button(frame, {
			label = Addon.L.PREF_SECTION_ORDER_DOWN,
			run = function()
				Move(DOWN)
			end,
		})
		down:SetPoint("LEFT", up, "RIGHT", BUTTON_GAP, 0)

		frame:SetSize(width, listHeight + BUTTON_GAP + up:GetHeight())

		function frame:Refresh()
			Paint()
		end

		Paint()

		return frame
	end
end

Addon.OptionsSectionList = OptionsSectionList
