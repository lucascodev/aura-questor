return function(Addon, T)
	T.Suite("ToggleSet", function()
		T.Test("liga guardando a chave e desliga apagando", function()
			local set = {}

			Addon.ToggleSet.Toggle(set, "quests")
			T.Equals(set.quests, true)

			Addon.ToggleSet.Toggle(set, "quests")
			T.Equals(set.quests, nil)
		end)

		T.Test("chaves diferentes nao interferem", function()
			local set = {}

			Addon.ToggleSet.Toggle(set, "a")
			Addon.ToggleSet.Toggle(set, "b")
			Addon.ToggleSet.Toggle(set, "a")

			T.Equals(set.a, nil)
			T.Equals(set.b, true)
		end)

		T.Test("limpar esvazia o conjunto", function()
			local set = { a = true, b = true }
			Addon.ToggleSet.Clear(set)

			T.Equals(next(set), nil)
		end)
	end)
end
