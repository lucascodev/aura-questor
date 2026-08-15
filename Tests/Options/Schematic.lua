return function(Addon, T)
	local Schematic = Addon.OptionsSchematic
	local METRICS = { cardPadding = 16, titleBlock = 26 }

	T.Suite("OptionsSchematic", function()
		T.Test("conteudo vazio tem altura zero", function()
			T.Equals(Schematic.ContentHeight({}, 12), 0)
		end)

		T.Test("conteudo soma linhas e respiros entre elas", function()
			T.Equals(Schematic.ContentHeight({ 46, 46, 16 }, 12), 46 + 12 + 46 + 12 + 16)
		end)

		T.Test("divisor entra como a espessura dele", function()
			T.Equals(Schematic.ContentHeight({ 16, 1, 16 }, 12), 16 + 12 + 1 + 12 + 16)
		end)

		T.Test("card sem titulo e so padding em volta do conteudo", function()
			T.Equals(Schematic.CardHeight(100, false, METRICS), 16 + 100 + 16)
		end)

		T.Test("titulo soma o bloco do titulo", function()
			T.Equals(Schematic.CardHeight(100, true, METRICS), 16 + 26 + 100 + 16)
		end)

		T.Test("cards empilham com o gap entre eles", function()
			local tops = Schematic.Tops({ 130, 90, 60 }, 84, 16)

			T.Equals(tops[1], 84)
			T.Equals(tops[2], 84 + 130 + 16)
			T.Equals(tops[3], 84 + 130 + 16 + 90 + 16)
		end)

		T.Test("paridade com o tema real: nada muda por acidente", function()
			local Theme = Addon.OptionsTheme

			T.Equals(Theme.COLUMN_OFFSET, Theme.COLUMN_WIDTH + Theme.COLUMN_GUTTER)
			T.Equals(
				Schematic.CardHeight(0, true, {
					cardPadding = Theme.CARD_PADDING,
					titleBlock = Theme.CARD_TITLE_BLOCK,
				}),
				Theme.CARD_PADDING * 2 + Theme.CARD_TITLE_BLOCK
			)
		end)
	end)
end
