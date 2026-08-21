local _, Addon = ...

local ROW_HEIGHT = 24
local ROW_GAP = 2
local MOVE_BUTTON_SIZE = 20
local MOVE_BUTTON_GAP = 4
local POSITION_WIDTH = 22
local RESET_TOP_GAP = 10

--- The same strings the tracker draws in its own headers, so the list in the
--- options reads exactly like the list in the game, already translated by the
--- client. A global missing on some client falls back to the section id, which
--- is ugly but never blank.
local SECTION_LABELS = {
	scenario = "TRACKER_HEADER_SCENARIO",
	campaign = "TRACKER_HEADER_CAMPAIGN_QUESTS",
	quests = "TRACKER_HEADER_QUESTS",
	worldQuests = "TRACKER_HEADER_WORLD_QUESTS",
	events = "EVENTS_LABEL",
	bonus = "TRACKER_HEADER_BONUS_OBJECTIVES",
	achievements = "TRACKER_HEADER_ACHIEVEMENTS",
	recipes = "PROFESSIONS_TRACKER_HEADER_PROFESSION",
	monthlyActivities = "TRACKER_HEADER_MONTHLY_ACTIVITIES",
	collectables = "ADVENTURE_TRACKING_MODULE_HEADER_TEXT",
	initiativeTasks = "TRACKER_HEADER_INITIATIVE_TASKS",
}

---@param id string
---@return string
local function LabelFor(id)
	local global = SECTION_LABELS[id]

	return global and _G[global] or id
end

---@class SectionOrderCard
local SectionOrderCard = {}

--- Exposed for the test that demands a label per section. Without it, adding a
--- section and forgetting the label would pass in silence, and the options list
--- would show the raw id.
SectionOrderCard.Labels = SECTION_LABELS

---@param parent table
---@param direction "up"|"down"
---@param run fun()
---@return table
local function MoveButton(parent, direction, run)
	local isUp = direction == "up"
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(MOVE_BUTTON_SIZE, MOVE_BUTTON_SIZE)
	button:SetNormalTexture(
		isUp and [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]]
			or [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]]
	)
	button:SetPushedTexture(
		isUp and [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]]
			or [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]]
	)
	button:SetDisabledTexture(
		isUp and [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]]
			or [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]]
	)
	button:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")
	button:SetScript("OnClick", run)

	return button
end

--- The reorder list, one row per section.
---
--- Built once and repainted on every change: `SectionOrder` fixes how many rows
--- can ever exist, so there is nothing to pool. The rows stay where they are
--- and the labels move between them, which is why a press never loses track of
--- what it is moving: each row reads its section id back on every repaint.
---
--- Matches the `build` contract in `Options/Components/Page.lua`, so the cell is
--- still declared with a preference key and the page's defaults button restores
--- it along with everything else on the page.
---@param parent table
---@param width number
---@param options { get: fun(): string, set: fun(value: string) }
---@return table
function SectionOrderCard.Cell(parent, width, options)
	local Theme = Addon.OptionsTheme
	local Fonts = Addon.OptionsFonts
	local Arrangement = Addon.SectionArrangement

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(width)

	---@return string[]
	local function Current()
		return Arrangement.Sequence(Addon.SectionOrder, Arrangement.Parse(options.get()))
	end

	---@param ids string[]
	local function Store(ids)
		options.set(Arrangement.Serialize(ids))
	end

	local hint = frame:CreateFontString(nil, "ARTWORK")
	hint:SetFontObject(Fonts.HINT)
	hint:SetPoint("TOPLEFT")
	hint:SetWidth(width)
	hint:SetJustifyH("LEFT")
	hint:SetText(Addon.L.SECTION_ORDER_HINT)
	hint:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)

	local top = hint:GetStringHeight() + Theme.ROW_GAP
	local rows = {}

	---@param row table
	---@param delta number
	local function Nudge(row, delta)
		local moved, changed = Arrangement.Move(Current(), row.sectionID, delta)

		if changed then
			Store(moved)
			frame:Refresh()
		end
	end

	for index = 1, #Arrangement.Defaults(Addon.SectionOrder) do
		local row = CreateFrame("Frame", nil, frame)
		row:SetSize(width, ROW_HEIGHT)
		row:SetPoint("TOPLEFT", 0, -(top + (index - 1) * (ROW_HEIGHT + ROW_GAP)))

		local position = row:CreateFontString(nil, "ARTWORK")
		position:SetFontObject(Fonts.MONO)
		position:SetPoint("LEFT")
		position:SetWidth(POSITION_WIDTH)
		position:SetJustifyH("RIGHT")
		position:SetText(index)
		position:SetTextColor(
			Theme.FAINT_COLOR.red,
			Theme.FAINT_COLOR.green,
			Theme.FAINT_COLOR.blue
		)

		local label = row:CreateFontString(nil, "ARTWORK")
		label:SetFontObject(Fonts.LABEL)
		label:SetPoint("LEFT", POSITION_WIDTH + Theme.ROW_GAP, 0)
		label:SetJustifyH("LEFT")
		label:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

		row.label = label

		row.down = MoveButton(row, "down", function()
			Nudge(row, 1)
		end)
		row.down:SetPoint("RIGHT")

		row.up = MoveButton(row, "up", function()
			Nudge(row, -1)
		end)
		row.up:SetPoint("RIGHT", row.down, "LEFT", -MOVE_BUTTON_GAP, 0)

		rows[index] = row
	end

	local listBottom = top + #rows * (ROW_HEIGHT + ROW_GAP)

	local reset = Addon.OptionsControls.Button(frame, {
		label = Addon.L.SECTION_ORDER_RESET,
		run = function()
			options.set("")
			frame:Refresh()
		end,
	})
	reset:SetPoint("TOPLEFT", 0, -(listBottom + RESET_TOP_GAP))

	frame:SetHeight(listBottom + RESET_TOP_GAP + reset:GetHeight())

	function frame:Refresh()
		local sequence = Current()

		for index, row in ipairs(rows) do
			local id = sequence[index]

			row.sectionID = id
			row.label:SetText(LabelFor(id))
			row.up:SetEnabled(index > 1)
			row.down:SetEnabled(index < #sequence)
		end

		reset:SetEnabled(not Arrangement.IsDefault(Addon.SectionOrder, sequence))
	end

	frame:Refresh()

	return frame
end

Addon.SectionOrderCard = SectionOrderCard
