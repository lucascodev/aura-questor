local _, Addon = ...

--- Limites que dependem de algo medido no cliente, e por isso não cabem no
--- catálogo.
---@class PreferenceBounds
local PreferenceBounds = {}

--- Deixa a tela ditar o teto: num monitor alto o rastreador vai até a borda de
--- baixo, em vez de parar num número escolhido a dedo. O teto do catálogo vira
--- piso, para uma tela baixa nunca encolher o que já está gravado, e o valor
--- cai num múltiplo do passo, senão o último ponto do controle não é
--- alcançável.
---@param preference Preference
---@param available number
---@return number
function PreferenceBounds.Maximum(preference, available)
	local steps = math.floor(available / preference.step)

	return math.max(preference.maximum, steps * preference.step)
end

Addon.PreferenceBounds = PreferenceBounds
