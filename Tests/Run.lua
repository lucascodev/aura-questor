local Harness = dofile("Tests/Harness.lua")

local Addon = Harness.LoadCore()

local Suite, Test = Harness.Suite, Harness.Test
local Equals, IsTrue, Near = Harness.Equals, Harness.IsTrue, Harness.Near

---@param overrides table?
---@return table
local function Entry(overrides)
	local entry = {
		id = 1,
		kind = "quest",
		title = "Uma missão",
		objectives = {},
		isComplete = false,
		canFindGroup = false,
	}

	for key, value in pairs(overrides or {}) do
		entry[key] = value
	end

	return entry
end

---@param id string
---@return QuestFilter
local function FilterById(id)
	for _, filter in ipairs(Addon.QuestFilters) do
		if filter.id == id then
			return filter
		end
	end

	error("filtro desconhecido: " .. id)
end

---@param id string
---@return SortMode
local function SortModeById(id)
	for _, mode in ipairs(Addon.SortModes) do
		if mode.id == id then
			return mode
		end
	end

	error("ordenação desconhecida: " .. id)
end

Suite("HexColor", function()
	Test("ida e volta preserva a cor", function()
		local red, green, blue = Addon.HexColor.ToRGB("EDC200")
		Equals(Addon.HexColor.FromRGB(red, green, blue), "EDC200")
	end)

	Test("branco e preto nos extremos", function()
		local red, green, blue = Addon.HexColor.ToRGB("FFFFFF")
		Equals(red, 1)
		Equals(green, 1)
		Equals(blue, 1)
		Equals(Addon.HexColor.FromRGB(0, 0, 0), "000000")
	end)

	Test("canal ilegivel vira zero em vez de nil", function()
		local red, green, blue = Addon.HexColor.ToRGB("zzzzzz")
		Equals(red, 0)
		Equals(green, 0)
		Equals(blue, 0)
	end)

	Test("meio caminho fica proximo de 0.5", function()
		local red = Addon.HexColor.ToRGB("808080")
		Near(red, 0.5, 0.01)
	end)
end)

Suite("ToggleSet", function()
	Test("liga guardando a chave e desliga apagando", function()
		local set = {}

		Addon.ToggleSet.Toggle(set, "quests")
		Equals(set.quests, true)

		Addon.ToggleSet.Toggle(set, "quests")
		Equals(set.quests, nil)
	end)

	Test("limpar esvazia o conjunto", function()
		local set = { a = true, b = true }
		Addon.ToggleSet.Clear(set)

		Equals(next(set), nil)
	end)
end)

Suite("QuestFilters", function()
	Test("todas aceita qualquer missão", function()
		IsTrue(FilterById(Addon.QuestFilterIds.ALL).matches({}))
	end)

	Test("zona atual olha apenas o mapa", function()
		local filter = FilterById(Addon.QuestFilterIds.ZONE)

		IsTrue(filter.matches({ isOnCurrentMap = true }))
		IsTrue(not filter.matches({ isOnCurrentMap = false }))
	end)

	Test("campanha e recorrente nao se confundem", function()
		local campaign = FilterById(Addon.QuestFilterIds.CAMPAIGN)
		local recurring = FilterById(Addon.QuestFilterIds.RECURRING)
		local quest = { isCampaign = true, isRecurring = false }

		IsTrue(campaign.matches(quest))
		IsTrue(not recurring.matches(quest))
	end)

	Test("todo filtro tem id, rotulo e predicado", function()
		for _, filter in ipairs(Addon.QuestFilters) do
			IsTrue(type(filter.id) == "string", "id ausente")
			IsTrue(type(filter.label) == "string", "rotulo ausente")
			IsTrue(type(filter.matches) == "function", "predicado ausente em " .. filter.id)
		end
	end)
end)

Suite("SortModes", function()
	Test("desativada nao compara", function()
		Equals(SortModeById("none").compare, nil)
	end)

	Test("por nivel ordena crescente e trata nivel ausente", function()
		local compare = SortModeById("level").compare

		IsTrue(compare({ level = 10 }, { level = 20 }))
		IsTrue(not compare({ level = 20 }, { level = 10 }))
		IsTrue(compare({}, { level = 1 }))
	end)

	Test("por titulo ordena alfabeticamente", function()
		local compare = SortModeById("title").compare

		IsTrue(compare({ title = "A" }, { title = "B" }))
		IsTrue(not compare({ title = "B" }, { title = "A" }))
	end)
end)

