export type DefItem = {
    id: number,
    name: string,
    color: Color3?,
    description: string?,
    index: string?,
}

export type DefItemList = {[number]: DefItem}
export type DefItemNameMap = {[string]: number}

local ITEMS = {
    [1] = {
        id = 1,
        index = 'espadadefogo',
        name = 'Espada de Fogo',
        color = Color3.fromRGB(170, 0, 0),
        description = 'Uma espada de fogo que causa dano de fogo aos inimigos.',
    },
    [2] = {
        id = 2,
        index = 'pocaodevida',
        name = 'Poção de Vida',
        color = Color3.fromRGB(0, 170, 0),
        description = 'Uma poção de vida que restaura 50 pontos de vida.',
    }
} :: DefItemList

-- Mapa reverso: nome -> id (para fast lookup por nome)
local ITEMS_BY_INDEX = {} :: DefItemNameMap
for id, item in pairs(ITEMS) do
    -- Normaliza o nome (lowercase, sem espaços extras)
    local trimmed = string.gsub(item.index, "^%s*(.-)%s*$", "%1")
    local normalizedName = string.lower(trimmed)
    ITEMS_BY_INDEX[normalizedName] = id
end

return {
    list = ITEMS,
    byIndex = ITEMS_BY_INDEX
}
