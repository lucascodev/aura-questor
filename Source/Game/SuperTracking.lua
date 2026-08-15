local _, Addon = ...

--- The arrow that follows one objective at a time.
---
--- Clearing is not a per-entry action: there is a single super-tracked thing in
--- the game, and letting go of it is the same call whatever was being followed.
---
--- Escrever a supervisão em combate mancha o caminho que o mapa percorre ao
--- criar pinos, e SetPassThroughButtons é bloqueada em combate; o pedido
--- espera o combate acabar. Só o último clique vale, como valeria fora dele.
---@class SuperTracking
local SuperTracking = {}

local pendingWrite = nil
local combatListener = nil

---@param write fun()
local function RunOrDefer(write)
	if not InCombatLockdown() then
		write()
		return
	end

	pendingWrite = write

	if combatListener then
		return
	end

	combatListener = CreateFrame("Frame")
	combatListener:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatListener:SetScript("OnEvent", function()
		local queued = pendingWrite

		pendingWrite = nil

		if queued then
			queued()
		end
	end)
end

---@param questID number
function SuperTracking.SetQuest(questID)
	RunOrDefer(function()
		C_SuperTrack.SetSuperTrackedQuestID(questID)
	end)
end

---@param pinType number
---@param pinID number
function SuperTracking.SetMapPin(pinType, pinID)
	RunOrDefer(function()
		C_SuperTrack.SetSuperTrackedMapPin(pinType, pinID)
	end)
end

function SuperTracking.Clear()
	RunOrDefer(function()
		C_SuperTrack.ClearAllSuperTracked()
	end)
end

Addon.SuperTracking = SuperTracking
