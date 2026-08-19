return function(Addon, T, Support)
	local Keys = Addon.PreferenceKeys

	---@param overrides table?
	---@return table
	local function Values(overrides)
		local values = {}

		for _, preference in ipairs(Addon.PreferenceCatalog) do
			values[preference.key] = preference.default
		end

		for key, value in pairs(overrides or {}) do
			values[key] = value
		end

		return values
	end

	---@param options table?
	---@return table
	local function Build(options)
		options = options or {}

		local sections = options.sections or {}
		local content = {
			Build = function()
				return sections
			end,
		}
		local renderer = Support.Renderer()
		local blizzard = Support.BlizzardTracker()
		local hiddenSections = options.hiddenSections or {}
		local widgets = options.widgets or {}
		local preferences = Addon.Preferences.New(
			Addon.PreferenceCatalog,
			Values(options.values),
			function() end
		)

		local display = Addon.TrackerDisplay.New(
			content,
			renderer,
			blizzard,
			preferences,
			hiddenSections,
			Support.AppearanceSources(),
			widgets,
			Support.GameState(options.isChallengeActive)
		)

		return {
			display = display,
			renderer = renderer,
			blizzard = blizzard,
			hiddenSections = hiddenSections,
			preferences = preferences,
		}
	end

	T.Suite("TrackerDisplay", function()
		T.Test("com o nosso ligado, o da Blizzard sai de cena", function()
			local built = Build()
			built.display:Refresh()

			T.Equals(built.blizzard.hidden, true)
			T.Equals(built.renderer.shown, true)
		end)

		T.Test("manter o da Blizzard deixa os dois na tela", function()
			local built = Build({ values = { [Keys.KEEP_BLIZZARD_TRACKER] = true } })
			built.display:Refresh()

			T.Equals(built.blizzard.hidden, false)
			T.Equals(built.renderer.shown, true)
		end)

		T.Test("com o nosso desligado, o da Blizzard volta", function()
			local built = Build({ values = { [Keys.OWN_TRACKER_ENABLED] = false } })
			built.display:Refresh()

			T.Equals(built.blizzard.hidden, false)
			T.Equals(built.renderer.shown, false)
			T.Equals(built.renderer.rendered, nil, "nada deveria ter sido desenhado")
		end)

		T.Test("desligado ainda aplica a visibilidade dos botoes", function()
			local widget = Support.Widget()
			local built = Build({
				values = { [Keys.OWN_TRACKER_ENABLED] = false, [Keys.SHOW_MINIMAP_BUTTON] = true },
				widgets = { [Keys.SHOW_MINIMAP_BUTTON] = widget },
			})

			built.display:Refresh()

			T.Equals(widget.shown, true, "sem isso nao haveria como religar o rastreador")
		end)

		T.Test("cada botao obedece a sua propria preferencia", function()
			local filter = Support.Widget()
			local minimap = Support.Widget()
			local built = Build({
				values = {
					[Keys.SHOW_FILTER_BUTTON] = false,
					[Keys.SHOW_MINIMAP_BUTTON] = true,
				},
				widgets = {
					[Keys.SHOW_FILTER_BUTTON] = filter,
					[Keys.SHOW_MINIMAP_BUTTON] = minimap,
				},
			})

			built.display:Refresh()

			T.Equals(filter.shown, false)
			T.Equals(minimap.shown, true)
		end)

		T.Test("secao escondida nao chega ao renderer, mas continua listada", function()
			local built = Build({
				sections = {
					Support.Section("quests", 20, { Support.Entry({}) }),
					Support.Section("events", 35, { Support.Entry({}) }),
				},
				hiddenSections = { events = true },
			})

			built.display:Refresh()

			T.Equals(#built.renderer.rendered, 1)
			T.Equals(built.renderer.rendered[1].id, "quests")
			T.Equals(#built.display:Sections(), 2, "a escondida some da tela, nao da lista")
		end)

		T.Test("alternar a secao esconde e traz de volta", function()
			local built = Build({
				sections = { Support.Section("quests", 20, { Support.Entry({}) }) },
			})

			T.IsTrue(built.display:IsSectionShown("quests"))

			built.display:ToggleSection("quests")
			T.IsTrue(not built.display:IsSectionShown("quests"))
			T.Equals(#built.renderer.rendered, 0)

			built.display:ToggleSection("quests")
			T.IsTrue(built.display:IsSectionShown("quests"))
			T.Equals(#built.renderer.rendered, 1)
		end)

		T.Test("escala e porcentagem, nao fator", function()
			local built = Build({ values = { [Keys.TRACKER_SCALE] = 80 } })
			built.display:Refresh()

			T.Near(built.renderer.scale, 0.8, 0.001)
		end)

		T.Test("opacidade tambem vira fracao", function()
			local built = Build({
				values = { [Keys.PANEL_OPACITY] = 50, [Keys.BORDER_OPACITY] = 20 },
			})
			built.display:Refresh()

			T.Near(built.renderer.appearance.opacity, 0.5, 0.001)
			T.Near(built.renderer.appearance.borderOpacity, 0.2, 0.001)
		end)

		T.Test("a cor da borda sai do hexadecimal guardado", function()
			local built = Build({
				values = { [Keys.BORDER_COLOR] = "FF0000", [Keys.BORDER_CLASS_COLOR] = false },
			})
			built.display:Refresh()

			T.Equals(built.renderer.appearance.borderColor.red, 1)
			T.Equals(built.renderer.appearance.borderColor.green, 0)
		end)

		T.Test("cor pela classe sobrepoe a guardada sem apaga-la", function()
			local built = Build({
				values = { [Keys.BORDER_COLOR] = "000000", [Keys.BORDER_CLASS_COLOR] = true },
			})
			built.display:Refresh()

			T.Equals(built.renderer.appearance.borderColor.red, 1, "deveria vir da classe")
			T.Equals(
				built.preferences:Get(Keys.BORDER_COLOR),
				"000000",
				"a cor escolhida continua guardada"
			)
		end)

		T.Test("o contorno da fonte chega resolvido", function()
			local built = Build({ values = { [Keys.FONT_FLAG] = "none" } })
			built.display:Refresh()

			T.Equals(built.renderer.font.flags, "", "none nao pode chegar cru na fonte")
		end)

		T.Test("a fonte e desenhada antes do layout ser medido", function()
			local built = Build()
			built.display:Refresh()

			T.IsTrue(built.renderer.font ~= nil)
			T.IsTrue(built.renderer.appearance ~= nil)
		end)

		T.Test("pedra-chave ativa deixa so a secao da instancia", function()
			local sections = {
				{ id = "scenario", title = "Masmorra", order = 1, entries = {} },
				{ id = "quests", title = "Missoes", order = 2, entries = {} },
				{ id = "worldQuests", title = "Mundiais", order = 3, entries = {} },
			}
			local built = Build({ sections = sections, isChallengeActive = true })
			built.display:Refresh()

			T.Equals(#built.renderer.rendered, 1)
			T.Equals(built.renderer.rendered[1].id, "scenario")
		end)

		T.Test("com o foco desligado a pedra-chave nao esconde nada", function()
			local sections = {
				{ id = "scenario", title = "Masmorra", order = 1, entries = {} },
				{ id = "quests", title = "Missoes", order = 2, entries = {} },
			}
			local built = Build({
				sections = sections,
				isChallengeActive = true,
				values = { [Keys.INSTANCE_FOCUS] = false },
			})
			built.display:Refresh()

			T.Equals(#built.renderer.rendered, 2)
		end)

		T.Test("fora da pedra-chave o foco nao muda nada", function()
			local sections = {
				{ id = "scenario", title = "Masmorra", order = 1, entries = {} },
				{ id = "quests", title = "Missoes", order = 2, entries = {} },
			}
			local built = Build({ sections = sections })
			built.display:Refresh()

			T.Equals(#built.renderer.rendered, 2)
		end)
	end)
end
