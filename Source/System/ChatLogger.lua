local _, Addon = ...

local CHAT_PREFIX = "|cffff7d0a[AQ]|r "
local WARN_COLOR = "|cffff2020"
local COLOR_END = "|r"

--- Logger port backed by the default chat frame.
---@class ChatLogger : Logger
local ChatLogger = {}
ChatLogger.__index = ChatLogger

---@return ChatLogger
function ChatLogger.New()
	return setmetatable({}, ChatLogger)
end

---@param message string
function ChatLogger:Info(message)
	DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. message)
end

---@param message string
function ChatLogger:Warn(message)
	DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. WARN_COLOR .. message .. COLOR_END)
end

Addon.ChatLogger = ChatLogger
