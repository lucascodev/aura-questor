---@meta

--- A cell in the grid of an options page. With a key, whatever is missing comes
--- from the catalog; without one, the cell describes its own control. build
--- hands over a ready frame, for content only the page knows how to draw.
---@class SchematicCell
---@field key? string
---@field style? "switch"|"slider"|"dropdown"|"dropdownRow"|"swatch"|"fact"
---@field span? number 2 ocupa as duas colunas.
---@field width? number
---@field controlWidth? number
---@field label? string
---@field hint? string
---@field suffix? string
---@field maximum? number|fun(): number Ceiling for the control when the catalog one does not fit.
---@field value? string
---@field choices? fun(): PreferenceChoice[]
---@field get? fun(): any
---@field set? fun(...)
---@field isEnabled? fun(): boolean
---@field build? fun(parent: table, width: number): table

--- A section becomes a card. Rows alternate lists of cells and the "divider"
--- marker, which draws the inner rule.
---@class SchematicSection
---@field title? string
---@field rows (SchematicCell[]|"divider")[]

---@alias Schematic SchematicSection[]
