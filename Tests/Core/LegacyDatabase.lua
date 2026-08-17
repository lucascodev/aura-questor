return function(Addon, T)
	local Resolve = Addon.LegacyDatabase.Resolve

	T.Suite("LegacyDatabase", function()
		T.Test("banco novo com conteudo prevalece sobre o antigo", function()
			local current = { profiles = { Default = {} } }
			local legacy = { profiles = { Old = {} } }

			local database, adopted = Resolve(current, legacy)

			T.IsTrue(database == current)
			T.Equals(adopted, false)
		end)

		T.Test("banco novo vazio adota o antigo por referencia", function()
			local legacy = { profiles = { Old = {} } }

			local database, adopted = Resolve({}, legacy)

			T.IsTrue(database == legacy)
			T.IsTrue(adopted)
		end)

		T.Test("sem banco novo e com ponte carregada adota o antigo", function()
			local legacy = { fontSize = 14 }

			local database, adopted = Resolve(nil, legacy)

			T.IsTrue(database == legacy)
			T.IsTrue(adopted)
		end)

		T.Test("sem nenhum dos dois nasce uma tabela vazia", function()
			local database, adopted = Resolve(nil, nil)

			T.Equals(type(database), "table")
			T.Equals(next(database), nil)
			T.Equals(adopted, false)
		end)
	end)
end
