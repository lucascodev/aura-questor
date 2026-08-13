return function(Addon, T, Support)
	---@param entries TrackerEntry[]
	---@return TrackerSection[]
	local function Sections(entries)
		return { Support.Section("quests", 20, entries) }
	end

	T.Suite("CompletionWatcher", function()
		T.Test("a primeira leitura nao reporta nada", function()
			local watcher = Addon.CompletionWatcher.New()
			local found = watcher:Detect(Sections({ Support.Entry({ isComplete = true }) }))

			T.Equals(#found, 0)
		end)

		T.Test("reporta a virada para concluida uma unica vez", function()
			local watcher = Addon.CompletionWatcher.New()
			watcher:Detect(Sections({ Support.Entry({ isComplete = false }) }))

			T.Equals(#watcher:Detect(Sections({ Support.Entry({ isComplete = true }) })), 1)
			T.Equals(#watcher:Detect(Sections({ Support.Entry({ isComplete = true }) })), 0)
		end)

		T.Test("devolve a entrada que virou, nao so a contagem", function()
			local watcher = Addon.CompletionWatcher.New()
			watcher:Detect(Sections({ Support.Entry({ title = "Alvo" }) }))

			local found = watcher:Detect(Sections({
				Support.Entry({ title = "Alvo", isComplete = true }),
			}))

			T.Equals(found[1].title, "Alvo")
		end)

		T.Test("entradas de tipos diferentes com o mesmo id nao se misturam", function()
			local watcher = Addon.CompletionWatcher.New()
			watcher:Detect(Sections({
				Support.Entry({ id = 7, kind = "quest" }),
				Support.Entry({ id = 7, kind = "achievement" }),
			}))

			local found = watcher:Detect(Sections({
				Support.Entry({ id = 7, kind = "quest", isComplete = true }),
				Support.Entry({ id = 7, kind = "achievement" }),
			}))

			T.Equals(#found, 1)
			T.Equals(found[1].kind, "quest")
		end)

		T.Test("entrada que some e volta concluida e reportada de novo", function()
			local watcher = Addon.CompletionWatcher.New()
			watcher:Detect(Sections({ Support.Entry({}) }))
			watcher:Detect(Sections({}))

			T.Equals(#watcher:Detect(Sections({ Support.Entry({ isComplete = true }) })), 1)
		end)

		T.Test("varias viradas na mesma leitura sao todas reportadas", function()
			local watcher = Addon.CompletionWatcher.New()
			watcher:Detect(Sections({
				Support.Entry({ id = 1 }),
				Support.Entry({ id = 2 }),
			}))

			local found = watcher:Detect(Sections({
				Support.Entry({ id = 1, isComplete = true }),
				Support.Entry({ id = 2, isComplete = true }),
			}))

			T.Equals(#found, 2)
		end)
	end)
end
