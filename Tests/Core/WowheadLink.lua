return function(Addon, T)
	local For = Addon.WowheadLink.For

	T.Suite("WowheadLink", function()
		T.Test("missao no idioma do cliente", function()
			T.Equals(For("quest", 12345, "ptBR"), "https://pt.wowhead.com/quest=12345")
		end)

		T.Test("conquista tambem", function()
			T.Equals(For("achievement", 987, "frFR"), "https://fr.wowhead.com/achievement=987")
		end)

		T.Test("idioma sem subdominio proprio cai no www", function()
			T.Equals(For("quest", 1, "enUS"), "https://www.wowhead.com/quest=1")
			T.Equals(For("quest", 1, "zhTW"), "https://www.wowhead.com/quest=1")
		end)

		T.Test("o subdominio nao e o codigo do idioma", function()
			T.Equals(For("quest", 2, "zhCN"), "https://cn.wowhead.com/quest=2")
			T.Equals(For("quest", 2, "esMX"), "https://es.wowhead.com/quest=2")
		end)
	end)
end
