return function(Addon, T, Support)
	---@param values table
	---@return Preferences
	local function Preferences(values)
		return Addon.Preferences.New({}, values, function() end)
	end

	---@param providers SectionProvider[]
	---@param sortMode string?
	---@param values table?
	---@return TrackerContent
	local function Content(providers, sortMode, values)
		values = values or {}
		values.sortMode = sortMode or "none"

		return Addon.TrackerContent.New(providers, Addon.SortModes, Preferences(values))
	end

	T.Suite("TrackerContent", function()
		T.Test("secao vazia nao entra na lista", function()
			local sections = Content({
				Support.Provider("quests", 20, {}),
				Support.Provider("events", 35, { Support.Entry({}) }),
			}):Build()

			T.Equals(#sections, 1)
			T.Equals(sections[1].id, "events")
		end)

		T.Test("secoes saem na ordem declarada, nao na de registro", function()
			local sections = Content({
				Support.Provider("events", 35, { Support.Entry({}) }),
				Support.Provider("quests", 20, { Support.Entry({}) }),
			}):Build()

			T.Equals(sections[1].id, "quests")
			T.Equals(sections[2].id, "events")
		end)

		T.Test("a ordem escolhida pelo jogador manda na declarada", function()
			local sections = Content({
				Support.Provider("quests", 20, { Support.Entry({}) }),
				Support.Provider("events", 35, { Support.Entry({}) }),
				Support.Provider("achievements", 50, { Support.Entry({}) }),
			}, nil, { sectionArrangement = "achievements,events,quests" }):Build()

			T.Equals(sections[1].id, "achievements")
			T.Equals(sections[2].id, "events")
			T.Equals(sections[3].id, "quests")
		end)

		--- Sem nada guardado, e com uma string invalida, a ordem tem que ser a
		--- mesma de sempre: e o caminho de toda instalacao nova.
		T.Test("sem arrumacao guardada vale o SectionOrder", function()
			for _, stored in ipairs({ "", "naoExiste", "  ,  " }) do
				local sections = Content({
					Support.Provider("events", 35, { Support.Entry({}) }),
					Support.Provider("quests", 20, { Support.Entry({}) }),
				}, nil, { sectionArrangement = stored }):Build()

				T.Equals(sections[1].id, "quests", ("guardado %q"):format(stored))
				T.Equals(sections[2].id, "events", ("guardado %q"):format(stored))
			end
		end)

		T.Test("secao fora da arrumacao vai para o fim, sem embaralhar", function()
			local sections = Content({
				Support.Provider("quests", 20, { Support.Entry({}) }),
				Support.Provider("naoCatalogada", 99, { Support.Entry({}) }),
				Support.Provider("events", 35, { Support.Entry({}) }),
			}, nil, { sectionArrangement = "events,quests" }):Build()

			T.Equals(sections[1].id, "events")
			T.Equals(sections[2].id, "quests")
			T.Equals(sections[3].id, "naoCatalogada")
		end)

		T.Test("um provider pode alimentar mais de uma secao", function()
			local two = {
				Collect = function()
					return {
						Support.Section("campaign", 10, { Support.Entry({}) }),
						Support.Section("quests", 20, { Support.Entry({}) }),
					}
				end,
			}

			T.Equals(#Content({ two }):Build(), 2)
		end)

		T.Test("concluidas descem para o fim mantendo a ordem entre si", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "pronta A", isComplete = true }),
					Support.Entry({ id = 2, title = "aberta" }),
					Support.Entry({ id = 3, title = "pronta B", isComplete = true }),
				}),
			}):Build()[1].entries

			T.Equals(entries[1].title, "aberta")
			T.Equals(entries[2].title, "pronta A")
			T.Equals(entries[3].title, "pronta B")
		end)

		T.Test("com a preferencia ligada as concluidas sobem para o topo", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "pronta A", isComplete = true }),
					Support.Entry({ id = 2, title = "aberta" }),
					Support.Entry({ id = 3, title = "pronta B", isComplete = true }),
				}),
			}, nil, { completedAtTop = true }):Build()[1].entries

			T.Equals(entries[1].title, "pronta A")
			T.Equals(entries[2].title, "pronta B")
			T.Equals(entries[3].title, "aberta")
		end)

		T.Test("sem ordenacao a ordem da fonte e preservada", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "Zangado" }),
					Support.Entry({ id = 2, title = "Alegre" }),
				}),
			}):Build()[1].entries

			T.Equals(entries[1].title, "Zangado")
		end)

		T.Test("ordenacao por titulo vale dentro da secao", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "Zangado" }),
					Support.Entry({ id = 2, title = "Alegre" }),
				}),
			}, "title"):Build()[1].entries

			T.Equals(entries[1].title, "Alegre")
			T.Equals(entries[2].title, "Zangado")
		end)

		T.Test("ordenacao por nivel funciona igual", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "alto", level = 70 }),
					Support.Entry({ id = 2, title = "baixo", level = 10 }),
				}),
			}, "level"):Build()[1].entries

			T.Equals(entries[1].title, "baixo")
		end)

		T.Test("ordenacao por recencia poe a mais nova no topo", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "antiga", arrival = 1 }),
					Support.Entry({ id = 2, title = "nova", arrival = 9 }),
				}),
			}, "recent"):Build()[1].entries

			T.Equals(entries[1].title, "nova")
			T.Equals(entries[2].title, "antiga")
		end)

		T.Test("por recencia, o que nao tem chegada fica embaixo", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "conquista" }),
					Support.Entry({ id = 2, title = "missao", arrival = 3 }),
				}),
			}, "recent"):Build()[1].entries

			T.Equals(entries[1].title, "missao", "so missao tem chegada")
		end)

		T.Test("ordenar nao promove concluida acima de aberta", function()
			local entries = Content({
				Support.Provider("quests", 20, {
					Support.Entry({ id = 1, title = "Alegre", isComplete = true }),
					Support.Entry({ id = 2, title = "Zangado" }),
				}),
			}, "title"):Build()[1].entries

			T.Equals(entries[1].title, "Zangado", "a concluida desce mesmo vindo antes no alfabeto")
		end)

		T.Test("ordenacao desconhecida nao quebra a montagem", function()
			local sections = Addon.TrackerContent.New(
				{ Support.Provider("quests", 20, { Support.Entry({}) }) },
				Addon.SortModes,
				Preferences({ sortMode = "nao-existe" })
			):Build()

			T.Equals(#sections, 1)
		end)

		T.Test("sem provider nenhum devolve lista vazia", function()
			T.Equals(#Content({}):Build(), 0)
		end)
	end)
end
