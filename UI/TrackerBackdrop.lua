local _, Addon = ...

--- The panel's background and border.
---
--- Rebuilding a backdrop recreates nine textures, and appearance is applied on
--- every quest update, so a signature of what the backdrop is made of decides
--- whether there is anything to redo.
---@class TrackerBackdrop
---@field private frame table
---@field private signature string?
local TrackerBackdrop = {}
TrackerBackdrop.__index = TrackerBackdrop

---@param frame table A frame created with BackdropTemplate.
---@return TrackerBackdrop
function TrackerBackdrop.New(frame)
	return setmetatable({ frame = frame }, TrackerBackdrop)
end

---@param appearance TrackerAppearance
---@return string
local function SignatureOf(appearance)
	return ("%s|%s|%d|%d"):format(
		appearance.backgroundTexture or "",
		appearance.borderTexture or "",
		appearance.borderThickness,
		appearance.backgroundInset
	)
end

---@param appearance TrackerAppearance
function TrackerBackdrop:Apply(appearance)
	local signature = SignatureOf(appearance)

	if signature ~= self.signature then
		self.signature = signature

		local inset = appearance.backgroundInset

		self.frame:SetBackdrop({
			bgFile = appearance.backgroundTexture,
			edgeFile = appearance.borderTexture,
			edgeSize = appearance.borderThickness,
			insets = { left = inset, right = inset, top = inset, bottom = inset },
		})
	end

	self.frame:SetBackdropColor(
		appearance.backgroundColor.red,
		appearance.backgroundColor.green,
		appearance.backgroundColor.blue,
		appearance.opacity
	)
	self.frame:SetBackdropBorderColor(
		appearance.borderColor.red,
		appearance.borderColor.green,
		appearance.borderColor.blue,
		appearance.borderOpacity
	)
end

Addon.TrackerBackdrop = TrackerBackdrop
