local _, Addon = ...

--- Reads a quest's rewards into the lines the game's own rewards block shows,
--- without calling it.
---
--- GameTooltip_AddQuestRewardsToTooltip writes into GameTooltip, which the whole
--- interface shares: waitingForData on every call, and the embedded item
--- tooltip for currency-container and spell rewards. From an addon those writes
--- are tainted, and the map reads them back when it draws its own quest
--- tooltips. Building the lines here leaves nothing behind but AddLine.
---@class QuestRewardReader
local QuestRewardReader = {}

local HONOR_ICON = [[Interface\ICONS\Achievement_LegionPVPTier4]]

---@class RewardLine
---@field text string
---@field color TrackerColor? Nil keeps the tooltip's own text colour.

---@param red number
---@param green number
---@param blue number
---@return TrackerColor
local function Color(red, green, blue)
	return { red = red, green = green, blue = blue }
end

---@return TrackerColor
local function Highlight()
	return Color(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

---@param quality number?
---@return TrackerColor?
local function QualityColor(quality)
	local colorData = quality and ColorManager.GetColorDataForItemQuality(quality)

	return colorData and Color(colorData.r, colorData.g, colorData.b) or nil
end

---@param questID number
---@return boolean
local function HasWarModeBonus(questID)
	return C_PvP.IsWarModeDesired() and C_QuestLog.QuestCanHaveWarModeBonus(questID)
end

---@param format string
---@return RewardLine
local function WarModeLine(format)
	return { text = format:format(C_PvP.GetWarModeRewardBonus()) }
end

---@param lines RewardLine[]
---@param questID number
local function AddExperience(lines, questID)
	local _, baseExperience = GetQuestLogRewardXP(questID)

	if baseExperience <= 0 then
		return
	end

	table.insert(lines, { text = BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(baseExperience), color = Highlight() })

	if HasWarModeBonus(questID) then
		table.insert(lines, WarModeLine(WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT))
	end
end

---@param lines RewardLine[]
---@param questID number
local function AddArtifactPower(lines, questID)
	local artifactPower = GetQuestLogRewardArtifactXP(questID)

	if artifactPower > 0 then
		table.insert(lines, { text = BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactPower), color = Highlight() })
	end
end

---@param lines RewardLine[]
---@param questID number
local function AddFavor(lines, questID)
	local favor = C_QuestInfoSystem.GetQuestLogRewardFavor(questID)

	if favor > 0 then
		table.insert(lines, {
			text = BONUS_OBJECTIVE_HOUSING_FAVOR_FORMAT:format(favor, HOUSING_DASHBOARD_REWARD_ESTATE_XP),
			color = Highlight(),
		})
	end
end

--- Rarest first, as the game lists them. The first of each currency is marked
--- because some war mode bonuses count once per tooltip.
---@param questID number
---@return { reward: table, quality: number, isFirst: boolean }[]
local function SortedCurrencies(questID)
	local currencies = {}
	local seen = {}

	for _, reward in ipairs(C_QuestLog.GetQuestRewardCurrencies(questID) or {}) do
		table.insert(currencies, {
			reward = reward,
			quality = C_CurrencyInfo.GetCurrencyInfo(reward.currencyID).quality,
			isFirst = not seen[reward.currencyID],
		})
		seen[reward.currencyID] = true
	end

	table.sort(currencies, function(first, second)
		if first.quality ~= second.quality then
			return first.quality > second.quality
		end

		return first.reward.currencyID > second.reward.currencyID
	end)

	return currencies
end

--- A container stands for another currency, so it shows under that one's name
--- and icon, the way the game draws it.
---@param reward table QuestRewardCurrencyInfo
---@return RewardLine
local function CurrencyLine(reward)
	local currencyID, amount = reward.currencyID, reward.totalRewardAmount
	local container = C_CurrencyInfo.IsCurrencyContainer(currencyID, amount)
		and C_CurrencyInfo.GetCurrencyContainerInfo(currencyID, amount)

	if container then
		return {
			text = BONUS_OBJECTIVE_REWARD_FORMAT:format(container.icon, container.name),
			color = QualityColor(container.quality),
		}
	end

	-- The game's colour, red when the reward would go past the currency's cap.
	local red, green, blue = GetColorForCurrencyReward(currencyID, amount):GetRGB()

	return {
		text = BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format(reward.texture, amount, reward.name),
		color = Color(red, green, blue),
	}
end

---@param questID number
---@param currencyID number
---@param isFirst boolean
---@return boolean
local function HasCurrencyWarModeBonus(questID, currencyID, isFirst)
	local applies, oncePerTooltip = C_CurrencyInfo.DoesWarModeBonusApply(currencyID)

	if not applies or (oncePerTooltip and not isFirst) then
		return false
	end

	return C_QuestLog.IsWorldQuest(questID) and not C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID)
end

---@param lines RewardLine[]
---@param questID number
local function AddCurrencies(lines, questID)
	local hasWarModeBonus = HasWarModeBonus(questID)

	for _, currency in ipairs(SortedCurrencies(questID)) do
		table.insert(lines, CurrencyLine(currency.reward))

		if hasWarModeBonus and HasCurrencyWarModeBonus(questID, currency.reward.currencyID, currency.isFirst) then
			table.insert(lines, WarModeLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT))
		end
	end
end

---@param lines RewardLine[]
---@param questID number
local function AddHonor(lines, questID)
	local honor = GetQuestLogRewardHonor(questID)

	if honor > 0 then
		table.insert(lines, {
			text = BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format(HONOR_ICON, honor, HONOR),
			color = Highlight(),
		})
	end
end

---@param lines RewardLine[]
---@param questID number
local function AddMoney(lines, questID)
	local money = GetQuestLogRewardMoney(questID)

	if money <= 0 then
		return
	end

	table.insert(lines, { text = MoneyFormatterUtil.FormatMoney(money, GameTooltipMoneyFormat), color = Highlight() })

	if HasWarModeBonus(questID) and C_QuestLog.IsWorldQuest(questID) then
		table.insert(lines, WarModeLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT))
	end
end

--- Every item, where the game's block shows only the first. A name or icon
--- still on its way from the server skips the item rather than drawing a gap.
---@param lines RewardLine[]
---@param questID number
local function AddItems(lines, questID)
	for index = 1, GetNumQuestLogRewards(questID) do
		local name, texture, count, quality = GetQuestLogRewardInfo(index, questID)

		if name and texture then
			local text = (count or 0) > 1
					and BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format(
						texture,
						HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(count),
						name
					)
				or BONUS_OBJECTIVE_REWARD_FORMAT:format(texture, name)

			table.insert(lines, { text = text, color = QualityColor(quality) })
		end
	end
end

---@param lines RewardLine[]
---@param questID number
local function AddSpells(lines, questID)
	for _, spellID in ipairs(C_QuestInfoSystem.GetQuestRewardSpells(questID) or {}) do
		local spell = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)

		if spell and spell.name and spell.texture then
			table.insert(lines, { text = BONUS_OBJECTIVE_REWARD_FORMAT:format(spell.texture, spell.name) })
		end
	end
end

--- In the order the game's block uses.
---@param questID number
---@return RewardLine[]
function QuestRewardReader.Lines(questID)
	local lines = {}

	AddExperience(lines, questID)
	AddArtifactPower(lines, questID)
	AddFavor(lines, questID)
	AddCurrencies(lines, questID)
	AddHonor(lines, questID)
	AddMoney(lines, questID)
	AddItems(lines, questID)
	AddSpells(lines, questID)

	return lines
end

Addon.QuestRewardReader = QuestRewardReader
