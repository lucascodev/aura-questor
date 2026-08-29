return function(Addon, T)
	---@return QuestRecency, table
	local function Recency(store)
		store = store or {}

		return Addon.QuestRecency.New(store), store
	end

	T.Suite("QuestRecency", function()
		T.Test("numera a missao na primeira vez que a ve", function()
			local recency = Recency()

			recency:Record(100)

			T.Equals(recency:Arrival(100), 1)
		end)

		T.Test("ver a mesma missao de novo nao renumera", function()
			local recency = Recency()

			recency:Record(100)
			recency:Record(200)
			recency:Record(100)

			T.Equals(recency:Arrival(100), 1, "renumerar embaralharia a lista na tela")
			T.Equals(recency:Arrival(200), 2)
		end)

		T.Test("missao nunca vista nao tem chegada", function()
			T.Equals(Recency():Arrival(100), nil)
		end)

		T.Test("adotar o log numera o que ainda nao conhecia", function()
			local recency = Recency()

			recency:Adopt({ 10, 20, 30 })

			T.Equals(recency:Arrival(10), 1)
			T.Equals(recency:Arrival(30), 3)
		end)

		T.Test("adotar esquece o que saiu do log", function()
			local recency = Recency()

			recency:Adopt({ 10, 20 })
			recency:Adopt({ 20 })

			T.Equals(recency:Arrival(10), nil, "entregue ou abandonada nao volta a lista")
			T.Equals(recency:Arrival(20), 2, "o que ficou mantem o numero que tinha")
		end)

		T.Test("log vazio nao apaga a historia", function()
			local recency = Recency()

			recency:Adopt({ 10, 20 })
			recency:Adopt({})

			T.Equals(recency:Arrival(10), 1, "no login o log demora a chegar, e vem vazio")
			T.Equals(recency:Arrival(20), 2)
		end)

		T.Test("a contagem continua na sessao seguinte", function()
			local first, store = Recency()
			first:Record(10)

			local second = Addon.QuestRecency.New(store)
			second:Record(20)

			T.IsTrue(second:Arrival(20) > second:Arrival(10), "a nova tem que ser mais recente")
		end)

		T.Test("store de versao antiga comeca do zero sem quebrar", function()
			local recency = Addon.QuestRecency.New({})

			recency:Record(10)

			T.Equals(recency:Arrival(10), 1)
		end)
	end)
end
