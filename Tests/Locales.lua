return function(Addon, T, Support, Harness)
	---@param path string
	---@return table<string, string>
	local function Entries(path)
		local captured
		local chunk = assert(loadfile(path))

		chunk("AuraQuestor", {
			RegisterLocale = function(_, entries)
				captured = entries
			end,
		})

		return captured
	end

	local english = Entries("Locales/enUS.lua")

	local translations = {
		ptBR = Entries("Locales/ptBR.lua"),
		esES = Entries("Locales/esES.lua"),
		frFR = Entries("Locales/frFR.lua"),
	}

	---@param text string
	---@return number
	local function Placeholders(text)
		local _, count = text:gsub("%%[%ds]", "")

		return count
	end

	T.Suite("Locales", function()
		T.Test("o enUS nao esta vazio", function()
			T.IsTrue(next(english) ~= nil)
		end)

		T.Test("nenhuma traducao inventa chave que o enUS nao tem", function()
			for name, entries in pairs(translations) do
				for key in pairs(entries) do
					T.IsTrue(english[key] ~= nil, key .. " so existe em " .. name)
				end
			end
		end)

		T.Test("toda traducao cobre o enUS inteiro", function()
			for name, entries in pairs(translations) do
				for key in pairs(english) do
					T.IsTrue(entries[key] ~= nil, key .. " nao foi traduzido em " .. name)
				end
			end
		end)

		T.Test("marcadores de formato batem em toda traducao", function()
			for name, entries in pairs(translations) do
				for key, text in pairs(english) do
					T.Equals(
						Placeholders(entries[key]),
						Placeholders(text),
						("%s.%s tem contagem de marcadores diferente"):format(name, key)
					)
				end
			end
		end)

		T.Test("nenhum texto esta vazio", function()
			local all = { enUS = english }

			for name, entries in pairs(translations) do
				all[name] = entries
			end

			for name, entries in pairs(all) do
				for key, text in pairs(entries) do
					T.IsTrue(text ~= "", ("%s.%s esta vazio"):format(name, key))
				end
			end
		end)

		T.Test("nenhuma chave usada no codigo esta faltando", function()
			for _, path in ipairs(Harness.RuntimeFiles()) do
				local source = io.open(path, "r")

				if source then
					local text = source:read("*a")
					source:close()

					for key in text:gmatch("L%.([A-Z_]+)") do
						T.IsTrue(
							english[key] ~= nil,
							("%s le L.%s, que nao existe no enUS"):format(path, key)
						)
					end
				end
			end
		end)

		T.Test("chave sem traducao devolve o proprio nome em vez de nil", function()
			T.Equals(Addon.L.CHAVE_QUE_NAO_EXISTE, "CHAVE_QUE_NAO_EXISTE")
		end)
	end)
end
