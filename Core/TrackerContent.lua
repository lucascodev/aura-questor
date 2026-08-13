local _, Addon = ...

local Keys = Addon.PreferenceKeys

--- Assembles what the tracker should show, from every registered provider.
---
--- Knows nothing about quests, achievements or frames: it collects sections,
--- drops the empty ones and puts them in order. Adding a content type means
--- adding a provider, never touching this.
---@class TrackerContent
---@field private providers SectionProvider[]
---@field private sortModes SortMode[]
---@field private preferences Preferences
local TrackerContent = {}
TrackerContent.__index = TrackerContent

---@param providers SectionProvider[]
---@param sortModes SortMode[]
---@param preferences Preferences
---@return TrackerContent
function TrackerContent.New(providers, sortModes, preferences)
	return setmetatable({
		providers = providers,
		sortModes = sortModes,
		preferences = preferences,
	}, TrackerContent)
end

--- Ordering applies inside a section, never across them: the sections have a
--- meaning of their own and a fixed place.
---@private
---@param sections TrackerSection[]
function TrackerContent:SortEntries(sections)
	local selectedID = self.preferences:Get(Keys.SORT_MODE)

	for _, mode in ipairs(self.sortModes) do
		if mode.id == selectedID then
			if not mode.compare then
				return
			end

			for _, section in ipairs(sections) do
				table.sort(section.entries, mode.compare)
			end

			return
		end
	end
end

--- Split into two lists and joined instead of sorted, because table.sort would
--- also shuffle entries that share a state — and "Desativada" promises to keep
--- the order they were tracked in.
---@private
---@param sections TrackerSection[]
function TrackerContent:SinkCompleted(sections)
	for _, section in ipairs(sections) do
		local pending = {}
		local completed = {}

		for _, entry in ipairs(section.entries) do
			table.insert(entry.isComplete and completed or pending, entry)
		end

		for _, entry in ipairs(completed) do
			table.insert(pending, entry)
		end

		section.entries = pending
	end
end

---@return TrackerSection[]
function TrackerContent:Build()
	local sections = {}

	for _, provider in ipairs(self.providers) do
		for _, section in ipairs(provider:Collect()) do
			if #section.entries > 0 then
				table.insert(sections, section)
			end
		end
	end

	table.sort(sections, function(left, right)
		return left.order < right.order
	end)

	self:SortEntries(sections)
	self:SinkCompleted(sections)

	return sections
end

Addon.TrackerContent = TrackerContent
