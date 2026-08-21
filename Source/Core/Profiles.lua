local _, Addon = ...

--- Fixed on purpose: it is a SavedVariables key, and translating it would make
--- the profile disappear when the player changed the client language.
local DEFAULT_NAME = "Default"

--- Tables a profile owns besides its settings. Named here so migration and
--- creation cannot drift apart.
local PROFILE_TABLES = {
	"ownTrackerPosition",
	"ownTrackerState",
	"collapsedSections",
	"hiddenCategories",
	"hiddenSections",
	"sectionOrder",
	"minimapButton",
}

--- Named sets of settings, with one active per character.
---
--- Holds the raw SavedVariables table and nothing else, no game API, so the
--- whole thing is testable outside the client.
---@class Profiles
---@field private database table
---@field private characterKey string
local Profiles = {}
Profiles.__index = Profiles

---@return table
local function NewProfile()
	local profile = { settings = {} }

	for _, name in ipairs(PROFILE_TABLES) do
		profile[name] = {}
	end

	return profile
end

--- The default profile once had a translated name, and a client in another
--- language would stop finding it. Renaming keeps the settings: without it a
--- character that never picked a profile would get an empty one.
local LEGACY_DEFAULT_NAMES = { "Padrão" }

---@private
function Profiles:RenameLegacyDefault()
	local profiles = self.database.profiles

	if not profiles or profiles[DEFAULT_NAME] then
		return
	end

	for _, legacy in ipairs(LEGACY_DEFAULT_NAMES) do
		if profiles[legacy] then
			profiles[DEFAULT_NAME] = profiles[legacy]
			profiles[legacy] = nil

			for characterKey, name in pairs(self.database.characters or {}) do
				if name == legacy then
					self.database.characters[characterKey] = DEFAULT_NAME
				end
			end

			return
		end
	end
end

--- Everything used to live loose at the root of the saved table. It is moved
--- into the first profile rather than discarded: those are settings the player
--- already made, and losing them to a refactor would be inexcusable.
---@private
function Profiles:Migrate()
	local database = self.database

	if database.profiles then
		self:RenameLegacyDefault()
		return
	end

	local moved = NewProfile()

	for _, name in ipairs(PROFILE_TABLES) do
		if type(database[name]) == "table" then
			moved[name] = database[name]
			database[name] = nil
		end
	end

	-- Clearing a key already visited is allowed while traversing, so the loose
	-- settings can be lifted and removed in one pass.
	for key, value in pairs(database) do
		moved.settings[key] = value
		database[key] = nil
	end

	database.profiles = { [DEFAULT_NAME] = moved }
	database.characters = {}
end

---@param database table The SavedVariables root.
---@param characterKey string
---@return Profiles
function Profiles.New(database, characterKey)
	local profiles = setmetatable({
		database = database,
		characterKey = characterKey,
	}, Profiles)

	profiles:Migrate()

	return profiles
end

---@return string
function Profiles:CurrentName()
	return self.database.characters[self.characterKey] or DEFAULT_NAME
end

--- The active profile, created on demand so a character pointed at a deleted
--- profile still gets somewhere to write instead of erroring.
--- A profile saved by an earlier version may be missing a table added later:
--- it starts empty on first read, without touching what was already there.
---@param profile table
local function Complete(profile)
	for _, name in ipairs(PROFILE_TABLES) do
		if type(profile[name]) ~= "table" then
			profile[name] = {}
		end
	end
end

---@return table
function Profiles:Current()
	local name = self:CurrentName()

	if not self.database.profiles[name] then
		self.database.profiles[name] = NewProfile()
	end

	Complete(self.database.profiles[name])

	return self.database.profiles[name]
end

---@return string[]
function Profiles:Names()
	local names = {}

	for name in pairs(self.database.profiles) do
		table.insert(names, name)
	end

	table.sort(names)

	return names
end

---@param name string
function Profiles:Select(name)
	self.database.characters[self.characterKey] = name
end

--- A new profile starts empty, which means every preference falls back to its
--- default, the same state a fresh install has.
---@param name string
function Profiles:Create(name)
	if self.database.profiles[name] then
		return
	end

	self.database.profiles[name] = NewProfile()
end

---@param source table
---@return table
local function DeepCopy(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = type(value) == "table" and DeepCopy(value) or value
	end

	return copy
end

--- Takes a profile from outside. The stored tables are filled in from a fresh
--- one so a profile exported by an older version, missing a table added since,
--- still lands complete instead of erroring the first time it is read.
---@param name string
---@param profile table
function Profiles:Import(name, profile)
	local complete = NewProfile()

	complete.settings = profile.settings or {}

	for _, tableName in ipairs(PROFILE_TABLES) do
		if type(profile[tableName]) == "table" then
			complete[tableName] = profile[tableName]
		end
	end

	self.database.profiles[name] = complete
end

---@param name string
function Profiles:CopyCurrentTo(name)
	self.database.profiles[name] = DeepCopy(self:Current())
end

--- The active profile is never removed: a character must always have somewhere
--- to write, and deleting what you are standing on is a trap.
---@param name string
---@return boolean removed
function Profiles:Delete(name)
	if name == self:CurrentName() then
		return false
	end

	self.database.profiles[name] = nil

	for characterKey, profileName in pairs(self.database.characters) do
		if profileName == name then
			self.database.characters[characterKey] = nil
		end
	end

	return true
end

Addon.Profiles = Profiles
