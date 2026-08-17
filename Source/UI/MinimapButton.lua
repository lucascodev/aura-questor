local ADDON_NAME, Addon = ...

local ICON = "Interface\\AddOns\\AuraQuestor\\Media\\Logo"

local LEFT_HINT = Addon.L.MINIMAP_LEFT_HINT
local RIGHT_HINT = Addon.L.MINIMAP_RIGHT_HINT

--- The minimap button, by way of the broker object behind it.
---
--- LibDataBroker publishes a launcher other displays can pick up (Titan, ElvUI
--- data texts) and LibDBIcon is only one consumer of it. Registering the broker
--- rather than drawing a button means the addon shows up wherever the player
--- already keeps their launchers.
---@class MinimapButton
---@field private addonInfo AddonInfo
---@field private position table Persisted; LibDBIcon writes the angle into it.
---@field private onToggle fun()
---@field private onOptions fun()
local MinimapButton = {}
MinimapButton.__index = MinimapButton

---@param addonInfo AddonInfo
---@param position table
---@param onToggle fun()
---@param onOptions fun()
---@return MinimapButton
function MinimapButton.New(addonInfo, position, onToggle, onOptions)
	return setmetatable({
		addonInfo = addonInfo,
		position = position,
		onToggle = onToggle,
		onOptions = onOptions,
	}, MinimapButton)
end

function MinimapButton:Attach()
	local broker = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
		type = "launcher",
		icon = ICON,
		OnClick = function(_, button)
			if button == "RightButton" then
				self.onOptions()
				return
			end

			self.onToggle()
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(self.addonInfo.title)
			tooltip:AddLine(LEFT_HINT, 1, 1, 1)
			tooltip:AddLine(RIGHT_HINT, 1, 1, 1)
		end,
	})

	LibStub("LibDBIcon-1.0"):Register(ADDON_NAME, broker, self.position)
end

--- TrackerWidget port. Only the icon goes away; the broker stays published, so a
--- data-text bar that shows it keeps working.
---@param isShown boolean
function MinimapButton:SetShown(isShown)
	local icons = LibStub("LibDBIcon-1.0")

	if isShown then
		icons:Show(ADDON_NAME)
		return
	end

	icons:Hide(ADDON_NAME)
end

Addon.MinimapButton = MinimapButton
