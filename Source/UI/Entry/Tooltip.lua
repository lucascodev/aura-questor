local _, Addon = ...

local FULL_ALPHA = 1
local WRAP = true
local WHITE = { 1, 1, 1 }

local GROUP_COLOR = { red = 0.45, green = 0.65, blue = 0.9 }
local OBJECTIVE_COLOR = { red = 0.82, green = 0.82, blue = 0.82 }
local OBJECTIVE_COMPLETE_COLOR = { red = 0.55, green = 0.55, blue = 0.55 }

--- What hovering and right-clicking an entry shows.
---@class EntryTooltip
local EntryTooltip = {}

--- The actions decide what belongs in the menu, so an entry that supports
--- nothing gets no menu at all rather than one full of dead options.
---@param actions EntryActions
---@param entry TrackerEntry
---@param owner table
function EntryTooltip.ShowMenu(actions, entry, owner)
	local items = actions:MenuItems(entry)
	if #items == 0 then
		return
	end

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:CreateTitle(entry.title)

		for _, item in ipairs(items) do
			rootDescription:CreateButton(item.label, item.run)
		end
	end)
end

--- The rewards block the map shows, as plain lines. The reader explains why the
--- game's own block is never called here. A world quest carries its rewards
--- outside the quest log, and they arrive on request.
---@param questID number
local function AddRewardLines(questID)
	if not HaveQuestRewardData(questID) then
		C_TaskQuest.RequestPreloadRewardData(questID)

		return
	end

	local lines = Addon.QuestRewardReader.Lines(questID)

	if #lines == 0 then
		return
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(QUEST_REWARDS, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, WRAP)

	for _, line in ipairs(lines) do
		if line.color then
			GameTooltip:AddLine(line.text, line.color.red, line.color.green, line.color.blue)
		else
			GameTooltip:AddLine(line.text)
		end
	end
end

--- What the map shows under the point, as plain lines. The reader explains why
--- the game's widget frames are never drawn here.
---@param widgetSetID number
local function AddWidgetLines(widgetSetID)
	local lines = Addon.WidgetTextReader.Lines(widgetSetID)

	if #lines == 0 then
		return
	end

	GameTooltip:AddLine(" ")

	for _, line in ipairs(lines) do
		GameTooltip:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, WRAP)
	end
end

--- The side with room for it. With a briefing and a list of rewards the tooltip
--- can be wider than the tracker itself, and the tracker can be dragged to
--- either edge of any screen.
---@param owner table
---@return string
local function AnchorFor(owner)
	local left = owner:GetLeft()

	if left and left < UIParent:GetWidth() / 2 then
		return "ANCHOR_RIGHT"
	end

	return "ANCHOR_LEFT"
end

--- The tracker shows a line per objective; the tooltip is where the briefing
--- fits.
---@param actions EntryActions
---@param entry TrackerEntry
---@param owner table
function EntryTooltip.Show(actions, entry, owner)
	local title = Addon.EntryText.TITLE_COLOR

	GameTooltip:SetOwner(owner, AnchorFor(owner))

	-- What is left over after choosing the side: a tall block still has to stay
	-- on screen.
	GameTooltip:SetClampedToScreen(true)

	-- SetText takes an alpha before the wrap flag, unlike AddLine. Passing the
	-- flag straight after the colour lands it in the alpha slot and errors.
	GameTooltip:SetText(entry.title, title.red, title.green, title.blue, FULL_ALPHA, WRAP)

	if entry.groupName then
		GameTooltip:AddLine(entry.groupName, GROUP_COLOR.red, GROUP_COLOR.green, GROUP_COLOR.blue)
	end

	local description = actions:Describe(entry)

	if description and description ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(description, WHITE[1], WHITE[2], WHITE[3], WRAP)
	end

	if #entry.objectives > 0 then
		GameTooltip:AddLine(" ")

		for _, objective in ipairs(entry.objectives) do
			local color = objective.isComplete and OBJECTIVE_COMPLETE_COLOR or OBJECTIVE_COLOR
			GameTooltip:AddLine("- " .. objective.text, color.red, color.green, color.blue, WRAP)
		end
	end

	if entry.rewardsQuestID then
		AddRewardLines(entry.rewardsQuestID)
	end

	if entry.tooltipWidgetSetID then
		AddWidgetLines(entry.tooltipWidgetSetID)
	end

	GameTooltip:Show()
end

Addon.EntryTooltip = EntryTooltip
