return function(Addon, T)
	local Ids = Addon.QuestFilterIds

	---@param id string
	---@return QuestFilter
	local function ById(id)
		for _, filter in ipairs(Addon.QuestFilters) do
			if filter.id == id then
				return filter
			end
		end

		error("filtro desconhecido: " .. tostring(id))
	end

	T.Suite("QuestFilters", function()
		T.Test("todas aceita qualquer missao", function()
			T.IsTrue(ById(Ids.ALL).matches({}))
		end)

		T.Test("zona atual olha apenas o mapa", function()
			local filter = ById(Ids.ZONE)

			T.IsTrue(filter.matches({ isOnCurrentMap = true }))
			T.IsTrue(not filter.matches({ isOnCurrentMap = false }))
		end)

		T.Test("campanha e recorrente nao se confundem", function()
			local quest = { isCampaign = true, isRecurring = false }

			T.IsTrue(ById(Ids.CAMPAIGN).matches(quest))
			T.IsTrue(not ById(Ids.RECURRING).matches(quest))
		end)

		T.Test("concluidas e nao concluidas sao complementares", function()
			for _, quest in ipairs({ { isComplete = true }, { isComplete = false } }) do
				T.IsTrue(
					ById(Ids.COMPLETE).matches(quest) ~= ById(Ids.UNFINISHED).matches(quest),
					"os dois filtros nao podem concordar sobre a mesma missao"
				)
			end
		end)

		T.Test("masmorra e raide olha apenas a instancia", function()
			T.IsTrue(ById(Ids.INSTANCE).matches({ isInstance = true }))
			T.IsTrue(not ById(Ids.INSTANCE).matches({ isInstance = false }))
		end)

		T.Test("todo filtro tem id, rotulo e predicado", function()
			for _, filter in ipairs(Addon.QuestFilters) do
				T.IsTrue(type(filter.id) == "string", "id ausente")
				T.IsTrue(type(filter.label) == "string", "rotulo ausente")
				T.IsTrue(type(filter.matches) == "function", "predicado ausente em " .. filter.id)
			end
		end)

		T.Test("todo id declarado tem um filtro", function()
			for name, id in pairs(Ids) do
				T.IsTrue(pcall(ById, id), name .. " nao tem filtro correspondente")
			end
		end)
	end)
end
