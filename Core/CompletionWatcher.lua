local _, Addon = ...

--- Reports the entries that have just been finished.
---@class CompletionWatcher
---@field private completed table<string, boolean>
---@field private hasSeeded boolean
local CompletionWatcher = {}
CompletionWatcher.__index = CompletionWatcher

---@return CompletionWatcher
function CompletionWatcher.New()
	return setmetatable({ completed = {}, hasSeeded = false }, CompletionWatcher)
end

---@param entry TrackerEntry
---@return string
local function KeyOf(entry)
	return ("%s:%s"):format(entry.kind, entry.id)
end

---@param sections TrackerSection[]
---@return TrackerEntry[]
function CompletionWatcher:Detect(sections)
	local seen = {}
	local justCompleted = {}

	for _, section in ipairs(sections) do
		for _, entry in ipairs(section.entries) do
			local key = KeyOf(entry)
			seen[key] = entry.isComplete == true

			if seen[key] and not self.completed[key] and self.hasSeeded then
				table.insert(justCompleted, entry)
			end
		end
	end

	self.completed = seen
	self.hasSeeded = true

	return justCompleted
end

Addon.CompletionWatcher = CompletionWatcher
