local _, Addon = ...

---@class ProfilePanel
local ProfilePanel = {}

---@param commands table
---@return PreferenceChoice[]
local function ProfileChoices(commands)
	local choices = {}

	for _, name in ipairs(commands.profileNames()) do
		table.insert(choices, { id = name, label = name })
	end

	return choices
end

---@param commands table
---@return fun(parent: table, width: number): table
local function ActiveProfileCell(commands)
	return function(parent, width)
		local Theme = Addon.OptionsTheme
		local Fonts = Addon.OptionsFonts

		local frame = CreateFrame("Frame", nil, parent)
		frame:SetSize(width, Theme.INPUT_HEIGHT)

		local name = frame:CreateFontString(nil, "ARTWORK")
		name:SetFontObject(Fonts.BIG)
		name:SetPoint("LEFT")
		name:SetTextColor(Theme.TEXT_COLOR.red, Theme.TEXT_COLOR.green, Theme.TEXT_COLOR.blue)

		local hint = frame:CreateFontString(nil, "ARTWORK")
		hint:SetFontObject(Fonts.HINT)
		hint:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 10, 2)
		hint:SetText(Addon.L.PROFILE_ON_CHARACTER)
		hint:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)

		local switcher = Addon.OptionsControls.Dropdown(frame, {
			width = 220,
			choices = function()
				return ProfileChoices(commands)
			end,
			get = commands.currentProfile,
			set = commands.selectProfile,
		})
		switcher:SetPoint("RIGHT")

		function frame:Refresh()
			name:SetText(commands.currentProfile())
			switcher:Refresh()
		end

		frame:Refresh()

		return frame
	end
end

---@param commands table
---@return fun(parent: table, width: number): table
local function ManageCell(commands)
	return function(parent, width)
		local Theme = Addon.OptionsTheme
		local Fonts = Addon.OptionsFonts
		local Controls = Addon.OptionsControls

		local frame = CreateFrame("Frame", nil, parent)
		frame:SetWidth(width)

		local buttons = {
			Controls.Button(frame, {
				label = Addon.L.PROFILE_NEW,
				run = commands.createProfile,
				variant = "primary",
			}),
			Controls.Button(frame, { label = Addon.L.PROFILE_COPY, run = commands.copyProfile }),
			Controls.Button(frame, { label = Addon.L.PROFILE_EXPORT, run = commands.exportProfile }),
			Controls.Button(frame, { label = Addon.L.PROFILE_IMPORT, run = commands.importProfile }),
		}

		local x = 0

		for _, button in ipairs(buttons) do
			button:SetPoint("TOPLEFT", x, 0)
			x = x + button:GetWidth() + 10
		end

		local buttonBottom = 24 + 14

		local divider = frame:CreateTexture(nil, "ARTWORK")
		divider:SetColorTexture(
			Theme.DIVIDER_COLOR.red,
			Theme.DIVIDER_COLOR.green,
			Theme.DIVIDER_COLOR.blue,
			Theme.DIVIDER_COLOR.alpha
		)
		divider:SetHeight(Theme.RULE_THICKNESS)
		divider:SetPoint("TOPLEFT", 0, -buttonBottom)
		divider:SetPoint("TOPRIGHT", 0, -buttonBottom)

		local dangerTop = buttonBottom + Theme.RULE_THICKNESS + 14

		local deleteButton = Controls.Button(frame, {
			label = Addon.L.PROFILE_DELETE,
			run = commands.deleteProfile,
			variant = "danger",
		})
		deleteButton:SetPoint("TOPRIGHT", 0, -dangerTop)

		local warning = frame:CreateFontString(nil, "ARTWORK")
		warning:SetFontObject(Fonts.HINT)
		warning:SetPoint("TOPLEFT", 0, -(dangerTop + 4))
		warning:SetWidth(width - deleteButton:GetWidth() - 24)
		warning:SetJustifyH("LEFT")
		warning:SetText(Addon.L.PROFILE_DELETE_HINT)
		warning:SetTextColor(Theme.HINT_COLOR.red, Theme.HINT_COLOR.green, Theme.HINT_COLOR.blue)

		frame:SetHeight(dangerTop + math.max(24, warning:GetStringHeight() + 8))

		function frame:Refresh() end

		return frame
	end
end

---@param category table
---@param commands table
---@return table subcategory
function ProfilePanel.Register(category, commands)
	local page = Addon.OptionsPage.New({
		title = Addon.L.PAGE_PROFILES,
		subtitle = Addon.L.PAGE_PROFILES_HINT,
	})

	page:Mount({
		{
			title = Addon.L.PROFILE_ACTIVE,
			rows = { { { build = ActiveProfileCell(commands), span = 2 } } },
		},
		{
			title = Addon.L.SECTION_MANAGE,
			rows = { { { build = ManageCell(commands), span = 2 } } },
		},
	}, {})

	return page:RegisterUnder(category)
end

Addon.ProfilePanel = ProfilePanel
