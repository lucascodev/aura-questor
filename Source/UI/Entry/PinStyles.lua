local _, Addon = ...

--- Event art is drawn smaller than a quest pin, it reads better that way, and
--- it is the size it had before the pins grew. The column stays the same width
--- either way, so a smaller pin is centred in it instead of shifting the text.
local EVENT_PIN_SIZE = 26

--- Every numbered quest pin comes as the same four-part set, so the family name
--- is enough to build one.
---@param prefix string
---@return table
local function NumberedPin(prefix)
	return {
		normal = prefix,
		pressed = prefix .. "-Pressed",
		selected = prefix .. "-SuperTracked",
		selectedPressed = prefix .. "-Pressed-SuperTracked",
		showsNumber = true,
	}
end

--- The same set, for a pin that carries an icon where the number would be.
---@param prefix string
---@return table
local function IconPin(prefix)
	local style = NumberedPin(prefix)
	style.showsNumber = false

	return style
end

--- Blizzard's own pin art, matched to what each kind of objective is. Using the
--- same families the map uses is what makes a campaign quest here look like the
--- campaign quest there.
---@class EntryPinStyles
local EntryPinStyles = {
	normal = NumberedPin("UI-QuestPoi-QuestNumber"),
	campaign = NumberedPin("UI-QuestPoiCampaign-QuestNumber"),
	legendary = NumberedPin("UI-QuestPoiLegendary-QuestNumber"),
	recurring = NumberedPin("UI-QuestPoiRecurring-QuestNumber"),
	important = NumberedPin("UI-QuestPoiImportant-QuestNumber"),
	meta = NumberedPin("UI-QuestPoiWrapper-QuestNumber"),

	-- Blizzard gives a world quest the same ring as a plain quest, with the type
	-- icon where the number would be.
	worldQuest = IconPin("UI-QuestPoi-QuestNumber"),

	bonus = {
		normal = "worldquest-questmarker-epic",
		pressed = "worldquest-questmarker-epic-down",
		selected = "worldquest-questmarker-epic-supertracked",
		selectedPressed = "worldquest-questmarker-epic-down-supertracked",
		showsNumber = false,
	},

	-- No pin at all. A number that cannot be clicked and points at nothing is
	-- noise, and the column it reserved goes back to the text.
	none = { isHidden = true, showsNumber = false },
}

-- An event pin is a map pin, and the game draws those with the same marker
-- whenever the event has no icon of its own.
EntryPinStyles.areaPoi = EntryPinStyles.bonus

--- A pin drawn with art the entry supplied. There are no pressed or selected
--- variants of these, so all four states share one texture, and being followed
--- shows as the glow the map puts behind its own pins.
---@param atlas string
---@return table
function EntryPinStyles.OwnArt(atlas)
	return {
		normal = atlas,
		pressed = atlas,
		selected = atlas,
		selectedPressed = atlas,
		showsNumber = false,
		glowsWhenSelected = true,
		size = EVENT_PIN_SIZE,
	}
end

--- The art for one entry: what it names for itself wins, then what its kind
--- says, and a plain pin as the last resort.
---@param entry TrackerEntry
---@return table
function EntryPinStyles.For(entry)
	return entry.pinAtlas and EntryPinStyles.OwnArt(entry.pinAtlas)
		or EntryPinStyles[entry.pinStyle]
		or EntryPinStyles.normal
end

Addon.EntryPinStyles = EntryPinStyles
