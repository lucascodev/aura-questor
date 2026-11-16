--- O reader conversa com a API do jogo, então a suíte carrega o arquivo por
--- fora do Harness, com um C_UIWidgetManager de mentira no lugar do global.
return function(_, T)
	local TEXT_WITH_STATE = 8
	local ICON_AND_TEXT = 0
	local STATUS_BAR = 2
	local HIDDEN = 0
	local SHOWN = 1
	local SET_ID = 1802

	---@param widgets table[] { widgetID, widgetType, info }
	---@return table addon
	local function Load(widgets)
		local infoByID = {}
		local listed = {}

		for _, widget in ipairs(widgets) do
			infoByID[widget.widgetID] = widget.info
			table.insert(listed, { widgetID = widget.widgetID, widgetSetID = SET_ID, widgetType = widget.widgetType })
		end

		local function Info(widgetID)
			return infoByID[widgetID]
		end

		Enum = {
			UIWidgetVisualizationType = { IconAndText = ICON_AND_TEXT, StatusBar = STATUS_BAR, TextWithState = TEXT_WITH_STATE },
			WidgetShownState = { Hidden = HIDDEN, Shown = SHOWN },
			IconAndTextWidgetState = { Hidden = HIDDEN, Shown = SHOWN },
		}
		C_UIWidgetManager = {
			GetAllWidgetsBySetID = function(setID)
				return setID == SET_ID and listed or {}
			end,
			GetTextWithStateWidgetVisualizationInfo = Info,
			GetIconAndTextWidgetVisualizationInfo = Info,
		}

		local addon = {}
		local chunk = assert(loadfile("Source/Game/WidgetTextReader.lua"))
		chunk("AuraQuestor", addon)

		return addon
	end

	---@param text string
	---@param orderIndex number?
	---@return table
	local function TextWithState(widgetID, text, orderIndex, shownState)
		return {
			widgetID = widgetID,
			widgetType = TEXT_WITH_STATE,
			info = { text = text, shownState = shownState or SHOWN, orderIndex = orderIndex or 0 },
		}
	end

	T.Suite("WidgetTextReader", function()
		T.Test("o texto do widget da issue vira uma linha", function()
			local addon = Load({ TextWithState(7420, "Story Variant: Totem Annihilation") })

			local lines = addon.WidgetTextReader.Lines(SET_ID)

			T.Equals(#lines, 1)
			T.Equals(lines[1], "Story Variant: Totem Annihilation")
		end)

		T.Test("icone com texto tambem entra, pelo campo de estado dele", function()
			local addon = Load({
				{ widgetID = 1, widgetType = ICON_AND_TEXT, info = { text = "Visivel", state = SHOWN, orderIndex = 0 } },
				{ widgetID = 2, widgetType = ICON_AND_TEXT, info = { text = "Oculto", state = HIDDEN, orderIndex = 1 } },
			})

			local lines = addon.WidgetTextReader.Lines(SET_ID)

			T.Equals(#lines, 1)
			T.Equals(lines[1], "Visivel")
		end)

		T.Test("widget escondido pelo jogo nao aparece", function()
			local addon = Load({ TextWithState(1, "Escondido", 0, HIDDEN) })

			T.Equals(#addon.WidgetTextReader.Lines(SET_ID), 0)
		end)

		T.Test("texto vazio nao vira linha em branco", function()
			local addon = Load({ TextWithState(1, "") })

			T.Equals(#addon.WidgetTextReader.Lines(SET_ID), 0)
		end)

		T.Test("tipo sem texto, como barra, fica de fora", function()
			local addon = Load({
				{ widgetID = 1, widgetType = STATUS_BAR, info = { text = "Barra", shownState = SHOWN, orderIndex = 0 } },
			})

			T.Equals(#addon.WidgetTextReader.Lines(SET_ID), 0)
		end)

		T.Test("widget sem dado ainda carregado e pulado", function()
			local addon = Load({ { widgetID = 1, widgetType = TEXT_WITH_STATE, info = nil } })

			T.Equals(#addon.WidgetTextReader.Lines(SET_ID), 0)
		end)

		T.Test("as linhas seguem a ordem do jogo, nao a da lista", function()
			local addon = Load({
				TextWithState(30, "Terceira", 2),
				TextWithState(10, "Primeira", 0),
				TextWithState(20, "Segunda", 1),
			})

			local lines = addon.WidgetTextReader.Lines(SET_ID)

			T.Equals(table.concat(lines, ","), "Primeira,Segunda,Terceira")
		end)

		T.Test("mesma ordem do jogo desempata pelo id", function()
			local addon = Load({ TextWithState(9, "Depois", 0), TextWithState(3, "Antes", 0) })

			T.Equals(table.concat(addon.WidgetTextReader.Lines(SET_ID), ","), "Antes,Depois")
		end)
	end)
end
