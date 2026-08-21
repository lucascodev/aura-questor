local _, Addon = ...

local OFFER_POPUP = "OFFER"
local QUEST_KIND = "quest"
local WORLD_QUEST_KIND = "worldQuest"

--- EntryActions for quests, world quests included: both live in the quest log.
---@class QuestEntryActions : EntryActions
---@field private waypoints EntryWaypoints?
local QuestEntryActions = {}
QuestEntryActions.__index = QuestEntryActions

---@param waypoints EntryWaypoints?
---@return QuestEntryActions
function QuestEntryActions.New(waypoints)
	return setmetatable({ waypoints = waypoints }, QuestEntryActions)
end

--- A quest ready to turn in opens its reward window and a pending offer opens
--- the offer, as Blizzard's blocks do; the rest goes to the quest log.
---@param entry TrackerEntry
function QuestEntryActions:OpenDetails(entry)
	if Addon.QuestPopupSource.CanComplete(entry.id) then
		Addon.QuestPopupSource.Complete(entry.id)
		return
	end

	local popUpType = Addon.QuestPopupSource.Find(entry.id)

	if popUpType == OFFER_POPUP and not C_QuestLog.GetLogIndexForQuestID(entry.id) then
		ShowQuestOffer(entry.id)
		return
	end

	QuestMapFrame_OpenToQuestDetails(entry.id)
end

--- The chat link click (shift by default) drops the quest into the text box.
--- The game's own call checks the modifier and whether a chat box is open.
---@param entry TrackerEntry
---@return boolean
function QuestEntryActions:InsertChatLink(entry)
	return ChatFrameUtil.TryInsertQuestLinkForQuestID(entry.id) == true
end

--- Waypoints would send the map to the next hop rather than to the objective,
--- so they are ignored when asking where this quest lives.
local IGNORE_WAYPOINTS = true

--- Takes the map to the quest's zone and pings it there. A quest with no map of
--- its own reports zero, and then nothing is moved.
---@param entry TrackerEntry
function QuestEntryActions:ShowOnMap(entry)
	local uiMapID = GetQuestUiMapID(entry.id, IGNORE_WAYPOINTS)

	if Addon.MapNavigator.Open(uiMapID, QuestLogDisplayMode.Quests) then
		Addon.MapNavigator.PingQuest(entry.id)
	end
end

---@param entry TrackerEntry
function QuestEntryActions:SuperTrack(entry)
	Addon.SuperTracking.SetQuest(entry.id)
end

---@param entry TrackerEntry
function QuestEntryActions:FindGroup(entry)
	LFGListUtil_FindQuestGroup(entry.id)
end

--- World quests keep their own watch list, so the quest log call would do
--- nothing to them. Letting go of the one being followed also releases the
--- arrow: with Blizzard's tracker hidden there was nowhere else to do that.
---@param entry TrackerEntry
function QuestEntryActions:Untrack(entry)
	if entry.kind == WORLD_QUEST_KIND then
		C_QuestLog.RemoveWorldQuestWatch(entry.id)

		if entry.isSuperTracked then
			Addon.SuperTracking.Clear()
		end

		return
	end

	if not QuestUtil.CanRemoveQuestWatch() then
		return
	end

	C_QuestLog.RemoveQuestWatch(entry.id)
end

--- Reading it means selecting the quest, and the selection is global state the
--- quest log reads too, so whatever was selected is put back. Skipping that
--- would make hovering the tracker quietly change what the quest log shows.
---@param entry TrackerEntry
---@return string?
function QuestEntryActions:Describe(entry)
	local previous = C_QuestLog.GetSelectedQuest()

	C_QuestLog.SetSelectedQuest(entry.id)
	local description = GetQuestLogQuestText()

	if previous then
		C_QuestLog.SetSelectedQuest(previous)
	end

	return description
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function QuestEntryActions:MenuItems(entry)
	local items = {
		{
			label = OBJECTIVES_VIEW_IN_QUESTLOG,
			run = function()
				self:OpenDetails(entry)
			end,
		},
		{
			label = OBJECTIVES_SHOW_QUEST_MAP,
			run = function()
				self:ShowOnMap(entry)
			end,
		},
		{
			label = OBJECTIVES_STOP_TRACKING,
			run = function()
				self:Untrack(entry)
			end,
		},
	}

	if self.waypoints and self.waypoints.isAvailable() then
		table.insert(items, {
			label = Addon.L.MENU_SEND_TO_TOMTOM,
			run = function()
				self.waypoints.send(entry)
			end,
		})
	end

	if entry.kind == QUEST_KIND and C_QuestLog.CanAbandonQuest(entry.id) then
		table.insert(items, {
			label = ABANDON_QUEST,
			run = function()
				QuestMapQuestOptions_AbandonQuest(entry.id)
			end,
		})
	end

	return items
end

Addon.QuestEntryActions = QuestEntryActions
