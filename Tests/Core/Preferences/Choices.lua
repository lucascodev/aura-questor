return function(Addon, T)
	---@param list PreferenceChoice[]
	---@param id string
	---@return boolean
	local function Has(list, id)
		for _, choice in ipairs(list) do
			if choice.id == id then
				return true
			end
		end

		return false
	end

	T.Suite("FontFlags", function()
		T.Test("nenhum vira string vazia, que e o que a fonte espera", function()
			T.Equals(Addon.FontFlags.Resolve("none"), "")
		end)

		T.Test("os demais passam adiante sem traducao", function()
			T.Equals(Addon.FontFlags.Resolve("OUTLINE"), "OUTLINE")
			T.Equals(Addon.FontFlags.Resolve("MONOCHROME,OUTLINE"), "MONOCHROME,OUTLINE")
		end)

		T.Test("a lista oferece a opcao nenhum", function()
			T.IsTrue(Has(Addon.FontFlags.Choices, "none"))
		end)
	end)

	T.Suite("SortModes", function()
		---@param id string
		---@return SortMode
		local function ById(id)
			for _, mode in ipairs(Addon.SortModes) do
				if mode.id == id then
					return mode
				end
			end

			error("ordenacao desconhecida: " .. id)
		end

		T.Test("desativada nao compara", function()
			T.Equals(ById("none").compare, nil)
		end)

		T.Test("por nivel ordena crescente e trata nivel ausente", function()
			local compare = ById("level").compare

			T.IsTrue(compare({ level = 10 }, { level = 20 }))
			T.IsTrue(not compare({ level = 20 }, { level = 10 }))
			T.IsTrue(compare({}, { level = 1 }))
		end)

		T.Test("por titulo ordena alfabeticamente", function()
			local compare = ById("title").compare

			T.IsTrue(compare({ title = "A" }, { title = "B" }))
			T.IsTrue(not compare({ title = "B" }, { title = "A" }))
		end)

		T.Test("por agrupamento trata grupo ausente", function()
			local compare = ById("group").compare

			T.IsTrue(compare({}, { groupName = "Valdrakken" }))
		end)
	end)

	T.Suite("SoundChannels", function()
		T.Test("oferece os canais que PlaySound aceita", function()
			for _, id in ipairs({ "Master", "SFX", "Music", "Ambience", "Dialog" }) do
				T.IsTrue(Has(Addon.SoundChannels, id), id .. " nao esta na lista")
			end
		end)
	end)
end
