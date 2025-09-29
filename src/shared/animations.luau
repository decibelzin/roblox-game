local AnimationsModule = {
    -- Lista de animações indexadas (usar índice no DataStore ao invés de nome)
    list = {
        [1] = {
            name = "Wave",
            id = "507770239",
            category = "dance",
            rarity = "common"
        },
        [2] = {
            name = "Dance",
            id = "507777268", 
            category = "dance",
            rarity = "common"
        },
        [3] = {
            name = "Cheer",
            id = "507770677",
            category = "celebration", 
            rarity = "common"
        }
    },
    
    -- Mapeamento reverso para busca rápida por nome
    nameToIndex = { 
        ["Wave"] = 1,
        ["Dance"] = 2, 
        ["Cheer"] = 3
    },
}

-- Funções auxiliares para facilitar o uso
function AnimationsModule.getByIndex(index: number)
    return AnimationsModule.list[index]
end

function AnimationsModule.getByName(name: string)
    local index = AnimationsModule.nameToIndex[name]
    return index and AnimationsModule.list[index]
end

function AnimationsModule.getIndexByName(name: string)
    return AnimationsModule.nameToIndex[name]
end

function AnimationsModule.getByCategory(category: string)
    local result = {}
    for index, animation in pairs(AnimationsModule.list) do
        if animation.category == category then
            result[index] = animation
        end
    end
    return result
end

function AnimationsModule.getByRarity(rarity: string)
    local result = {}
    for index, animation in pairs(AnimationsModule.list) do
        if animation.rarity == rarity then
            result[index] = animation
        end
    end
    return result
end

-- Valida se um índice é válido
function AnimationsModule.isValidIndex(index: number)
    return type(index) == "number" and AnimationsModule.list[index] ~= nil
end

-- Obtém todas as animações como array ordenado
function AnimationsModule.getAllSorted()
    local sorted = {}
    for i = 1, #AnimationsModule.list do
        if AnimationsModule.list[i] then
            table.insert(sorted, {
                index = i,
                animation = AnimationsModule.list[i]
            })
        end
    end
    return sorted
end

return AnimationsModule