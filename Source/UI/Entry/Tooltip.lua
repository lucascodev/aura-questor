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

--- The tracker shows a line per objective; the tooltip is where the briefing
--- fits. Anchored left so it never covers the tracker it came from.
---@param actions EntryActions
---@param entry TrackerEntry
---@param owner table
function EntryTooltip.Show(actions, entry, owner)
	local title = Addon.EntryText.TITLE_COLOR

	GameTooltip:SetOwner(owner, "ANCHOR_LEFT")

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

	local rewards = actions:Rewards(entry)

	if #rewards > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(REWARDS, title.red, title.green, title.blue)

		for _, reward in ipairs(rewards) do
			GameTooltip:AddLine(reward, WHITE[1], WHITE[2], WHITE[3])
		end
	end

	-- Where this content was made to live: it is the set the map draws in the
	-- point's tooltip, with items and rewards that have no place in a block.
	if entry.tooltipWidgetSetID then
		GameTooltip_AddWidgetSet(GameTooltip, entry.tooltipWidgetSetID, WIDGET_PADDING)
	end

	GameTooltip:Show()
end

Addon.EntryTooltip = EntryTooltip
