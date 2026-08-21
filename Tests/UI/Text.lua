return function(Addon, T)
	local TimeLeft = Addon.EntryText.TimeLeft

	T.Suite("EntryText", function()
		T.Test("menos de um minuto sai so em segundos", function()
			T.Equals(TimeLeft(45), "45s")
			T.Equals(TimeLeft(0), "0s")
		end)

		T.Test("abaixo de uma hora sai em minutos e segundos", function()
			T.Equals(TimeLeft(60), "1min 0s")
			T.Equals(TimeLeft(272), "4min 32s")
			T.Equals(TimeLeft(3599), "59min 59s")
		end)

		T.Test("de uma hora para cima o segundo sai de cena", function()
			T.Equals(TimeLeft(3600), "1h 0min")
			T.Equals(TimeLeft(49260), "13h 41min")
		end)

		T.Test("fracao de segundo nao vaza para o texto", function()
			T.Equals(TimeLeft(45.9), "45s")
			T.Equals(TimeLeft(3599.9), "59min 59s")
		end)
	end)
end
