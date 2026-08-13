return function(Addon, T)
	T.Suite("Preferences", function()
		T.Test("preenche o que falta com o padrao", function()
			local values = {}
			Addon.Preferences.New({ { key = "fontSize", default = 12 } }, values, function() end)

			T.Equals(values.fontSize, 12)
		end)

		T.Test("nao sobrescreve valor ja guardado", function()
			local values = { fontSize = 20 }
			Addon.Preferences.New({ { key = "fontSize", default = 12 } }, values, function() end)

			T.Equals(values.fontSize, 20)
		end)

		T.Test("preenche tambem um padrao falso", function()
			local values = {}
			Addon.Preferences.New({ { key = "editMode", default = false } }, values, function() end)

			T.Equals(values.editMode, false)
		end)

		T.Test("avisa ao mudar e cala quando o valor e o mesmo", function()
			local changes = 0
			local preferences = Addon.Preferences.New({}, {}, function()
				changes = changes + 1
			end)

			preferences:Set("fontSize", 14)
			T.Equals(changes, 1)

			preferences:Set("fontSize", 14)
			T.Equals(changes, 1, "valor igual nao deveria avisar")

			preferences:Set("fontSize", 16)
			T.Equals(changes, 2)
		end)

		T.Test("avisa qual chave mudou", function()
			local changed
			local preferences = Addon.Preferences.New({}, {}, function(key)
				changed = key
			end)

			preferences:Set("fontName", "Arial")
			T.Equals(changed, "fontName")
		end)

		T.Test("Notify avisa sem escrever nada", function()
			local changes = 0
			local values = {}
			local preferences = Addon.Preferences.New({}, values, function()
				changes = changes + 1
			end)

			preferences:Notify("fontSize")

			T.Equals(changes, 1)
			T.Equals(values.fontSize, nil)
		end)

		T.Test("Values devolve a tabela viva, nao uma copia", function()
			local values = {}
			local preferences = Addon.Preferences.New({}, values, function() end)

			preferences:Set("fontSize", 18)

			T.Equals(preferences:Values(), values)
			T.Equals(values.fontSize, 18)
		end)
	end)
end
