local _, Addon = ...

local MINUTES_PER_HOUR = 60
local COLOR_CHANNEL_MAXIMUM = 255

--- Gold for the part already done, so "9/16" reads as progress at a glance
--- instead of as one grey number.
local PROGRESS_HEX = "ffd100"

local OBJECTIVE_COLOR = { red = 0.82, green = 0.82, blue = 0.82 }
local OBJECTIVE_COMPLETE_COLOR = { red = 0.55, green = 0.55, blue = 0.55 }
local TIME_COLOR = { red = 0.4, green = 0.7, blue = 1 }
local GROUP_COLOR = { red = 0.45, green = 0.65, blue = 0.9 }

--- Turns an entry into the strings the block draws.
---@class EntryText
local EntryText = {}

EntryText.TITLE_COLOR = { red = 1, green = 0.82, blue = 0 }
EntryText.TITLE_COMPLETE_COLOR = { red = 0.55, green = 0.85, blue = 0.55 }

--- The one the arrow is following reads brighter than the rest. The pin already
--- says so, but only if you are looking at the pin.
EntryText.TITLE_TRACKED_COLOR = { red = 1, green = 0.97, blue = 0.88 }

---@param minutes number
---@return string
local function FormatTimeLeft(minutes)
	if minutes < MINUTES_PER_HOUR then
		return ("%d min"):format(minutes)
	end

	return ("%dh %dmin"):format(math.floor(minutes / MINUTES_PER_HOUR), minutes % MINUTES_PER_HOUR)
end

--- Highlights the achieved half of an "x/y" count. Objectives that have not
--- started keep a plain zero: colouring it would suggest progress that is not
--- there.
---@param text string
---@return string
local function HighlightProgress(text)
	local current, remainder = text:match("^(%d+)(/%d+.*)$")

	if not current or tonumber(current) == 0 then
		return text
	end

	return ("|cff%s%s|r%s"):format(PROGRESS_HEX, current, remainder)
end

--- The level reads in the game's own difficulty colour, the same one the quest
--- log uses, so green really means trivial.
---@param entry TrackerEntry
---@return string
function EntryText.Title(entry)
	if not entry.level then
		return entry.title
	end

	local color = GetQuestDifficultyColor(entry.level)

	return ("|cff%02x%02x%02x[%d]|r %s"):format(
		math.floor(color.r * COLOR_CHANNEL_MAXIMUM),
		math.floor(color.g * COLOR_CHANNEL_MAXIMUM),
		math.floor(color.b * COLOR_CHANNEL_MAXIMUM),
		entry.level,
		entry.title
	)
end

---@param entry TrackerEntry
---@param isSuperTracked boolean
---@return table
function EntryText.TitleColor(entry, isSuperTracked)
	return entry.isComplete and EntryText.TITLE_COMPLETE_COLOR
		or isSuperTracked and EntryText.TITLE_TRACKED_COLOR
		or EntryText.TITLE_COLOR
end

--- The group, the objectives and the expiry clock share one column, so they are
--- collected into a single list first and drawn by one loop. Only objectives get
--- the dash: the others are context, not progress.
---@param entry TrackerEntry
---@return { text: string, color: table, percent: number?, card: TrackerObjectiveCard?, widgetSetID: number? }[]
function EntryText.Rows(entry)
	local rows = {}

	if entry.groupName then
		table.insert(rows, { text = entry.groupName, color = GROUP_COLOR })
	end

	for _, objective in ipairs(entry.objectives) do
		-- Card e widget têm moldura própria, então o traço de objetivo sobraria.
		local isFramed = objective.card ~= nil or objective.widgetSetID ~= nil

		local color = objective.isComplete and OBJECTIVE_COMPLETE_COLOR or OBJECTIVE_COLOR

		table.insert(rows, {
			text = isFramed and objective.text or ("- " .. HighlightProgress(objective.text)),
			color = color,
			card = objective.card,
			widgetSetID = objective.widgetSetID,
		})

		-- A barra diz a fração, não o que está sendo medido. Sozinha, "0%" não
		-- informa nada, então ela vem depois da linha em vez de no lugar dela.
		if objective.percent and not isFramed then
			table.insert(rows, { text = objective.text, color = color, percent = objective.percent })
		end
	end

	if entry.timeLeftMinutes and entry.timeLeftMinutes > 0 then
		table.insert(rows, { text = FormatTimeLeft(entry.timeLeftMinutes), color = TIME_COLOR })
	end

	return rows
end

Addon.EntryText = EntryText
