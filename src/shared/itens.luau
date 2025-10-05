export type DefItem = {
    id: number,
    name: string,
    color: Color3?,
    description: string?,
    index: string?,
    stackable: boolean?,
    canHotbar: boolean?,  -- Se o item pode ser colocado na hotbar (default: true)
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
        stackable = true,
        color = Color3.fromRGB(0, 170, 0),
        description = 'Uma poção de vida que restaura 50 pontos de vida.',
    },
    [3] = {
        id = 3,
        index = 'pocaodano',
        name = 'Poção de Dano',
        color = Color3.fromRGB(170, 0, 170),
        description = 'Uma poção de dano que causa 50 pontos de dano aos inimigos.',
    },
    [4] = {
        id = 4,
        index = 'pocaodefogo',
        name = 'Poção de Fogo', 
        color = Color3.fromRGB(0, 0, 170),
        description = 'Uma poção de fogo que causa 50 pontos de dano de fogo aos inimigos.',
    },
    [5] = {
        id = 5,
        index = 'pocaodearmadura',
        name = 'Poção de Armadura', 
        color = Color3.fromRGB(0, 170, 170),
        description = 'Uma poção de armadura que restaura 50 pontos de armadura.',
    },
    [6] = {
        id = 6,
        index = 'pocaodenergia',
        name = 'Poção de Energia',
        color = Color3.fromRGB(170, 170, 0),
        description = 'Uma poção de energia que restaura 50 pontos de energia.',
    },
    [7] = {
        id = 7,
        index = 'pocaodestamina',
        name = 'Poção de Stamina',
        color = Color3.fromRGB(0, 0, 170),
        description = 'Uma poção de stamina que restaura 50 pontos de stamina.',
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
    maxSlots = 50,
    maxHotbarSlots = 4,
    byIndex = ITEMS_BY_INDEX
}