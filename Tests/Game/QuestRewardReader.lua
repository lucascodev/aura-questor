--- O reader conversa com a API do jogo, então a suíte carrega o arquivo por
--- fora do Harness, com cada global que ele lê no lugar.
---
--- Os textos reais usam argumentos posicionais (%1$d), que o Lua do jogo aceita
--- e o Lua puro não; aqui eles têm a mesma ordem, sem a posição.
return function(_, T)
	local QUEST_ID = 70000
	local HIGHLIGHT = { r = 1, g = 1, b = 1 }
	local EPIC = { r = 0.64, g = 0.21, b = 0.93 }
	local OVERFLOW = { 1, 0.1, 0.1 }
	local NORMAL = { 1, 0.82, 0 }

	--- Uma missão sem nenhuma recompensa; cada teste liga só o que exercita.
	---@param quest table?
	local function Install(quest)
		quest = quest or {}

		BONUS_OBJECTIVE_EXPERIENCE_FORMAT = "%s XP"
		BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT = "%s Artifact Power"
		BONUS_OBJECTIVE_HOUSING_FAVOR_FORMAT = "%d %s"
		HOUSING_DASHBOARD_REWARD_ESTATE_XP = "House XP"
		BONUS_OBJECTIVE_REWARD_FORMAT = "[%s] %s"
		BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT = "[%s] %s %s"
		HONOR = "Honor"
		WAR_MODE_BONUS_PERCENTAGE_FORMAT = "+%d%% War Mode Bonus"
		WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT = "+%d%% War Mode XP"
		GameTooltipMoneyFormat = "tooltip"
		HIGHLIGHT_FONT_COLOR = {
			r = HIGHLIGHT.r,
			g = HIGHLIGHT.g,
			b = HIGHLIGHT.b,
			WrapTextInColorCode = function(_, text)
				return text
			end,
		}

		GetQuestLogRewardXP = function()
			return quest.xp or 0, quest.xp or 0
		end
		GetQuestLogRewardArtifactXP = function()
			return quest.artifactPower or 0
		end
		GetQuestLogRewardHonor = function()
			return quest.honor or 0
		end
		GetQuestLogRewardMoney = function()
			return quest.money or 0
		end
		GetNumQuestLogRewards = function()
			return #(quest.items or {})
		end
		GetQuestLogRewardInfo = function(index)
			local item = quest.items[index]
			return item.name, item.texture, item.count, item.quality
		end

		C_QuestInfoSystem = {
			GetQuestLogRewardFavor = function()
				return quest.favor or 0
			end,
			GetQuestRewardSpells = function()
				return quest.spellIDs or {}
			end,
			GetQuestRewardSpellInfo = function(_, spellID)
				return (quest.spells or {})[spellID]
			end,
		}
		C_QuestLog = {
			GetQuestRewardCurrencies = function()
				return quest.currencies or {}
			end,
			IsWorldQuest = function()
				return quest.isWorldQuest == true
			end,
			QuestCanHaveWarModeBonus = function()
				return quest.canHaveWarModeBonus == true
			end,
		}
		C_PvP = {
			IsWarModeDesired = function()
				return quest.isWarModeOn == true
			end,
			GetWarModeRewardBonus = function()
				return 10
			end,
		}
		C_CurrencyInfo = {
			GetCurrencyInfo = function(currencyID)
				return { quality = (quest.currencyQuality or {})[currencyID] or 1 }
			end,
			IsCurrencyContainer = function(currencyID)
				return (quest.containers or {})[currencyID] ~= nil
			end,
			GetCurrencyContainerInfo = function(currencyID)
				return quest.containers[currencyID]
			end,
			DoesWarModeBonusApply = function(currencyID)
				return (quest.warModeCurrencies or {})[currencyID] == true, false
			end,
			GetFactionGrantedByCurrency = function()
				return nil
			end,
		}
		MoneyFormatterUtil = {
			FormatMoney = function(copper, format)
				return ("%d copper (%s)"):format(copper, format)
			end,
		}
		ColorManager = {
			GetColorDataForItemQuality = function(quality)
				return quality == 4 and EPIC or nil
			end,
		}
		GetColorForCurrencyReward = function(currencyID)
			local color = (quest.overflowing or {})[currencyID] and OVERFLOW or NORMAL

			return {
				GetRGB = function()
					return color[1], color[2], color[3]
				end,
			}
		end

		local addon = {}
		local chunk = assert(loadfile("Source/Game/QuestRewardReader.lua"))
		chunk("AuraQuestor", addon)

		return addon.QuestRewardReader
	end

	---@param lines table[]
	---@return string
	local function Texts(lines)
		local texts = {}

		for _, line in ipairs(lines) do
			table.insert(texts, line.text)
		end

		return table.concat(texts, " | ")
	end

	---@param currencyID number
	---@param amount number
	---@param name string
	---@return table
	local function Currency(currencyID, amount, name)
		return { currencyID = currencyID, totalRewardAmount = amount, name = name, texture = "icon" .. currencyID }
	end

	T.Suite("QuestRewardReader", function()
		T.Test("missao sem recompensa nao gera linha", function()
			T.Equals(#Install().Lines(QUEST_ID), 0)
		end)

		T.Test("experiencia sai em destaque", function()
			local lines = Install({ xp = 1500 }).Lines(QUEST_ID)

			T.Equals(lines[1].text, "1500 XP")
			T.Equals(lines[1].color.red, HIGHLIGHT.r)
		end)

		T.Test("o bonus do modo guerra so aparece com o modo ligado e a missao elegivel", function()
			local withBonus = Install({ xp = 100, isWarModeOn = true, canHaveWarModeBonus = true }).Lines(QUEST_ID)
			local warModeOff = Install({ xp = 100, canHaveWarModeBonus = true }).Lines(QUEST_ID)
			local notEligible = Install({ xp = 100, isWarModeOn = true }).Lines(QUEST_ID)

			T.Equals(Texts(withBonus), "100 XP | +10% War Mode XP")
			T.Equals(#warModeOff, 1)
			T.Equals(#notEligible, 1)
		end)

		T.Test("moedas saem da mais rara para a mais comum", function()
			local lines = Install({
				currencies = { Currency(10, 5, "Comum"), Currency(20, 1, "Epica") },
				currencyQuality = { [10] = 1, [20] = 4 },
			}).Lines(QUEST_ID)

			T.Equals(Texts(lines), "[icon20] 1 Epica | [icon10] 5 Comum")
		end)

		T.Test("moeda que estouraria o limite vem na cor de aviso do jogo", function()
			local lines = Install({
				currencies = { Currency(10, 5, "Cheia") },
				overflowing = { [10] = true },
			}).Lines(QUEST_ID)

			T.Equals(lines[1].color.red, OVERFLOW[1])
			T.Equals(lines[1].color.green, OVERFLOW[2])
		end)

		T.Test("moeda container usa o nome e o icone do container, na cor da qualidade", function()
			local lines = Install({
				currencies = { Currency(30, 400, "Bruto") },
				containers = { [30] = { name = "Bau de pedras", icon = "bau", quality = 4 } },
			}).Lines(QUEST_ID)

			T.Equals(lines[1].text, "[bau] Bau de pedras")
			T.Equals(lines[1].color.red, EPIC.r)
		end)

		T.Test("bonus do modo guerra na moeda so em missao mundial", function()
			local quest = {
				currencies = { Currency(10, 5, "Moeda") },
				warModeCurrencies = { [10] = true },
				isWarModeOn = true,
				canHaveWarModeBonus = true,
			}

			T.Equals(#Install(quest).Lines(QUEST_ID), 1)

			quest.isWorldQuest = true
			T.Equals(Texts(Install(quest).Lines(QUEST_ID)), "[icon10] 5 Moeda | +10% War Mode Bonus")
		end)

		T.Test("dinheiro usa o formato de dinheiro do tooltip", function()
			local lines = Install({ money = 12345 }).Lines(QUEST_ID)

			T.Equals(lines[1].text, "12345 copper (tooltip)")
		end)

		T.Test("cada item entra com a quantidade quando passa de um", function()
			local lines = Install({
				items = {
					{ name = "Espada", texture = "espada", count = 1, quality = 4 },
					{ name = "Pocao", texture = "pocao", count = 3, quality = 1 },
				},
			}).Lines(QUEST_ID)

			T.Equals(Texts(lines), "[espada] Espada | [pocao] 3 Pocao")
			T.Equals(lines[1].color.red, EPIC.r)
			T.Equals(lines[2].color, nil, "sem cor de qualidade, fica a do tooltip")
		end)

		T.Test("item ainda sem dado do jogo e pulado", function()
			local lines = Install({ items = { { count = 1, quality = 1 } } }).Lines(QUEST_ID)

			T.Equals(#lines, 0)
		end)

		T.Test("feitico de recompensa entra pelo nome e icone", function()
			local lines = Install({
				spellIDs = { 99 },
				spells = { [99] = { name = "Montaria", texture = "sela" } },
			}).Lines(QUEST_ID)

			T.Equals(lines[1].text, "[sela] Montaria")
		end)

		T.Test("as linhas seguem a ordem do bloco do jogo", function()
			local lines = Install({
				xp = 10,
				honor = 5,
				money = 7,
				favor = 3,
				currencies = { Currency(10, 2, "Moeda") },
				items = { { name = "Item", texture = "item", count = 1, quality = 1 } },
			}).Lines(QUEST_ID)

			T.Equals(
				Texts(lines),
				"10 XP | 3 House XP | [icon10] 2 Moeda | [Interface\\ICONS\\Achievement_LegionPVPTier4] 5 Honor"
					.. " | 7 copper (tooltip) | [item] Item"
			)
		end)
	end)
end
