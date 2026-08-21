--- Fakes e construtores compartilhados pelas suítes.
---
--- Todos são tabelas simples: o Core recebe colaboradores por injeção, então
--- não há framework de mock envolvido.

local Support = {}

---@param overrides table?
---@return TrackerEntry
function Support.Entry(overrides)
	local entry = {
		id = 1,
		kind = "quest",
		title = "Uma missão",
		objectives = {},
		isComplete = false,
		canFindGroup = false,
	}

	for key, value in pairs(overrides or {}) do
		entry[key] = value
	end

	return entry
end

---@param id string
---@param order number
---@param entries TrackerEntry[]
---@return TrackerSection
function Support.Section(id, order, entries)
	return { id = id, title = id, order = order, entries = entries }
end

--- SectionProvider que devolve sempre a mesma seção.
---@param id string
---@param order number
---@param entries TrackerEntry[]
---@return SectionProvider
function Support.Provider(id, order, entries)
	return {
		Collect = function()
			return { Support.Section(id, order, entries) }
		end,
	}
end

--- Logger que guarda o que recebeu, para o teste conferir o aviso.
---@return table
function Support.Logger()
	return {
		infos = {},
		warnings = {},
		Info = function(self, message)
			table.insert(self.infos, message)
		end,
		Warn = function(self, message)
			table.insert(self.warnings, message)
		end,
	}
end

--- QuestSource sobre uma lista fixa, registrando cada SetWatched.
---@param quests Quest[]
---@param refuseAfter number? A partir de quantas chamadas o jogo recusa.
---@return table
function Support.QuestSource(quests, refuseAfter)
	return {
		quests = quests,
		calls = {},
		ListAll = function(self)
			return self.quests
		end,
		SetWatched = function(self, questID, isWatched)
			table.insert(self.calls, { questID = questID, isWatched = isWatched })

			if refuseAfter and #self.calls > refuseAfter then
				return false
			end

			return true
		end,
	}
end

--- TrackerRenderer que anota o que foi pedido, sem desenhar nada.
---@return table
function Support.Renderer()
	return {
		shown = nil,
		rendered = nil,
		appearance = nil,
		font = nil,
		scale = nil,
		editing = nil,
		itemButtonsShown = nil,
		progressBarTexture = nil,
		Render = function(self, sections)
			self.rendered = sections
		end,
		SetShown = function(self, isShown)
			self.shown = isShown
		end,
		SetAppearance = function(self, appearance)
			self.appearance = appearance
		end,
		SetFont = function(self, style)
			self.font = style
		end,
		SetItemButtonsShown = function(self, isShown)
			self.itemButtonsShown = isShown
		end,
		SetProgressBarTexture = function(self, path)
			self.progressBarTexture = path
		end,
		SetProgressBarHeight = function(self, height)
			self.progressBarHeight = height
		end,
		SetProgressBarStyle = function(self, style)
			self.progressBarStyle = style
		end,
		SetScale = function(self, scale)
			self.scale = scale
		end,
		SetEditing = function(self, isEditing)
			self.editing = isEditing
		end,
		ResetPosition = function() end,
		Expand = function(self)
			self.expanded = (self.expanded or 0) + 1
		end,
	}
end

---@return table
function Support.BlizzardTracker()
	return {
		hidden = nil,
		SetHidden = function(self, isHidden)
			self.hidden = isHidden
		end,
	}
end

---@return table
function Support.Widget()
	return {
		shown = nil,
		SetShown = function(self, isShown)
			self.shown = isShown
		end,
	}
end

--- AppearanceSources que devolve o nome recebido, para o teste ver o que
--- chegou sem precisar de acervo de mídia.
---@return AppearanceSources
---@return GameState
function Support.GameState(isChallengeActive)
	return {
		IsChallengeActive = function()
			return isChallengeActive == true
		end,
	}
end

function Support.AppearanceSources()
	local function echo(name)
		return name
	end

	return {
		Font = echo,
		Background = echo,
		Border = echo,
		ProgressBar = echo,
		ClassColor = function()
			return { red = 1, green = 0, blue = 0 }
		end,
	}
end

return Support
