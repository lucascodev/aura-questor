local _, Addon = ...

--- Sends each action to the implementation that understands that kind of entry.
---
--- Indexing without a guard is deliberate: a kind with no actions registered is
--- a wiring mistake in the composition root, and it should surface the first
--- time it is clicked instead of silently doing nothing.
---@class EntryActionRouter : EntryActions
---@field private byKind table<string, EntryActions>
local EntryActionRouter = {}
EntryActionRouter.__index = EntryActionRouter

---@param byKind table<string, EntryActions>
---@return EntryActionRouter
function EntryActionRouter.New(byKind)
	return setmetatable({ byKind = byKind }, EntryActionRouter)
end

---@param entry TrackerEntry
function EntryActionRouter:OpenDetails(entry)
	self.byKind[entry.kind]:OpenDetails(entry)
end

---@param entry TrackerEntry
---@return EntryMenuItem[]
function EntryActionRouter:MenuItems(entry)
	return self.byKind[entry.kind]:MenuItems(entry)
end

---@param entry TrackerEntry
function EntryActionRouter:FindGroup(entry)
	self.byKind[entry.kind]:FindGroup(entry)
end

---@param entry TrackerEntry
function EntryActionRouter:SuperTrack(entry)
	self.byKind[entry.kind]:SuperTrack(entry)
end

--- Optional by design: most content has nothing to add beyond what the tracker
--- already shows, and an absent description is a fact, not a failure.
---@param entry TrackerEntry
---@return string?
function EntryActionRouter:Describe(entry)
	local actions = self.byKind[entry.kind]

	if not actions.Describe then
		return nil
	end

	return actions:Describe(entry)
end

--- Optional for the same reason as Describe: an achievement pays nothing, and
--- saying so with an empty list is truer than pretending it has rewards.
---@param entry TrackerEntry
---@return string[]
function EntryActionRouter:Rewards(entry)
	local actions = self.byKind[entry.kind]

	if not actions.Rewards then
		return {}
	end

	return actions:Rewards(entry)
end

--- Optional like Describe: only what exists as a link in chat implements it.
---@param entry TrackerEntry
---@return boolean handled
function EntryActionRouter:InsertChatLink(entry)
	local actions = self.byKind[entry.kind]

	if not actions.InsertChatLink then
		return false
	end

	return actions:InsertChatLink(entry) == true
end

Addon.EntryActionRouter = EntryActionRouter
