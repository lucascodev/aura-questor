local _, Addon = ...

--- CommandRegistry port backed by the global SlashCmdList.
--- Every key is namespaced by the addon so it cannot clash with another addon.
---@class SlashCommandRegistry : CommandRegistry
---@field private namespace string
local SlashCommandRegistry = {}
SlashCommandRegistry.__index = SlashCommandRegistry

---@param namespace string
---@return SlashCommandRegistry
function SlashCommandRegistry.New(namespace)
	return setmetatable({ namespace = namespace:upper() }, SlashCommandRegistry)
end

---@param command string
---@param handler fun(argument: string)
function SlashCommandRegistry:Register(command, handler)
	local key = self.namespace .. "_" .. command:upper()

	_G["SLASH_" .. key .. "1"] = "/" .. command
	SlashCmdList[key] = handler
end

Addon.SlashCommandRegistry = SlashCommandRegistry
