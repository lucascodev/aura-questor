return function(Addon, T)
	---@return table
	local function Arrow()
		return {
			sent = {},
			clears = 0,
			SetWaypoint = function(self, target)
				table.insert(self.sent, target)
			end,
			Clear = function(self)
				self.clears = self.clears + 1
			end,
		}
	end

	--- Atribuir nil num construtor de tabela nao cria a chave, entao "sem
	--- posicao" precisa ser uma opcao explicita em vez de um override nil.
	---@param overrides table?
	---@return WaypointTarget
	local function Target(overrides)
		local target = { id = 10, kind = "quest", uiMapID = 84, x = 0.5, y = 0.5, title = "Alvo" }

		for key, value in pairs(overrides or {}) do
			target[key] = value
		end

		if target.noPosition then
			target.noPosition = nil
			target.x = nil
			target.y = nil
		end

		return target
	end

	---@param options table?
	---@return table
	local function Build(options)
		options = options or {}

		local state = {
			arrow = Arrow(),
			target = options.target,
			enabled = options.enabled ~= false,
		}

		state.sync = Addon.WaypointSync.New(function()
			return state.target
		end, state.arrow, function()
			return state.enabled
		end)

		return state
	end

	T.Suite("WaypointSync", function()
		T.Test("alvo novo vira waypoint", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 1)
			T.Equals(built.arrow.sent[1].id, 10)
		end)

		T.Test("sem alvo nada acontece", function()
			local built = Build()
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 0)
			T.Equals(built.arrow.clears, 0)
		end)

		T.Test("mesmo lugar nao reenvia", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = Target({ x = 0.5001, y = 0.4999 })
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 1)
		end)

		T.Test("deriva alem da tolerancia reenvia", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = Target({ x = 0.6 })
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 2)
		end)

		T.Test("perder o alvo limpa uma vez so", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = nil
			built.sync:Sync()
			built.sync:Sync()

			T.Equals(built.arrow.clears, 1)
		end)

		T.Test("alvo sem posicao com o mesmo id mantem a seta", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = Target({ noPosition = true })
			built.sync:Sync()

			T.Equals(built.arrow.clears, 0)
			T.Equals(#built.arrow.sent, 1)
		end)

		T.Test("alvo sem posicao com id novo limpa", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = Target({ id = 99, noPosition = true })
			built.sync:Sync()

			T.Equals(built.arrow.clears, 1)
		end)

		T.Test("desligar limpa e para de enviar", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.enabled = false
			built.sync:Sync()
			built.sync:Sync()

			T.Equals(built.arrow.clears, 1)
			T.Equals(#built.arrow.sent, 1)
		end)

		T.Test("religar reenvia o alvo atual", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.enabled = false
			built.sync:Sync()

			built.enabled = true
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 2)
		end)

		T.Test("a posicao que chega depois substitui a antiga", function()
			local built = Build({ target = Target() })
			built.sync:Sync()

			built.target = Target({ noPosition = true })
			built.sync:Sync()

			built.target = Target({ x = 0.7, y = 0.7 })
			built.sync:Sync()

			T.Equals(#built.arrow.sent, 2)
			T.Near(built.arrow.sent[2].x, 0.7, 0.0001)
		end)
	end)
end
