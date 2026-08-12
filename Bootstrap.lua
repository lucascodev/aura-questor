local ADDON_NAME, Addon = ...

--- Composition root: the only place allowed to know every concrete implementation.
local function BuildAndRun()
	local logger = Addon.ChatLogger.New()
	local startup = Addon.Startup.New(logger)

	startup:Run(Addon.AddonMetadata.GetTitle(), Addon.AddonMetadata.GetVersion())
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loadedAddonName)
	if loadedAddonName ~= ADDON_NAME then
		return
	end

	self:UnregisterEvent("ADDON_LOADED")
	BuildAndRun()
end)
