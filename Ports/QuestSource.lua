---@meta

--- Reads the quest log and drives what the tracker watches.
---
--- SetWatched returns false when the game refused the change — the watch list
--- has a hard cap — so the caller can tell the player instead of silently
--- showing less than they asked for.
---@class QuestSource
---@field ListAll fun(self: QuestSource): Quest[]
---@field SetWatched fun(self: QuestSource, questID: number, isWatched: boolean): boolean
