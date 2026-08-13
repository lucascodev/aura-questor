return function(Addon, T)
	T.Suite("SectionOrder", function()
		T.Test("cenario vem antes de missoes, que vem antes de conquistas", function()
			T.IsTrue(Addon.SectionOrder.scenario < Addon.SectionOrder.quests)
			T.IsTrue(Addon.SectionOrder.quests < Addon.SectionOrder.achievements)
		end)

		T.Test("campanha vem antes das demais missoes", function()
			T.IsTrue(Addon.SectionOrder.campaign < Addon.SectionOrder.quests)
		end)

		T.Test("nenhuma secao divide a mesma posicao", function()
			local seen = {}

			for id, order in pairs(Addon.SectionOrder) do
				T.IsTrue(
					seen[order] == nil,
					("%s e %s empatam em %d"):format(id, tostring(seen[order]), order)
				)
				seen[order] = id
			end
		end)

		T.Test("toda posicao e um numero", function()
			for id, order in pairs(Addon.SectionOrder) do
				T.IsTrue(type(order) == "number", id .. " nao tem posicao numerica")
			end
		end)
	end)
end
