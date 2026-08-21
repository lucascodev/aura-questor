return function(Addon, T)
	local Arrangement = Addon.SectionArrangement

	--- Um padrao pequeno e estavel, para os testes nao quebrarem quando uma
	--- secao nova entrar em SectionOrder.
	local DEFAULTS = {
		scenario = 5,
		quests = 20,
		worldQuests = 30,
		achievements = 50,
	}

	---@param ids string[]
	---@return string
	local function Joined(ids)
		return table.concat(ids, ",")
	end

	T.Suite("SectionArrangement", function()
		T.Test("texto vazio ou ausente nao vira secao nenhuma", function()
			T.Equals(#Arrangement.Parse(nil), 0)
			T.Equals(#Arrangement.Parse(""), 0)
			T.Equals(#Arrangement.Parse(",,,"), 0)
		end)

		T.Test("le a lista separada por virgula", function()
			T.Equals(Joined(Arrangement.Parse("quests,scenario")), "quests,scenario")
		end)

		T.Test("ignora espaco em volta de cada id", function()
			T.Equals(Joined(Arrangement.Parse(" quests , scenario ")), "quests,scenario")
		end)

		T.Test("id repetido conta uma vez, valendo a primeira posicao", function()
			T.Equals(Joined(Arrangement.Parse("quests,scenario,quests")), "quests,scenario")
		end)

		T.Test("serializar e ler de volta devolve a mesma lista", function()
			local ids = { "worldQuests", "quests", "scenario" }

			T.Equals(Joined(Arrangement.Parse(Arrangement.Serialize(ids))), Joined(ids))
		end)

		T.Test("sem nada guardado a ordem e a padrao", function()
			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, nil)),
				"scenario,quests,worldQuests,achievements"
			)
		end)

		T.Test("a ordem guardada e respeitada", function()
			local stored = { "achievements", "quests", "worldQuests", "scenario" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"achievements,quests,worldQuests,scenario"
			)
		end)

		T.Test("id desconhecido guardado e descartado", function()
			local stored = { "quests", "petTracker", "scenario", "worldQuests", "achievements" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"quests,scenario,worldQuests,achievements"
			)
		end)

		--- O caso que decide o desenho: uma versao nova acrescenta uma secao, e
		--- a lista que o jogador salvou nao a conhece.
		T.Test("secao nova cai na vizinhanca padrao, nao no fim", function()
			local stored = { "scenario", "quests", "achievements" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"scenario,quests,worldQuests,achievements"
			)
		end)

		T.Test("secao nova de posicao baixa entra no comeco", function()
			local stored = { "quests", "worldQuests", "achievements" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"scenario,quests,worldQuests,achievements"
			)
		end)

		T.Test("secao nova de posicao alta entra no fim", function()
			local stored = { "scenario", "quests", "worldQuests" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"scenario,quests,worldQuests,achievements"
			)
		end)

		T.Test("toda secao conhecida aparece uma unica vez", function()
			local stored = { "achievements", "achievements", "naoExiste" }
			local sequence = Arrangement.Sequence(DEFAULTS, stored)
			local seen = {}

			for _, id in ipairs(sequence) do
				T.IsTrue(not seen[id], id .. " aparece duas vezes")
				seen[id] = true
			end

			for id in pairs(DEFAULTS) do
				T.IsTrue(seen[id], id .. " sumiu da sequencia")
			end
		end)

		--- O caso que reprovou a primeira versao do algoritmo: com conquistas
		--- puxadas para o topo, a secao nova tem que pousar ao lado do vizinho
		--- padrao dela, nao roubar o primeiro lugar so por desempatar por numero.
		T.Test("secao nova nao rouba o topo de uma lista rearranjada", function()
			local stored = { "achievements", "scenario", "quests" }

			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, stored)),
				"achievements,scenario,quests,worldQuests"
			)
		end)

		--- Duas secoes que o jogador deixou coladas continuam coladas depois de
		--- uma atualizacao acrescentar outras duas no meio do caminho.
		T.Test("secao nova nao se enfia entre duas que ficaram lado a lado", function()
			T.Equals(
				Joined(Arrangement.Sequence(DEFAULTS, { "worldQuests", "quests" })),
				"scenario,worldQuests,quests,achievements"
			)
		end)

		T.Test("as posicoes saem em 1..n, sem buraco", function()
			local ranks = Arrangement.Resolve(DEFAULTS, { "worldQuests", "quests" })
			local taken = {}

			for _, rank in pairs(ranks) do
				T.IsTrue(not taken[rank], "duas secoes na posicao " .. rank)
				taken[rank] = true
			end

			for index = 1, 4 do
				T.IsTrue(taken[index], "posicao " .. index .. " vazia")
			end

			T.IsTrue(ranks.worldQuests < ranks.quests, "a ordem guardada nao foi respeitada")
		end)

		T.Test("subir troca com a de cima", function()
			local moved, changed = Arrangement.Move({ "a", "b", "c" }, "b", -1)

			T.IsTrue(changed)
			T.Equals(Joined(moved), "b,a,c")
		end)

		T.Test("descer troca com a de baixo", function()
			local moved, changed = Arrangement.Move({ "a", "b", "c" }, "b", 1)

			T.IsTrue(changed)
			T.Equals(Joined(moved), "a,c,b")
		end)

		T.Test("nas pontas nao sai do lugar", function()
			local top, movedTop = Arrangement.Move({ "a", "b" }, "a", -1)
			local bottom, movedBottom = Arrangement.Move({ "a", "b" }, "b", 1)

			T.IsTrue(not movedTop)
			T.IsTrue(not movedBottom)
			T.Equals(Joined(top), "a,b")
			T.Equals(Joined(bottom), "a,b")
		end)

		T.Test("mover id que nao esta na lista nao faz nada", function()
			local moved, changed = Arrangement.Move({ "a", "b" }, "z", 1)

			T.IsTrue(not changed)
			T.Equals(Joined(moved), "a,b")
		end)

		T.Test("mover nao altera a lista recebida", function()
			local original = { "a", "b", "c" }
			Arrangement.Move(original, "a", 1)

			T.Equals(Joined(original), "a,b,c")
		end)

		T.Test("sem nada guardado a ordem conta como padrao", function()
			T.IsTrue(Arrangement.IsDefault(DEFAULTS, nil))
			T.IsTrue(Arrangement.IsDefault(DEFAULTS, {}))
			T.IsTrue(
				Arrangement.IsDefault(DEFAULTS, { "scenario", "quests", "worldQuests", "achievements" })
			)
		end)

		T.Test("qualquer troca deixa de ser padrao", function()
			T.IsTrue(not Arrangement.IsDefault(DEFAULTS, { "quests", "scenario" }))
		end)

		T.Test("funciona com o SectionOrder de verdade", function()
			local sequence = Arrangement.Sequence(Addon.SectionOrder, nil)
			local count = 0

			for _ in pairs(Addon.SectionOrder) do
				count = count + 1
			end

			T.Equals(#sequence, count)
			T.Equals(sequence[1], "scenario")
			T.Equals(sequence[#sequence], "initiativeTasks")
		end)
	end)
end
