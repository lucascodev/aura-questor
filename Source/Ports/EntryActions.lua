---@meta

--- One entry in the right-click menu, already bound to what it acts on.
---@class EntryMenuItem
---@field label string
---@field run fun()

--- What the player can do with an entry.
---
--- The menu is asked for rather than assembled by the renderer, because only the
--- actions know what makes sense for their kind of entry: a bonus objective has
--- no quest log page and cannot be untracked, so it must not be offered either.
---@class EntryActions
---@field OpenDetails fun(self: EntryActions, entry: TrackerEntry) Left click.
---@field MenuItems fun(self: EntryActions, entry: TrackerEntry): EntryMenuItem[]
---@field FindGroup fun(self: EntryActions, entry: TrackerEntry) Only called when entry.canFindGroup.
---@field SuperTrack? fun(self: EntryActions, entry: TrackerEntry) Only where entry.isSuperTrackable.
---@field Describe? fun(self: EntryActions, entry: TrackerEntry): string? Extra text for the tooltip.
---@field InsertChatLink? fun(self: EntryActions, entry: TrackerEntry): boolean Chat-link click; true when the link went to the chat box.

--- Manda uma entrada para a seta de navegação, quando há uma disponível.
---@class EntryWaypoints
---@field isAvailable fun(): boolean
---@field send fun(entry: TrackerEntry)

--- The usable item some quests carry, ready to be put on a secure button.
---@class EntryItem
---@field link string
---@field texture number|string
---@field charges number
---@field cooldownStart number
---@field cooldownDuration number
