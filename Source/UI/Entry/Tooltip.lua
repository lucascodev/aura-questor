local _, Addon = ...

local FULL_ALPHA = 1
local WRAP = true
local WHITE = { 1, 1, 1 }
local WIDGET_PADDING = 10

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

--- The game's own rewards block, without the item tooltip it can embed: that
--- one measures itself with values the client keeps secret from an addon, and
--- doing the arithmetic on them errors inside the game. Without it the rewards
--- still come out named, coloured and with their icons.
local REWARDS_STYLE = {
	headerText = QUEST_REWARDS,
	headerColor = NORMAL_FONT_COLOR,
	prefixBlankLineCount = 1,
	postHeaderBlankLineCount = 0,
	wrapHeaderText = true,
	fullItemDescription = false,
}

--- Sets whose drawing has already failed once. The game fills a POI's widgets
--- while its map is up, and away from it some arrive without the fields its own
--- drawing code reads, which errors inside the game. Nothing here can complete
--- that data, and an error the player sees on every hover is worse than the
--- missing details, so a set that fails is dropped for the session.
local brokenWidgetSets = {}

--- The set the map draws in the point's tooltip, with items and rewards that
--- have no place inside a block.
---@param widgetSetID number
local function AddWidgetSet(widgetSetID)
	if brokenWidgetSets[widgetSetID] then
		return
	end

	local wasDrawn = pcall(GameTooltip_AddWidgetSet, GameTooltip, widgetSetID, WIDGET_PADDING)

	if not wasDrawn then
		brokenWidgetSets[widgetSetID] = true
	end
end

--- The side with room for it. A rewards block carries the whole item tooltip,
--- so it can be taller and wider than the tracker itself, and the tracker can
--- be dragged to either edge of any screen.
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

	-- The game's own rewards block, so currencies, reputation and the war mode
	-- bonus come out as they do on the map. A world quest carries its rewards
	-- outside the quest log, and they arrive on request.
	if entry.rewardsQuestID then
		if HaveQuestRewardData(entry.rewardsQuestID) then
			GameTooltip_AddQuestRewardsToTooltip(GameTooltip, entry.rewardsQuestID, REWARDS_STYLE)
		else
			C_TaskQuest.RequestPreloadRewardData(entry.rewardsQuestID)
		end
	end

	if entry.tooltipWidgetSetID then
		AddWidgetSet(entry.tooltipWidgetSetID)
	end

	GameTooltip:Show()
end

Addon.EntryTooltip = EntryTooltip