Suite("SectionOrder", function()
	Test("cenario vem antes de missoes, que vem antes de conquistas", function()
		IsTrue(Addon.SectionOrder.scenario < Addon.SectionOrder.quests)
		IsTrue(Addon.SectionOrder.quests < Addon.SectionOrder.achievements)
	end)

	Test("nenhuma secao divide a mesma posicao", function()
		local seen = {}

		for id, order in pairs(Addon.SectionOrder) do
			IsTrue(seen[order] == nil, ("%s e %s empatam em %d"):format(id, tostring(seen[order]), order))
			seen[order] = id
		end
	end)
end)

Suite("CompletionWatcher", function()
	---@param entries TrackerEntry[]
	---@return TrackerSection[]
	local function Sections(entries)
		return { { id = "quests", title = "Missões", order = 1, entries = entries } }
	end

	Test("a primeira leitura nao reporta nada", function()
		local watcher = Addon.CompletionWatcher.New()
		local found = watcher:Detect(Sections({ Entry({ isComplete = true }) }))

		Equals(#found, 0)
	end)

	Test("reporta a virada para concluida uma unica vez", function()
		local watcher = Addon.CompletionWatcher.New()
		watcher:Detect(Sections({ Entry({ isComplete = false }) }))

		Equals(#watcher:Detect(Sections({ Entry({ isComplete = true }) })), 1)
		Equals(#watcher:Detect(Sections({ Entry({ isComplete = true }) })), 0)
	end)

	Test("entradas de tipos diferentes com o mesmo id nao se misturam", function()
		local watcher = Addon.CompletionWatcher.New()
		local before = Sections({
			Entry({ id = 7, kind = "quest" }),
			Entry({ id = 7, kind = "achievement" }),
		})
		watcher:Detect(before)

		local after = Sections({
			Entry({ id = 7, kind = "quest", isComplete = true }),
			Entry({ id = 7, kind = "achievement" }),
		})

		Equals(#watcher:Detect(after), 1)
	end)
end)

Suite("TrackerContent", function()
	---@param id string
	---@param order number
	---@param entries TrackerEntry[]
	---@return SectionProvider
	local function Provider(id, order, entries)
		return {
			Collect = function()
				return { { id = id, title = id, order = order, entries = entries } }
			end,
		}
	end

	---@param values table
	---@return Preferences
	local function Preferences(values)
		return Addon.Preferences.New({}, values, function() end)
	end

	Test("secao vazia nao entra na lista", function()
		local content = Addon.TrackerContent.New(
			{ Provider("quests", 20, {}), Provider("events", 35, { Entry({}) }) },
			Addon.SortModes,
			Preferences({ sortMode = "none" })
		)

		local sections = content:Build()

		Equals(#sections, 1)
		Equals(sections[1].id, "events")
	end)

	Test("secoes saem na ordem declarada", function()
		local content = Addon.TrackerContent.New({
			Provider("events", 35, { Entry({}) }),
			Provider("quests", 20, { Entry({}) }),
		}, Addon.SortModes, Preferences({ sortMode = "none" }))

		local sections = content:Build()

		Equals(sections[1].id, "quests")
		Equals(sections[2].id, "events")
	end)

	Test("concluidas descem para o fim mantendo a ordem entre si", function()
		local content = Addon.TrackerContent.New({
			Provider("quests", 20, {
				Entry({ id = 1, title = "pronta A", isComplete = true }),
				Entry({ id = 2, title = "aberta" }),
				Entry({ id = 3, title = "pronta B", isComplete = true }),
			}),
		}, Addon.SortModes, Preferences({ sortMode = "none" }))

		local entries = content:Build()[1].entries

		Equals(entries[1].title, "aberta")
		Equals(entries[2].title, "pronta A")
		Equals(entries[3].title, "pronta B")
	end)

	Test("ordenacao por titulo vale dentro da secao", function()
		local content = Addon.TrackerContent.New({
			Provider("quests", 20, {
				Entry({ id = 1, title = "Zangado" }),
				Entry({ id = 2, title = "Alegre" }),
			}),
		}, Addon.SortModes, Preferences({ sortMode = "title" }))

		local entries = content:Build()[1].entries

		Equals(entries[1].title, "Alegre")
		Equals(entries[2].title, "Zangado")
	end)
end)

Suite("Preferences", function()
	Test("preenche o que falta com o padrao", function()
		local values = {}
		Addon.Preferences.New({ { key = "fontSize", default = 12 } }, values, function() end)

		Equals(values.fontSize, 12)
	end)

	Test("nao sobrescreve valor ja guardado", function()
		local values = { fontSize = 20 }
		Addon.Preferences.New({ { key = "fontSize", default = 12 } }, values, function() end)

		Equals(values.fontSize, 20)
	end)

	Test("avisa ao mudar e cala quando o valor e o mesmo", function()
		local changes = 0
		local preferences = Addon.Preferences.New({}, {}, function()
			changes = changes + 1
		end)

		preferences:Set("fontSize", 14)
		Equals(changes, 1)

		preferences:Set("fontSize", 14)
		Equals(changes, 1, "valor igual nao deveria avisar")

		preferences:Set("fontSize", 16)
		Equals(changes, 2)
	end)
end)

Suite("AchievementCategories", function()
	local function ListTwo()
		return { { id = 1, name = "Um" }, { id = 2, name = "Dois" } }
	end

	Test("tudo visivel por padrao", function()
		local categories = Addon.AchievementCategories.New({}, ListTwo, function() end)

		IsTrue(categories:IsShown(1))
	end)

	Test("alternar esconde e mostra de volta", function()
		local hidden = {}
		local categories = Addon.AchievementCategories.New(hidden, ListTwo, function() end)

		categories:Toggle(1)
		IsTrue(not categories:IsShown(1))

		categories:Toggle(1)
		IsTrue(categories:IsShown(1))
		Equals(next(hidden), nil, "o conjunto deveria voltar a ficar vazio")
	end)

	Test("desmarcar todas esconde cada uma da lista", function()
		local hidden = {}
		local categories = Addon.AchievementCategories.New(hidden, ListTwo, function() end)

		categories:ShowAll(false)
		IsTrue(not categories:IsShown(1))
		IsTrue(not categories:IsShown(2))

		categories:ShowAll(true)
		Equals(next(hidden), nil)
	end)
end)

Suite("Profiles", function()
	Test("instalacao nova ganha um perfil padrao", function()
		local store = {}
		local profiles = Addon.Profiles.New(store, "Inpuro - Azralon")

		IsTrue(profiles:Current() ~= nil)
		IsTrue(#profiles:Names() >= 1)
	end)

	Test("criar e selecionar troca o perfil em uso", function()
		local profiles = Addon.Profiles.New({}, "Inpuro - Azralon")
		profiles:Create("Alterativo")
		profiles:Select("Alterativo")

		Equals(profiles:CurrentName(), "Alterativo")
	end)

	Test("o perfil em uso nao pode ser apagado", function()
		local profiles = Addon.Profiles.New({}, "Inpuro - Azralon")

		IsTrue(not profiles:Delete(profiles:CurrentName()))
	end)

	Test("copiar leva as configuracoes junto", function()
		local profiles = Addon.Profiles.New({}, "Inpuro - Azralon")
		profiles:Current().settings.fontSize = 18
		profiles:CopyCurrentTo("Copia")
		profiles:Select("Copia")

		Equals(profiles:Current().settings.fontSize, 18)
	end)
end)

Suite("Locales", function()
	---@param path string
	---@return table<string, string>
	local function Entries(path)
		local captured
		local chunk = assert(loadfile(path))

		chunk("AuraTrackerQuestor", {
			RegisterLocale = function(_, entries)
				captured = entries
			end,
		})

		return captured
	end

	local english = Entries("Locales/enUS.lua")
	local portuguese = Entries("Locales/ptBR.lua")

	Test("ptBR nao inventa chave que o enUS nao tem", function()
		for key in pairs(portuguese) do
			IsTrue(english[key] ~= nil, key .. " so existe em ptBR")
		end
	end)

	Test("enUS cobre tudo que o ptBR traduz", function()
		for key in pairs(english) do
			IsTrue(portuguese[key] ~= nil, key .. " nao foi traduzido")
		end
	end)

	Test("marcadores de formato batem entre os dois", function()
		for key, text in pairs(english) do
			local _, expected = text:gsub("%%[%ds]", "")
			local _, actual = portuguese[key]:gsub("%%[%ds]", "")
			Equals(actual, expected, key .. " tem contagem de %s diferente")
		end
	end)

	Test("nenhuma chave usada no codigo esta faltando", function()
		for _, path in ipairs(Harness.RuntimeFiles()) do
			local source = io.open(path, "r")

			if source then
				local text = source:read("*a")
				source:close()

				for key in text:gmatch("L%.([A-Z_]+)") do
					IsTrue(english[key] ~= nil, ("%s le L.%s, que nao existe no enUS"):format(path, key))
				end
			end
		end
	end)
end)

os.exit(Harness.Report())
