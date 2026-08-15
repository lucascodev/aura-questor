return function(Addon, T)
	local Lookup = Addon.PreferenceLookup

	local catalog = {
		{ key = "alpha", kind = "boolean", default = true },
		{ key = "beta", kind = "number", default = 1, page = "Página" },
		{ key = "gamma", kind = "color", default = "FFFFFF", panel = "painel" },
		{ key = "delta", kind = "boolean", default = false },
	}

	T.Suite("PreferenceLookup", function()
		T.Test("acha a preferencia pela chave", function()
			T.Equals(Lookup.Find(catalog, "beta").kind, "number")
		end)

		T.Test("chave desconhecida estoura com a mensagem do locale", function()
			local ok, message = pcall(Lookup.Find, catalog, "nao_existe")

			T.IsTrue(not ok)
			T.IsTrue(tostring(message):find("nao_existe", 1, true) ~= nil)
		end)

		T.Test("raizes sao as sem pagina e sem painel, na ordem", function()
			local roots = Lookup.Roots(catalog)

			T.Equals(#roots, 2)
			T.Equals(roots[1].key, "alpha")
			T.Equals(roots[2].key, "delta")
		end)

		T.Test("no catalogo real toda raiz e boolean", function()
			for _, preference in ipairs(Lookup.Roots(Addon.PreferenceCatalog)) do
				T.Equals(preference.kind, "boolean", preference.key)
			end
		end)
	end)
end
