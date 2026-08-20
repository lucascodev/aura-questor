--- O adapter conversa com a API do jogo, então a suíte carrega o arquivo por
--- fora do Harness, com um ObjectiveTrackerFrame de mentira no lugar do global.
return function(_, T)
	---@return table
	local function TrackerFrame()
		return {
			alpha = 1,
			hasMouse = true,
			SetAlpha = function(self, alpha)
				self.alpha = alpha
			end,
			GetAlpha = function(self)
				return self.alpha
			end,
			EnableMouse = function(self, isEnabled)
				self.hasMouse = isEnabled
			end,
			IsMouseEnabled = function(self)
				return self.hasMouse
			end,
		}
	end

	---@param isInCombat boolean?
	---@return table tracker, table frame
	local function Load(isInCombat)
		local addon = {}
		local chunk = assert(loadfile("Source/Game/BlizzardTracker.lua"))

		chunk("AuraQuestor", addon)

		local frame = TrackerFrame()

		ObjectiveTrackerFrame = frame
		InCombatLockdown = function()
			return isInCombat == true
		end

		return addon.BlizzardTracker.New(), frame
	end

	T.Suite("BlizzardTracker", function()
		T.Test("esconder apaga a opacidade e tira o mouse", function()
			local tracker, frame = Load()

			tracker:SetHidden(true)

			T.Equals(frame.alpha, 0)
			T.Equals(frame.hasMouse, false)
		end)

		T.Test("esconde de novo depois que o jogo devolve a opacidade", function()
			local tracker, frame = Load()

			tracker:SetHidden(true)
			-- O que o contêiner da direita faz quando a UIParent volta.
			frame.alpha = 1
			frame.hasMouse = true
			tracker:SetHidden(true)

			T.Equals(frame.alpha, 0)
			T.Equals(frame.hasMouse, false)
		end)

		T.Test("mostrar de volta levanta o zero que pusemos", function()
			local tracker, frame = Load()

			tracker:SetHidden(true)
			tracker:SetHidden(false)

			T.Equals(frame.alpha, 1)
			T.Equals(frame.hasMouse, true)
		end)

		T.Test("mostrar de volta nao mexe numa opacidade que nao e nossa", function()
			local tracker, frame = Load()
			frame.alpha = 0.5

			tracker:SetHidden(false)

			T.Equals(frame.alpha, 0.5)
		end)

		T.Test("com os dois na tela, o zero do jogo continua de pe", function()
			local tracker, frame = Load()
			-- Sob barra de acao substituta o proprio jogo apaga o rastreador dele.
			frame.alpha = 0

			tracker:SetHidden(false)

			T.Equals(frame.alpha, 0, "so o zero que foi nosso e nosso para levantar")
		end)

		T.Test("em combate o mouse fica como esta", function()
			local tracker, frame = Load(true)

			tracker:SetHidden(true)

			T.Equals(frame.alpha, 0, "opacidade nao e protegida")
			T.Equals(frame.hasMouse, true, "EnableMouse e bloqueado no frame protegido")
		end)
	end)
end
