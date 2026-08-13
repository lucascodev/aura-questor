return function(Addon, T)
	local catalog = Addon.PreferenceCatalog
	local Keys = Addon.PreferenceKeys

	---@return table<string, boolean>
	local function DeclaredKeys()
		local declared = {}

		for _, key in pairs(Keys) do
			declared[key] = true
		end

		return declared
	end

	T.Suite("PreferenceCatalog", function()
		T.Test("nao esta vazio", function()
			T.IsTrue(#catalog > 0)
		end)

		T.Test("toda chave usada existe em PreferenceKeys", function()
			local declared = DeclaredKeys()

			for _, preference in ipairs(catalog) do
				T.IsTrue(
					declared[preference.key],
					("%s nao esta em PreferenceKeys"):format(tostring(preference.key))
				)
			end
		end)

		T.Test("nenhuma chave aparece duas vezes", function()
			local seen = {}

			for _, preference in ipairs(catalog) do
				T.IsTrue(not seen[preference.key], preference.key .. " esta duplicada")
				seen[preference.key] = true
			end
		end)

		T.Test("toda preferencia tem rotulo e valor padrao", function()
			for _, preference in ipairs(catalog) do
				T.IsTrue(
					type(preference.label) == "string" and preference.label ~= "",
					preference.key .. " sem rotulo"
				)
				T.IsTrue(preference.default ~= nil, preference.key .. " sem padrao")
			end
		end)

		T.Test("o tipo declarado bate com o valor padrao", function()
			for _, preference in ipairs(catalog) do
				local expected = preference.kind == "color" and "string" or preference.kind

				T.Equals(
					type(preference.default),
					expected,
					("%s declara %s"):format(preference.key, preference.kind)
				)
			end
		end)

		T.Test("preferencia numerica traz minimo, maximo e passo coerentes", function()
			for _, preference in ipairs(catalog) do
				if preference.kind == "number" then
					local key = preference.key

					T.IsTrue(type(preference.minimum) == "number", key .. " sem minimo")
					T.IsTrue(type(preference.maximum) == "number", key .. " sem maximo")
					T.IsTrue(type(preference.step) == "number", key .. " sem passo")
					T.IsTrue(preference.minimum < preference.maximum, key .. " com faixa invertida")
					T.IsTrue(preference.step > 0, key .. " com passo nao positivo")
					T.IsTrue(
						preference.default >= preference.minimum
							and preference.default <= preference.maximum,
						key .. " tem padrao fora da faixa"
					)
				end
			end
		end)

		T.Test("cor padrao tem seis digitos hexadecimais", function()
			for _, preference in ipairs(catalog) do
				if preference.kind == "color" then
					T.IsTrue(
						preference.default:match("^%x%x%x%x%x%x$") ~= nil,
						preference.key .. " nao e uma cor de seis digitos"
					)
				end
			end
		end)

		T.Test("dropdown de lista fixa tem o padrao entre as opcoes", function()
			for _, preference in ipairs(catalog) do
				if preference.choices then
					local found = false

					for _, choice in ipairs(preference.choices) do
						found = found or choice.id == preference.default
					end

					T.IsTrue(found, preference.key .. " tem padrao fora das opcoes")
				end
			end
		end)

		T.Test("toda opcao de dropdown tem id e rotulo", function()
			for _, preference in ipairs(catalog) do
				for _, choice in ipairs(preference.choices or {}) do
					T.IsTrue(type(choice.id) == "string", preference.key .. " com id invalido")
					T.IsTrue(
						type(choice.label) == "string" and choice.label ~= "",
						preference.key .. " com rotulo vazio"
					)
				end
			end
		end)

		T.Test("preferencia fica numa pagina ou num painel, nunca nos dois", function()
			for _, preference in ipairs(catalog) do
				T.IsTrue(
					not (preference.page and preference.panel),
					preference.key .. " declara page e panel ao mesmo tempo"
				)
			end
		end)
	end)

	T.Suite("PreferenceKeys", function()
		T.Test("nenhuma chave de armazenamento se repete", function()
			local seen = {}

			for name, key in pairs(Keys) do
				T.IsTrue(
					not seen[key],
					("%s e %s guardam em %s"):format(name, tostring(seen[key]), key)
				)
				seen[key] = name
			end
		end)
	end)
end
