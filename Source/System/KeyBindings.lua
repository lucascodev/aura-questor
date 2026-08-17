local _, Addon = ...

--- Names the game reads out of the global namespace to build its key binding
--- screen. There is no other way in: the binding system predates anything
--- scoped, so the header, the labels and the actions all have to be globals.
---
--- The two command names keep the old addon name on purpose: they are the key
--- the client files the player's chosen key under, and renaming them would
--- silently unbind everyone.
BINDING_HEADER_AURAQUESTOR = Addon.L.BINDING_HEADER
BINDING_NAME_AURATRACKERQUESTOR_TOGGLE = Addon.L.BINDING_TOGGLE
BINDING_NAME_AURATRACKERQUESTOR_OPTIONS = Addon.L.BINDING_OPTIONS

--- Bridges the game's key bindings to the addon.
---
--- Confining the globals to this one file is the point: everything else keeps
--- receiving what it needs instead of reaching for a name in the open.
---@class KeyBindings
local KeyBindings = {}

---@param toggleTracker fun()
---@param openOptions fun()
function KeyBindings.Install(toggleTracker, openOptions)
	AuraQuestor_ToggleTracker = toggleTracker
	AuraQuestor_OpenOptions = openOptions
end

Addon.KeyBindings = KeyBindings
