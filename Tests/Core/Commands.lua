return function(Addon, T, Support)
	local addonInfo = { title = "Aura Questor: Objective Tracker", brand = "Aura Questor", version = "9.9.9" }

	T.Suite("StatusCommand", function()
		T.Test("escreve titulo e versao no chat", function()
			local logger = Support.Logger()
			Addon.StatusCommand.New(logger, addonInfo):Run()

			T.Equals(#logger.infos, 1)
			T.IsTrue(logger.infos[1]:find("9.9.9", 1, true) ~= nil)
		end)
	end)

	T.Suite("HelpCommand", function()
		T.Test("escreve uma linha por comando", function()
			local logger = Support.Logger()
			local commands = {
				{ command = "/atq", description = "abre" },
				{ command = "/atq ajuda", description = "ajuda" },
			}

			Addon.HelpCommand.New(logger, commands):Run()

			T.Equals(#logger.infos, 2)
			T.IsTrue(logger.infos[1]:find("/atq", 1, true) ~= nil)
		end)

		T.Test("lista vazia nao escreve nada", function()
			local logger = Support.Logger()
			Addon.HelpCommand.New(logger, {}):Run()

			T.Equals(#logger.infos, 0)
		end)
	end)

	T.Suite("Startup", function()
		---@param announce boolean
		---@param hasAdoptedLegacy boolean?
		---@return table logger
		local function Run(announce, hasAdoptedLegacy)
			local logger = Support.Logger()
			local preferences = Addon.Preferences.New(
				{ { key = "announceOnLoad", default = announce } },
				{},
				function() end
			)

			Addon.Startup.New(logger, addonInfo, preferences, hasAdoptedLegacy):Run()

			return logger
		end

		T.Test("anuncia quando a preferencia esta ligada", function()
			T.Equals(#Run(true).infos, 1)
		end)

		T.Test("cala quando esta desligada", function()
			T.Equals(#Run(false).infos, 0)
		end)

		T.Test("avisa da adocao do banco antigo mesmo com o anuncio desligado", function()
			local logger = Run(false, true)

			T.Equals(#logger.infos, 1)
			T.Equals(logger.infos[1], Addon.L.LEGACY_ADOPTED)
		end)
	end)
end
