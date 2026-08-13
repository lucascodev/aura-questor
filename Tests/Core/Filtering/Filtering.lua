return function(Addon, T, Support)
	local Ids = Addon.QuestFilterIds

	---@param overrides table?
	---@return Quest
	local function Quest(overrides)
		local quest = {
			questID = 1,
			title = "Missão",
			isOnCurrentMap = false,
			isCampaign = false,
			isRecurring = false,
			isInstance = false,
			isComplete = false,
		}

		for key, value in pairs(overrides or {}) do
			quest[key] = value
		end

		return quest
	end

	---@param quests Quest[]
	---@param refuseAfter number?
	---@return QuestFiltering, table source, table logger
	local function Build(quests, refuseAfter)
		local source = Support.QuestSource(quests, refuseAfter)
		local logger = Support.Logger()

		return Addon.QuestFiltering.New(source, Addon.QuestFilters, logger), source, logger
	end

	T.Suite("QuestFiltering", function()
		T.Test("aplicar reescreve a lista inteira, ligando e desligando", function()
			local filtering, source = Build({
				Quest({ questID = 1, isCampaign = true }),
				Quest({ questID = 2, isCampaign = false }),
			})

			filtering:Apply(Ids.CAMPAIGN)

			T.Equals(#source.calls, 2, "toda missão precisa ser decidida")
			T.Equals(source.calls[1].isWatched, true)
			T.Equals(source.calls[2].isWatched, false)
		end)

		T.Test("parar de rastrear tudo desliga todas", function()
			local filtering, source = Build({
				Quest({ questID = 1, isCampaign = true }),
				Quest({ questID = 2 }),
			})

			filtering:UntrackAll()

			for _, call in ipairs(source.calls) do
				T.Equals(call.isWatched, false)
			end
		end)

		T.Test("aplicar por agrupamento usa o nome do grupo", function()
			local filtering, source = Build({
				Quest({ questID = 1, groupName = "Valdrakken" }),
				Quest({ questID = 2, groupName = "Thaldraszus" }),
			})

			filtering:ApplyGroup("Valdrakken")

			T.Equals(source.calls[1].isWatched, true)
			T.Equals(source.calls[2].isWatched, false)
		end)

		T.Test("filtro desconhecido avisa e nao mexe na lista", function()
			local filtering, source, logger = Build({ Quest({}) })

			filtering:Apply("nao-existe")

			T.Equals(#source.calls, 0, "nada deveria ter sido reescrito")
			T.Equals(#logger.warnings, 1)
		end)

		T.Test("recusa do jogo vira um aviso com a contagem", function()
			local filtering, _, logger = Build({
				Quest({ questID = 1, isCampaign = true }),
				Quest({ questID = 2, isCampaign = true }),
				Quest({ questID = 3, isCampaign = true }),
			}, 1)

			filtering:Apply(Ids.CAMPAIGN)

			T.Equals(#logger.warnings, 1)
			T.IsTrue(
				logger.warnings[1]:find("2") ~= nil,
				"o aviso deveria dizer quantas ficaram de fora"
			)
		end)

		T.Test("sem recusa nenhuma nao ha aviso", function()
			local filtering, _, logger = Build({ Quest({ isCampaign = true }) })

			filtering:Apply(Ids.CAMPAIGN)

			T.Equals(#logger.warnings, 0)
		end)

		T.Test("contagem responde por todos os filtros", function()
			local filtering = Build({
				Quest({ questID = 1, isCampaign = true }),
				Quest({ questID = 2, isComplete = true }),
				Quest({ questID = 3 }),
			})

			local counts = filtering:Counts()

			T.Equals(counts[Ids.ALL], 3)
			T.Equals(counts[Ids.CAMPAIGN], 1)
			T.Equals(counts[Ids.COMPLETE], 1)
			T.Equals(counts[Ids.UNFINISHED], 2)
		end)

		T.Test("grupos vem na ordem do diario, sem repetir", function()
			local filtering = Build({
				Quest({ questID = 1, groupName = "Valdrakken" }),
				Quest({ questID = 2, groupName = "Thaldraszus" }),
				Quest({ questID = 3, groupName = "Valdrakken" }),
			})

			local groups = filtering:Groups()

			T.Equals(#groups, 2)
			T.Equals(groups[1].name, "Valdrakken")
			T.Equals(groups[1].count, 2)
			T.Equals(groups[2].name, "Thaldraszus")
			T.Equals(groups[2].count, 1)
		end)

		T.Test("missao sem grupo fica fora da lista de grupos", function()
			local filtering = Build({ Quest({ questID = 1 }) })

			T.Equals(#filtering:Groups(), 0)
		end)
	end)
end
