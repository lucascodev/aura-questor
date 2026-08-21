return function(Addon, T)
	local Labels = Addon.SectionOrderCard.Labels

	T.Suite("SectionOrderCard", function()
		--- A lista de reordenar mostra o id cru quando falta rotulo, e isso so
		--- apareceria no cliente. Aqui falha antes.
		T.Test("toda secao tem uma global de rotulo", function()
			for id in pairs(Addon.SectionOrder) do
				local global = Labels[id]

				T.IsTrue(
					type(global) == "string" and global ~= "",
					id .. " nao tem rotulo em SectionOrderCard.Labels"
				)
			end
		end)

		T.Test("nenhum rotulo sobra para secao que nao existe mais", function()
			for id in pairs(Labels) do
				T.IsTrue(
					Addon.SectionOrder[id] ~= nil,
					id .. " tem rotulo mas nao esta em SectionOrder"
				)
			end
		end)

		T.Test("o nome da global e maiusculo, como as do cliente", function()
			for id, global in pairs(Labels) do
				T.IsTrue(
					global:match("^[A-Z][A-Z0-9_]*$") ~= nil,
					("%s aponta para %q, que nao parece uma global do cliente"):format(id, global)
				)
			end
		end)
	end)
end
