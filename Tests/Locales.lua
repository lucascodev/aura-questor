return function(Addon, T, Support, Harness)
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

		T.Test("ptBR nao inventa chave que o enUS nao tem", function()
			for key in pairs(portuguese) do
				T.IsTrue(english[key] ~= nil, key .. " so existe em ptBR")
			end
		end)

		T.Test("enUS cobre tudo que o ptBR traduz", function()
			for key in pairs(english) do
				T.IsTrue(portuguese[key] ~= nil, key .. " nao foi traduzido")
			end
		end)

		T.Test("marcadores de formato batem entre os dois", function()
			for key, text in pairs(english) do
				T.Equals(
					Placeholders(portuguese[key]),
					Placeholders(text),
					key .. " tem contagem de marcadores diferente"
				)
			end
		end)

		T.Test("nenhum texto esta vazio", function()
			for name, entries in pairs({ enUS = english, ptBR = portuguese }) do
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
