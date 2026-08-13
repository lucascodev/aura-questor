local _, Addon = ...

--- SectionProvider for the systems that publish their tracked items as one list
--- of ids plus a lookup by id: Traveler's Log activities and neighbourhood
--- initiative tasks. Both describe progress as a requirements list, so the only
--- difference between them is which namespace answers.
---@class TrackedListSectionProvider : SectionProvider
---@field private source TrackedListSource
local TrackedListSectionProvider = {}
TrackedListSectionProvider.__index = TrackedListSectionProvider

---@param source TrackedListSource
---@return TrackedListSectionProvider
function TrackedListSectionProvider.New(source)
	return setmetatable({ source = source }, TrackedListSectionProvider)
end

---@private
---@param id number
---@return TrackerEntry?
function TrackedListSectionProvider:ReadEntry(id)
	local info = self.source.readInfo(id)
	local title = info and info[self.source.titleField]

	if not title then
		return nil
	end

	return {
		id = id,
		kind = self.source.kind,
		title = title,
		objectives = Addon.RequirementReader.Read(info.requirementsList),
		isComplete = info.completed == true,
		canFindGroup = false,
		pinStyle = "none",
	}
end

---@return TrackerSection[]
function TrackedListSectionProvider:Collect()
	local entries = {}
	local tracked = self.source.readTracked()

	for _, id in ipairs(tracked and tracked.trackedIDs or {}) do
		local entry = self:ReadEntry(id)

		if entry then
			table.insert(entries, entry)
		end
	end

	return {
		{
			id = self.source.sectionID,
			title = self.source.title,
			order = Addon.SectionOrder[self.source.sectionID],
			entries = entries,
		},
	}
end

Addon.TrackedListSectionProvider = TrackedListSectionProvider
