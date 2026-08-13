---@meta

--- A named rule deciding which quests stay in the tracker.
--- A passive filter leaves the watch list untouched, which is what the addon
--- does until the player asks for something else.
---@class QuestFilter
---@field id string
---@field label string
---@field isPassive? boolean
---@field matches? fun(quest: Quest): boolean Required unless isPassive.
