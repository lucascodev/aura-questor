local _, Addon = ...

--- Where a frame sits, remembered across sessions.
---
--- Placed from numbers, never from measuring the frame: the client answers
--- GetLeft and GetTop with the rectangle of the last drawn frame, so measuring
--- right after anchoring reads the place the frame has just left. Writing that
--- back is what walked the window a step on every reload.
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

--- Reads the corner the frame is anchored by. Safe where measuring is not:
--- these are the numbers the anchor was set with, not a drawn rectangle.
function FramePosition:Save()
	local point, _, relativePoint, x, y = self.frame:GetPoint()

	self.saved.point = point
	self.saved.relativePoint = relativePoint
	self.saved.x = x
	self.saved.y = y
end

function FramePosition:Restore()
	local Place = Addon.TrackerPlace
	local left, top = Place.Resolve(
		self.saved,
		{ width = self.frame:GetWidth(), height = self.frame:GetHeight() },
		{ width = GetScreenWidth(), height = GetScreenHeight() }
	)

	self.frame:ClearAllPoints()
	self.frame:SetPoint(Place.anchor, UIParent, Place.screenAnchor, left, top)
end

--- Back to where a fresh install puts it, for when the frame has been dragged
--- somewhere unreachable: off screen, or under another addon.
function FramePosition:Reset()
	wipe(self.saved)
	self:Restore()
end

Addon.FramePosition = FramePosition
