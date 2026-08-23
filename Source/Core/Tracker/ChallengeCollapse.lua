local _, Addon = ...

local COLLAPSE = "collapse"
local EXPAND = "expand"

--- Whether the tracker should fold itself away while a Mythic+ run is going.
---
--- The whole difficulty is telling apart a window this addon folded from one
--- the player folded. Only the first is ours to open again: unfolding the other
--- would undo a choice nobody asked us to touch.
local ChallengeCollapse = {
	COLLAPSE = COLLAPSE,
	EXPAND = EXPAND,
}

---@class ChallengeCollapseState
---@field isEnabled boolean
---@field isChallengeActive boolean
---@field isCollapsed boolean
---@field isOurs boolean Whether the fold in place is the one this addon did.

---@param state ChallengeCollapseState
---@return string? action COLLAPSE, EXPAND, or nothing to do.
---@return boolean isOurs What to remember for the next answer.
function ChallengeCollapse.Decide(state)
	-- Turning the setting off mid run hands the window back rather than leaving
	-- it folded with nothing left to unfold it.
	if not state.isEnabled then
		return state.isOurs and EXPAND or nil, false
	end

	if not state.isChallengeActive then
		return state.isOurs and EXPAND or nil, false
	end

	if state.isOurs then
		-- Opened by hand during the run: the window is theirs from here, and the
		-- end of the run leaves it alone.
		return nil, state.isCollapsed
	end

	-- Already folded before the run started, so there is nothing to do and
	-- nothing to claim: it stays folded when the run ends, as they left it.
	if state.isCollapsed then
		return nil, false
	end

	return COLLAPSE, true
end

Addon.ChallengeCollapse = ChallengeCollapse
