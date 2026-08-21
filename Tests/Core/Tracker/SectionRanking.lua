return function(Addon, T)
	local Ranking = Addon.SectionRanking
	local DEFAULTS = { scenario = 5, quests = 20, events = 35 }

	T.Suite("SectionRanking", function()
		T.Test("a ordem de fabrica sai na ordem declarada", function()
			local order = Ranking.FromDefaults(DEFAULTS)

			T.Equals(order[1], "scenario")
			T.Equals(order[2], "quests")
			T.Equals(order[3], "events")
		end)

		T.Test("secao arranjada vale pela posicao na lista", function()
			local order = { "events", "quests" }

			T.IsTrue(Ranking.Rank(order, "events", 35) < Ranking.Rank(order, "quests", 20))
		end)

		T.Test("secao fora da lista fica depois das arranjadas", function()
			local order = { "events" }

			T.IsTrue(Ranking.Rank(order, "events", 35) < Ranking.Rank(order, "quests", 20))
		end)

		T.Test("entre duas fora da lista vale a ordem de nascimento", function()
			local order = {}

			T.IsTrue(Ranking.Rank(order, "scenario", 5) < Ranking.Rank(order, "quests", 20))
		end)

		T.Test("mover troca com o vizinho", function()
			local order = { "scenario", "quests", "events" }

			T.Equals(Ranking.Move(order, "quests", -1), true)
			T.Equals(order[1], "quests")
			T.Equals(order[2], "scenario")
		end)

		T.Test("nas pontas nao ha para onde ir", function()
			local order = { "scenario", "quests" }

			T.Equals(Ranking.Move(order, "scenario", -1), false)
			T.Equals(Ranking.Move(order, "quests", 1), false)
			T.Equals(order[1], "scenario")
		end)

		T.Test("secao que nao esta na lista nao se move", function()
			local order = { "scenario" }

			T.Equals(Ranking.Move(order, "quests", -1), false)
		end)
	end)
end
