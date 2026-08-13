local _, Addon = ...

--- Names the game reads out of the global namespace to build its key binding
--- screen. There is no other way in: the binding system predates anything
--- scoped, so the header, the labels and the actions all have to be globals.
BINDING_HEADER_AURATRACKERQUESTOR = "Aura Tracker Questor"
BINDING_NAME_AURATRACKERQUESTOR_TOGGLE = "Mostrar / esconder o rastreador"
BINDING_NAME_AURATRACKERQUESTOR_OPTIONS = "Abrir as opções"

--- Bridges the game's key bindings to the addon.
---
--- Confining the globals to this one file is the point: everything else keeps
--- receiving what it needs instead of reaching for a name in the open.
---@class KeyBindings
local KeyBindings = {}

---@param toggleTracker fun()
---@param openOptions fun()
function KeyBindings.Install(toggleTracker, openOptions)
	AuraTrackerQuestor_ToggleTracker = toggleTracker
	AuraTrackerQuestor_OpenOptions = openOptions
end

Addon.KeyBindings = KeyBindings
