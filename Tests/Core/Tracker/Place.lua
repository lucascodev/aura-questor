return function(Addon, T)
	local Place = Addon.TrackerPlace

	local WINDOW = { width = 320, height = 400 }
	local SCREEN = { width = 1600, height = 1200 }

	T.Suite("TrackerPlace", function()
		T.Test("o lugar guardado e devolvido como veio", function()
			local saved = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 2477, y = 803 }
			local left, top = Place.Resolve(saved, WINDOW, SCREEN)

			T.Equals(left, 2477)
			T.Equals(top, 803)
		end)

		T.Test("sem nada guardado vai para o lugar de fabrica", function()
			local left, top = Place.Resolve({}, WINDOW, SCREEN)

			T.Equals(left, 1600 - 120 - 320)
			T.Equals(top, (1200 + 400) / 2)
		end)

		--- Uma versao antiga podia gravar outro canto. Lido como canto superior
		--- esquerdo, o mesmo par de numeros aponta para outro lugar da tela.
		T.Test("lugar gravado por outro canto e descartado", function()
			local saved = { point = "RIGHT", relativePoint = "RIGHT", x = -120, y = 0 }
			local left, top = Place.Resolve(saved, WINDOW, SCREEN)

			T.Equals(left, 1600 - 120 - 320)
			T.Equals(top, (1200 + 400) / 2)
		end)

		T.Test("meio par de numeros nao conta como lugar", function()
			local saved = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 2477 }
			local left = Place.Resolve(saved, WINDOW, SCREEN)

			T.Equals(left, 1600 - 120 - 320)
		end)

		T.Test("o canto de fabrica cabe na tela", function()
			local left, top = Place.Factory(WINDOW, SCREEN)

			T.IsTrue(left > 0 and left + WINDOW.width <= SCREEN.width, "sai pela lateral")
			T.IsTrue(top <= SCREEN.height and top - WINDOW.height >= 0, "sai por cima ou por baixo")
		end)
	end)
end
