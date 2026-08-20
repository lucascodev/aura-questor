return function(Addon, T)
	local HEIGHT = { maximum = 900, step = 20 }

	T.Suite("PreferenceBounds", function()
		T.Test("tela alta empurra o teto para cima", function()
			T.Equals(Addon.PreferenceBounds.Maximum(HEIGHT, 1440), 1440)
		end)

		T.Test("o teto cai num multiplo do passo", function()
			T.Equals(Addon.PreferenceBounds.Maximum(HEIGHT, 1450), 1440)
		end)

		T.Test("tela baixa nao encolhe o teto de fabrica", function()
			T.Equals(Addon.PreferenceBounds.Maximum(HEIGHT, 768), 900)
		end)

		T.Test("tela na medida do teto de fabrica nao muda nada", function()
			T.Equals(Addon.PreferenceBounds.Maximum(HEIGHT, 900), 900)
		end)
	end)
end
