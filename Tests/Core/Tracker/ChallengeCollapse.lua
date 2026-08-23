return function(Addon, T)
	local ChallengeCollapse = Addon.ChallengeCollapse

	---@param overrides table?
	---@return ChallengeCollapseState
	local function State(overrides)
		local state = {
			isEnabled = true,
			isChallengeActive = false,
			isCollapsed = false,
			isOurs = false,
		}

		for key, value in pairs(overrides or {}) do
			state[key] = value
		end

		return state
	end

	T.Suite("ChallengeCollapse", function()
		T.Test("comecar a chave recolhe", function()
			local action, isOurs = ChallengeCollapse.Decide(State({ isChallengeActive = true }))

			T.Equals(action, ChallengeCollapse.COLLAPSE)
			T.IsTrue(isOurs, "quem recolheu fomos nos, e isso precisa ficar anotado")
		end)

		T.Test("terminar a chave devolve a janela", function()
			local action, isOurs = ChallengeCollapse.Decide(State({
				isChallengeActive = false,
				isCollapsed = true,
				isOurs = true,
			}))

			T.Equals(action, ChallengeCollapse.EXPAND)
			T.IsTrue(not isOurs)
		end)

		T.Test("durante a chave nao fica repetindo o recolher", function()
			local action = ChallengeCollapse.Decide(State({
				isChallengeActive = true,
				isCollapsed = true,
				isOurs = true,
			}))

			T.Equals(action, nil)
		end)

		--- A regra que da sentido ao desenho: janela que o jogador ja tinha
		--- recolhido nao e nossa, entao o fim da chave nao pode abri-la.
		T.Test("janela ja recolhida antes da chave nao vira nossa", function()
			local action, isOurs = ChallengeCollapse.Decide(State({
				isChallengeActive = true,
				isCollapsed = true,
			}))

			T.Equals(action, nil)
			T.IsTrue(not isOurs)
		end)

		T.Test("abrir na mao durante a chave solta a janela para sempre", function()
			local _, isOurs = ChallengeCollapse.Decide(State({
				isChallengeActive = true,
				isCollapsed = false,
				isOurs = true,
			}))

			T.IsTrue(not isOurs, "o jogador assumiu, e o fim da chave nao mexe mais")
		end)

		T.Test("aberta na mao, o fim da chave nao faz nada", function()
			local action = ChallengeCollapse.Decide(State({
				isChallengeActive = false,
				isCollapsed = false,
				isOurs = false,
			}))

			T.Equals(action, nil)
		end)

		T.Test("desligar a opcao no meio da chave devolve a janela", function()
			local action, isOurs = ChallengeCollapse.Decide(State({
				isEnabled = false,
				isChallengeActive = true,
				isCollapsed = true,
				isOurs = true,
			}))

			T.Equals(action, ChallengeCollapse.EXPAND)
			T.IsTrue(not isOurs)
		end)

		T.Test("com a opcao desligada, chave nenhuma recolhe", function()
			local action = ChallengeCollapse.Decide(State({
				isEnabled = false,
				isChallengeActive = true,
			}))

			T.Equals(action, nil)
		end)
	end)
end
