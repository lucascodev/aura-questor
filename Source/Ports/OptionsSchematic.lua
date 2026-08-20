---@meta

--- Uma célula da grade de uma página de opções. Com key, o que faltar vem do
--- catálogo por inferência; sem key, a célula descreve o próprio controle.
--- build entrega um frame pronto, para conteúdo que só a página sabe desenhar.
---@class SchematicCell
---@field key? string
---@field style? "switch"|"slider"|"dropdown"|"dropdownRow"|"swatch"|"fact"
---@field span? number 2 ocupa as duas colunas.
---@field width? number
---@field controlWidth? number
---@field label? string
---@field hint? string
---@field suffix? string
---@field maximum? number|fun(): number Teto do controle quando o do catálogo não serve.
---@field value? string
---@field choices? fun(): PreferenceChoice[]
---@field get? fun(): any
---@field set? fun(...)
---@field isEnabled? fun(): boolean
---@field build? fun(parent: table, width: number): table

--- Uma seção vira um card. As linhas alternam listas de células e o marcador
--- "divider", que desenha a régua interna.
---@class SchematicSection
---@field title? string
---@field rows (SchematicCell[]|"divider")[]

---@alias Schematic SchematicSection[]
