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

	--- O gerenciador do jogo, com um container e dois modulos pendurados nele.
	---@return table manager, table container
	local function Manager()
		local container = { modules = {} }

		function container:RemoveModule(module)
			for index, current in ipairs(self.modules) do
				if current == module then
					table.remove(self.modules, index)
					return
				end
			end
		end

		local manager = { moduleToContainerMap = {}, containers = { [container] = true } }

		--- Como no jogo: sair do container nao apaga o registro do gerenciador.
		function manager:SetModuleContainer(module, target)
			self.moduleToContainerMap[module] = target

			for _, current in ipairs(target.modules) do
				if current == module then
					return
				end
			end

			table.insert(target.modules, module)
		end

		manager:SetModuleContainer({ name = "missoes" }, container)
		manager:SetModuleContainer({ name = "cenario" }, container)

		return manager, container
	end

	---@param isInCombat boolean?
	---@return table tracker, table frame, table container
	local function Load(isInCombat)
		local addon = {}
		local chunk = assert(loadfile("Source/Game/BlizzardTracker.lua"))

		chunk("AuraQuestor", addon)

		local frame = TrackerFrame()
		local manager, container = Manager()

		ObjectiveTrackerFrame = frame
		ObjectiveTrackerManager = manager
		InCombatLockdown = function()
			return isInCombat == true
		end

		return addon.BlizzardTracker.New(), frame, container
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

		--- O erro que apareceu numa mitica: invisivel, o rastreador do jogo
		--- continuava montando blocos, e essa montagem le aura, que dentro de
		--- instancia o cliente recusa entregar a codigo que um addon encostou.
		T.Test("escondido, os modulos saem do container", function()
			local tracker, _, container = Load()

			tracker:SetHidden(true)

			T.Equals(#container.modules, 0)
		end)

		T.Test("mostrar de volta devolve os modulos", function()
			local tracker, _, container = Load()

			tracker:SetHidden(true)
			tracker:SetHidden(false)

			T.Equals(#container.modules, 2)
		end)

		T.Test("modulo que o jogo devolveu sai de novo", function()
			local tracker, _, container = Load()

			tracker:SetHidden(true)
			table.insert(container.modules, { name = "voltou" })
			tracker:SetHidden(true)

			T.Equals(#container.modules, 0)
		end)

		T.Test("esconder duas vezes nao duplica na volta", function()
			local tracker, _, container = Load()

			tracker:SetHidden(true)
			tracker:SetHidden(true)
			tracker:SetHidden(false)

			T.Equals(#container.modules, 2)
		end)

		T.Test("em combate os modulos ficam onde estao", function()
			local tracker, _, container = Load(true)

			tracker:SetHidden(true)

			T.Equals(#container.modules, 2, "mexer no frame protegido e bloqueado")
		end)

		T.Test("sem o gerenciador do jogo, nada estoura", function()
			local tracker = Load()
			ObjectiveTrackerManager = nil

			tracker:SetHidden(true)
			tracker:SetHidden(false)
		end)
	end)
end
