return function(_, T)
	local ADDON_TOC = "AuraQuestor.toc"
	local BRIDGE_TOC = "Bridge/AuraTrackerQuestor/AuraTrackerQuestor.toc"

	---@param path string
	---@return string
	local function ReadInterface(path)
		local file = assert(io.open(path, "r"))
		local content = file:read("*a")
		file:close()

		return assert(content:match("## Interface: ([^\r\n]+)"), path .. " sem ## Interface")
	end

	T.Suite("Package", function()
		--- A ponte desatualizada e o cliente com "carregar addons desatualizados"
		--- desmarcado deixam a adocao morrer em silencio a cada patch.
		T.Test("a ponte declara o mesmo Interface que o addon", function()
			T.Equals(ReadInterface(BRIDGE_TOC), ReadInterface(ADDON_TOC))
		end)
	end)
end
