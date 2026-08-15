local _, Addon = ...

local DEFAULT_POINT = "RIGHT"
local DEFAULT_OFFSET_X = -120
local DEFAULT_OFFSET_Y = 0

--- Where a frame sits, remembered across sessions.
---@class FramePosition
---@field private frame table
---@field private saved table
local FramePosition = {}
FramePosition.__index = FramePosition

---@param frame table
---@param saved table Persisted across sessions; empty on a fresh install.
---@return FramePosition
function FramePosition.New(frame, saved)
	return setmetatable({ frame = frame, saved = saved }, FramePosition)
end

function FramePosition:Save()
	local point, _, relativePoint, x, y = self.frame:GetPoint()

	self.saved.point = point
	self.saved.relativePoint = relativePoint
	self.saved.x = x
	self.saved.y = y
end

function FramePosition:Restore()
	if not self.saved.point then
		self.frame:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_POINT, DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y)
		return
	end

	self.frame:SetPoint(
		self.saved.point,
		UIParent,
		self.saved.relativePoint,
		self.saved.x,
		self.saved.y
	)
end

--- Back to where a fresh install puts it, for when the frame has been dragged
--- somewhere unreachable: off screen, or under another addon.
function FramePosition:Reset()
	wipe(self.saved)
	self.frame:ClearAllPoints()
	self:Restore()
end

Addon.FramePosition = FramePosition
