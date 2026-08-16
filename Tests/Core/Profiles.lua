return function(Addon, T)
	local DEFAULT = "Default"
	local CHARACTER = "Inpuro - Azralon"
	local OTHER = "Outro - Azralon"

	---@param database table?
	---@return Profiles
	local function Build(database)
		return Addon.Profiles.New(database or {}, CHARACTER)
	end

	T.Suite("Profiles", function()
		T.Test("instalacao nova ganha um perfil padrao", function()
			local profiles = Build()

			T.IsTrue(profiles:Current() ~= nil)
			T.Equals(#profiles:Names(), 1)
		end)

		T.Test("o perfil novo vem com as tabelas que o addon espera", function()
			local profile = Build():Current()

			for _, name in ipairs({
				"settings",
				"ownTrackerPosition",
				"ownTrackerState",
				"collapsedSections",
				"hiddenCategories",
				"hiddenSections",
				"minimapButton",
			}) do
				T.Equals(type(profile[name]), "table", name .. " deveria existir")
			end
		end)

		T.Test("perfil de versao anterior ganha as tabelas novas ao ser lido", function()
			local database = {
				profiles = { [DEFAULT] = { settings = { fontSize = 18 }, collapsedSections = { quests = true } } },
				characters = {},
			}
			local profile = Build(database):Current()

			T.Equals(type(profile.ownTrackerState), "table")
			T.Equals(profile.settings.fontSize, 18)
			T.IsTrue(profile.collapsedSections.quests)
		end)

		T.Test("criar e selecionar troca o perfil em uso", function()
			local profiles = Build()
			profiles:Create("Alternativo")
			profiles:Select("Alternativo")

			T.Equals(profiles:CurrentName(), "Alternativo")
			T.Equals(#profiles:Names(), 2)
		end)

		T.Test("os nomes saem em ordem alfabetica", function()
			local profiles = Build()
			profiles:Create("Zebra")
			profiles:Create("Abacaxi")

			local names = profiles:Names()

			T.Equals(names[1], "Abacaxi")
			T.IsTrue(names[#names] == "Zebra")
		end)

		T.Test("perfis nao compartilham configuracao", function()
			local profiles = Build()
			profiles:Current().settings.fontSize = 18
			profiles:Create("Limpo")
			profiles:Select("Limpo")

			T.Equals(profiles:Current().settings.fontSize, nil)
		end)

		T.Test("copiar leva as configuracoes junto", function()
			local profiles = Build()
			profiles:Current().settings.fontSize = 18
			profiles:CopyCurrentTo("Copia")
			profiles:Select("Copia")

			T.Equals(profiles:Current().settings.fontSize, 18)
		end)

		T.Test("a copia e independente do original", function()
			local profiles = Build()
			profiles:Current().settings.fontSize = 18
			profiles:CopyCurrentTo("Copia")
			profiles:Select("Copia")
			profiles:Current().settings.fontSize = 30
			profiles:Select(DEFAULT)

			T.Equals(profiles:Current().settings.fontSize, 18, "o original foi alterado junto")
		end)

		T.Test("o perfil em uso nao pode ser apagado", function()
			local profiles = Build()

			T.IsTrue(not profiles:Delete(profiles:CurrentName()))
		end)

		T.Test("apagar um perfil solta os personagens que o usavam", function()
			local database = {}
			local profiles = Addon.Profiles.New(database, CHARACTER)
			profiles:Create("Descartavel")
			database.characters[OTHER] = "Descartavel"

			T.IsTrue(profiles:Delete("Descartavel"))
			T.Equals(database.characters[OTHER], nil)
		end)

		T.Test("personagem apontado para um perfil apagado ganha um novo", function()
			local database = { profiles = {}, characters = { [CHARACTER] = "Sumiu" } }
			local profiles = Addon.Profiles.New(database, CHARACTER)

			T.IsTrue(profiles:Current() ~= nil, "deveria criar em vez de errar")
		end)

		T.Test("importar completa as tabelas que faltam", function()
			local profiles = Build()
			profiles:Import("Importado", { settings = { fontSize = 22 } })
			profiles:Select("Importado")

			local profile = profiles:Current()

			T.Equals(profile.settings.fontSize, 22)
			T.Equals(type(profile.hiddenSections), "table", "tabela ausente deveria ser criada")
		end)

		T.Test("importar sobre um nome existente substitui", function()
			local profiles = Build()
			profiles:Create("Alvo")
			profiles:Import("Alvo", { settings = { fontSize = 9 } })
			profiles:Select("Alvo")

			T.Equals(profiles:Current().settings.fontSize, 9)
		end)

		T.Test("migracao levanta as configuracoes soltas da raiz", function()
			local database = {
				fontSize = 16,
				editMode = true,
				hiddenSections = { events = true },
			}
			local profiles = Addon.Profiles.New(database, CHARACTER)
			local profile = profiles:Current()

			T.Equals(profile.settings.fontSize, 16)
			T.Equals(profile.settings.editMode, true)
			T.Equals(profile.hiddenSections.events, true, "as tabelas nomeadas vao para o lugar certo")
			T.Equals(database.fontSize, nil, "a raiz deveria ter sido limpa")
		end)

		T.Test("o nome do perfil padrao nao depende do idioma", function()
			T.Equals(
				Build():CurrentName(),
				DEFAULT,
				"traduzir esse nome faria o perfil sumir ao trocar o idioma do cliente"
			)
		end)

		T.Test("perfil com o nome antigo traduzido e renomeado sem perder nada", function()
			local database = {
				profiles = { ["Padrão"] = { settings = { fontSize = 16 } } },
				characters = { [OTHER] = "Padrão" },
			}
			local profiles = Addon.Profiles.New(database, CHARACTER)

			T.Equals(database.profiles["Padrão"], nil, "o nome antigo deveria sair")
			T.Equals(profiles:Current().settings.fontSize, 16, "as configuracoes seguem junto")
			T.Equals(database.characters[OTHER], DEFAULT, "quem apontava para ele acompanha")
		end)

		T.Test("renomear nao sobrescreve um padrao que ja existe", function()
			local database = {
				profiles = {
					[DEFAULT] = { settings = { fontSize = 1 } },
					["Padrão"] = { settings = { fontSize = 2 } },
				},
				characters = {},
			}
			Addon.Profiles.New(database, CHARACTER)

			T.Equals(database.profiles[DEFAULT].settings.fontSize, 1)
			T.Equals(database.profiles["Padrão"].settings.fontSize, 2, "o outro segue intacto")
		end)

		T.Test("migracao nao roda de novo sobre um banco ja migrado", function()
			local database = { fontSize = 16 }
			Addon.Profiles.New(database, CHARACTER)
			database.profiles[DEFAULT].settings.fontSize = 24
			Addon.Profiles.New(database, CHARACTER)

			T.Equals(database.profiles[DEFAULT].settings.fontSize, 24)
		end)
	end)
end
