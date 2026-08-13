---@meta

--- Supplies the sections for one kind of content — quests, achievements,
--- recipes. Every content type the tracker learns is one more implementation
--- of this, and nothing else in the addon has to change.
---
--- Returns a list because a single source can feed more than one section:
--- quests split into campaign and everything else.
---@class SectionProvider
---@field Collect fun(self: SectionProvider): TrackerSection[]
