local _, Addon = ...
local L = Addon.L

local PAGE_NAME = Addon.L.PAGE_PROFILES

local PADDING = 20
local TITLE_GAP = 56
local LABEL_ROW_GAP = 22
local ROW_GAP = 60
local COLUMN_GAP = 250

local RULE_THICKNESS = 1
local RULE_WIDTH = 420
local ACCENT_WIDTH = 60
local RULE_COLOR = { red = 0.26, green = 0.24, blue = 0.20, alpha = 0.9 }
local ACCENT_COLOR = { red = 0.95, green = 0.72, blue = 0.25, alpha = 1 }

local ACTIVE_LABEL = Addon.L.PROFILE_ACTIVE
local NEW_LABEL = Addon.L.PROFILE_NEW
local COPY_LABEL = Addon.L.PROFILE_COPY
local DELETE_LABEL = Addon.L.PROFILE_DELETE
local EXPORT_LABEL = Addon.L.PROFILE_EXPORT
local IMPORT_LABEL = Addon.L.PROFILE_IMPORT

--- The profile page.
---@class ProfilePanel
local ProfilePanel = {}

---@param frame table
---@param color table
---@param width number
---@param offset number
local function AddRule(frame, color, width, offset)
	local rule = frame:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	rule:SetSize(width, RULE_THICKNESS)
	rule:SetPoint("TOPLEFT", PADDING, offset)
end

--- A name is both the value and the label, the same shape the media lists take.
---@param commands table
---@return PreferenceChoice[]
local function ProfileChoices(commands)
	local choices = {}

	for _, name in ipairs(commands.profileNames()) do
		table.insert(choices, { id = name, label = name })
	end

	return choices
end

---@param category table Parent category the page hangs under.
---@param commands table Everything the page can do to a profile.
function ProfilePanel.Register(category, commands)
	local frame = CreateFrame("Frame")
	frame.name = PAGE_NAME

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(PAGE_NAME)

	AddRule(frame, RULE_COLOR, RULE_WIDTH, -TITLE_GAP)
	AddRule(frame, ACCENT_COLOR, ACCENT_WIDTH, -TITLE_GAP)

	---@param label string
	---@param run fun()
	---@return table
	local function Button(label, run)
		return Addon.PanelControls.Button(frame, { label = label, run = run })
	end

	local rows = {
		{
			Addon.PanelControls.Dropdown(frame, {
				label = ACTIVE_LABEL,
				choices = function()
					return ProfileChoices(commands)
				end,
				get = commands.currentProfile,
				set = commands.selectProfile,
			}),
		},
		{
			Button(NEW_LABEL, commands.createProfile),
			Button(COPY_LABEL, commands.copyProfile),
		},
		{
			Button(EXPORT_LABEL, commands.exportProfile),
			Button(IMPORT_LABEL, commands.importProfile),
		},
		{
			Button(DELETE_LABEL, commands.deleteProfile),
		},
	}

	local controls = {}
	local offset = -TITLE_GAP - LABEL_ROW_GAP - ROW_GAP

	for _, row in ipairs(rows) do
		for index, control in ipairs(row) do
			control:SetPoint("TOPLEFT", PADDING + (index - 1) * COLUMN_GAP, offset)
			table.insert(controls, control)
		end

		offset = offset - ROW_GAP
	end

	frame:SetScript("OnShow", function()
		for _, control in ipairs(controls) do
			control:Refresh()
		end
	end)

	Settings.RegisterCanvasLayoutSubcategory(category, frame, PAGE_NAME)
end

Addon.ProfilePanel = ProfilePanel
