return function(Addon, T)
	local function ListTwo()
		return { { id = 1, name = "Um" }, { id = 2, name = "Dois" } }
	end

	T.Suite("AchievementCategories", function()
		T.Test("tudo visivel por padrao", function()
			local categories = Addon.AchievementCategories.New({}, ListTwo, function() end)

			T.IsTrue(categories:IsShown(1))
			T.IsTrue(categories:IsShown(2))
		end)

		T.Test("alternar esconde e mostra de volta", function()
			local hidden = {}
			local categories = Addon.AchievementCategories.New(hidden, ListTwo, function() end)

			categories:Toggle(1)
			T.IsTrue(not categories:IsShown(1))
			T.IsTrue(categories:IsShown(2), "a outra nao deveria ser afetada")

			categories:Toggle(1)
			T.IsTrue(categories:IsShown(1))
			T.Equals(next(hidden), nil, "o conjunto deveria voltar a ficar vazio")
		end)

		T.Test("desmarcar todas esconde cada uma da lista", function()
			local hidden = {}
			local categories = Addon.AchievementCategories.New(hidden, ListTwo, function() end)

			categories:ShowAll(false)
			T.IsTrue(not categories:IsShown(1))
			T.IsTrue(not categories:IsShown(2))

			categories:ShowAll(true)
			T.Equals(next(hidden), nil)
		end)

		T.Test("cada mudanca avisa uma vez", function()
			local changes = 0
			local categories = Addon.AchievementCategories.New({}, ListTwo, function()
				changes = changes + 1
			end)

			categories:Toggle(1)
			categories:ShowAll(false)

			T.Equals(changes, 2)
		end)

		T.Test("a lista e repassada sem alteracao", function()
			local categories = Addon.AchievementCategories.New({}, ListTwo, function() end)

			T.Equals(#categories:List(), 2)
		end)
	end)
end
