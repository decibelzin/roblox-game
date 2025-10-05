local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local STORAGE_KEY = STORAGE_DEFINITIONS.playerItems
local ORDER_STORAGE_KEY = STORAGE_DEFINITIONS.itemsOrder
local HOTBAR_STORAGE_KEY = STORAGE_DEFINITIONS.hotbarItems
local ITEMS_MODULE = require(game.ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list
local MAX_HOTBAR_SLOTS = ITEMS_MODULE.maxHotbarSlots or 4
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local playerItemsStore = DataStoreService:GetDataStore(STORAGE_KEY)
local itemsOrderStore = DataStoreService:GetDataStore(ORDER_STORAGE_KEY)
local hotbarStore = DataStoreService:GetDataStore(HOTBAR_STORAGE_KEY)
local playerItemsCache = {} -- Cache: userId -> {itemId -> quantidade}
local playerOrderCache = {} -- Cache: userId -> {itemId -> posição}
local hotbarCache = {} -- Cache: userId -> {[slotIndex] = {itemId, quantity}}

-- RemoteEvents
local getPlayerItemsEvent = Instance.new("RemoteFunction")
getPlayerItemsEvent.Name = "GetPlayerItems"
getPlayerItemsEvent.Parent = ReplicatedStorage

local updatePlayerItemsEvent = Instance.new("RemoteEvent")
updatePlayerItemsEvent.Name = "UpdatePlayerItems"
updatePlayerItemsEvent.Parent = ReplicatedStorage

local reorderItemsEvent = Instance.new("RemoteEvent")
reorderItemsEvent.Name = "ReorderItems"
reorderItemsEvent.Parent = ReplicatedStorage

local getHotbarFunction = Instance.new("RemoteFunction")
getHotbarFunction.Name = "GetHotbar"
getHotbarFunction.Parent = ReplicatedStorage

local updateHotbarEvent = Instance.new("RemoteEvent")
updateHotbarEvent.Name = "UpdateHotbar"
updateHotbarEvent.Parent = ReplicatedStorage

local setHotbarSlotEvent = Instance.new("RemoteEvent")
setHotbarSlotEvent.Name = "SetHotbarSlot"
setHotbarSlotEvent.Parent = ReplicatedStorage

local swapHotbarSlotsEvent = Instance.new("RemoteEvent")
swapHotbarSlotsEvent.Name = "SwapHotbarSlots"
swapHotbarSlotsEvent.Parent = ReplicatedStorage

local moveHotbarToInventorySlotEvent = Instance.new("RemoteEvent")
moveHotbarToInventorySlotEvent.Name = "MoveHotbarToInventorySlot"
moveHotbarToInventorySlotEvent.Parent = ReplicatedStorage

local PlayerItemsModule = {}

--- Valida se um item existe na configuração
local function isValidItem(itemId: number): boolean
    return type(itemId) == "number" and ITEMS_CONFIG[itemId] ~= nil
end

--- Valida se um item pode ser colocado na hotbar
local function canItemBeHotbar(itemId: number): boolean
    if not isValidItem(itemId) then return false end
    local itemConfig = ITEMS_CONFIG[itemId]
    -- Se canHotbar não está definido, assume true
    return itemConfig.canHotbar ~= false
end

--- Envia atualização de itens E ordem para o cliente
local function notifyClient(player: Player)
    local items = PlayerItemsModule.getPlayerItemsWithInfo(player)  -- ✅ Retorna com info completa
    local order = PlayerItemsModule.getPlayerOrder(player)
    
    updatePlayerItemsEvent:FireClient(player, {items = items, order = order})
end

--- Envia atualização da hotbar para o cliente
local function notifyHotbarClient(player: Player)
    local hotbar = PlayerItemsModule.getHotbar(player)
    
    -- Normalizar chaves antes de enviar (garantir que sejam números)
    local normalizedHotbar = {}
    for slotIndex, slotData in pairs(hotbar) do
        local slotNum = tonumber(slotIndex)
        if slotNum then
            normalizedHotbar[slotNum] = slotData
        end
    end
    
    updateHotbarEvent:FireClient(player, normalizedHotbar)
end

--- Envia atualização completa (inventário + hotbar) para o cliente
--- Usa isso para operações que afetam ambos simultaneamente
local function notifyFullState(player: Player)
    local items = PlayerItemsModule.getPlayerItemsWithInfo(player)  -- ✅ Retorna com info completa
    local order = PlayerItemsModule.getPlayerOrder(player)
    local hotbar = PlayerItemsModule.getHotbar(player)
    
    -- Normalizar chaves da hotbar antes de enviar (garantir que sejam números)
    local normalizedHotbar = {}
    for slotIndex, slotData in pairs(hotbar) do
        local slotNum = tonumber(slotIndex)
        if slotNum then
            normalizedHotbar[slotNum] = slotData
        end
    end
    
    -- Enviar ambos (cliente receberá na ordem correta)
    updatePlayerItemsEvent:FireClient(player, {items = items, order = order})
    updateHotbarEvent:FireClient(player, normalizedHotbar)
end

--- Valida dados de itens
local function validateItemsData(items: {[number]: number}): boolean
    if type(items) ~= "table" then
        return false
    end
    
    for itemId, quantity in pairs(items) do
        local itemIdNum = tonumber(itemId)  -- Converter para número (DataStore pode retornar string)
        if not itemIdNum or not isValidItem(itemIdNum) or type(quantity) ~= "number" or quantity < 0 then
            return false
        end
    end
    
    return true
end

--- Carrega itens do jogador do DataStore
function PlayerItemsModule.loadPlayerItems(player: Player): {[number]: number}
    local userId = tostring(player.UserId)
    
    local success, items = pcall(function()
        return playerItemsStore:GetAsync(userId)
    end)
    
    local playerItems = {}
    
    if success and items and type(items) == "table" then
        -- Validar e filtrar itens inválidos
        for itemId, quantity in pairs(items) do
            -- 🔧 Converter itemId para número (DataStore pode retornar como string)
            local itemIdNum = tonumber(itemId)
            
            if itemIdNum and isValidItem(itemIdNum) and type(quantity) == "number" and quantity > 0 then
                playerItems[itemIdNum] = quantity  -- Usar número ao invés de string
            else
                print("  ❌ Inválido! itemIdNum:", itemIdNum, "isValidItem:", itemIdNum and isValidItem(itemIdNum) or "false")
            end
        end
    end
    
    playerItemsCache[player.UserId] = playerItems
    return playerItems
end

--- Salva itens do jogador no DataStore
function PlayerItemsModule.savePlayerItems(player: Player): boolean
    local userId = player.UserId
    local items = playerItemsCache[userId] or {}
    
    if not validateItemsData(items) then
        warn("❌ Dados de itens inválidos para jogador:", player.Name)
        return false
    end
    
    local success = pcall(function()
        playerItemsStore:SetAsync(tostring(userId), items)
    end)
    
    if not success then
        warn("❌ Erro ao salvar itens para jogador:", player.Name)
    end
    
    return success
end

--- Obtém itens do jogador (com cache)
function PlayerItemsModule.getPlayerItems(player: Player): {[number]: number}
    if not playerItemsCache[player.UserId] then
        PlayerItemsModule.loadPlayerItems(player)
    end
    
    local items = playerItemsCache[player.UserId] or {}
    
    return items
end

--- Adiciona item ao inventário do jogador
--- @param shouldNotify (opcional) Se deve notificar o cliente (default: true)
function PlayerItemsModule.addItem(player: Player, itemId: number, quantity: number?, shouldNotify: boolean?): boolean
    if not isValidItem(itemId) then
        warn("❌ Item ID inválido:", itemId)
        return false
    end
    
    local amount = quantity or 1
    if type(amount) ~= "number" or amount <= 0 then
        warn("❌ Quantidade inválida:", amount)
        return false
    end
    
    -- Inicializa cache se necessário
    if not playerItemsCache[player.UserId] then
        playerItemsCache[player.UserId] = {}
    end
    if not playerOrderCache[player.UserId] then
        playerOrderCache[player.UserId] = {}
    end
    
    local playerItems = playerItemsCache[player.UserId]
    local order = playerOrderCache[player.UserId]
    local currentAmount = playerItems[itemId] or 0
    local itemConfig = ITEMS_CONFIG[itemId]
    
    -- 🔧 Criar entradas na ordem para items não-stackable
    if itemConfig and not itemConfig.stackable then
        -- Para cada nova unidade, criar um uniqueId e encontrar posição livre
        for i = 1, amount do
            local newIndex = currentAmount + i
            local uniqueId = tostring(itemId) .. "_" .. tostring(newIndex)
            
            -- Encontrar próxima posição livre
            local usedPositions = {}
            for _, pos in pairs(order) do
                usedPositions[pos] = true
            end
            
            local nextPosition = 1
            while usedPositions[nextPosition] do
                nextPosition = nextPosition + 1
            end
            
            order[uniqueId] = nextPosition
        end
    end
    
    playerItems[itemId] = currentAmount + amount
    
    -- Salvar AMBOS no DataStore
    local successItems = PlayerItemsModule.savePlayerItems(player)
    local successOrder = PlayerItemsModule.savePlayerOrder(player)
    
    if successItems and successOrder and (shouldNotify == nil or shouldNotify == true) then
        -- Notificar cliente com itens E ordem (apenas se shouldNotify não for false)
        notifyClient(player)
    end
    
    return successItems and successOrder
end

--- Remove item do inventário do jogador
--- @param shouldNotify (opcional) Se deve notificar o cliente (default: true)
function PlayerItemsModule.removeItem(player: Player, itemId: number, quantity: number?, shouldNotify: boolean?): boolean
    if not isValidItem(itemId) then
        warn("❌ Item ID inválido:", itemId)
        return false
    end
    
    local amount = quantity or 1
    if type(amount) ~= "number" or amount <= 0 then
        warn("❌ Quantidade inválida:", amount)
        return false
    end
    
    local playerItems = PlayerItemsModule.getPlayerItems(player)
    local currentAmount = playerItems[itemId] or 0
    
    if currentAmount < amount then
        warn("❌ Jogador não tem quantidade suficiente do item")
        return false
    end
    
    local newAmount = currentAmount - amount
    if newAmount <= 0 then
        playerItems[itemId] = nil
    else
        playerItems[itemId] = newAmount
    end
    
    -- Salvar no DataStore
    local success = PlayerItemsModule.savePlayerItems(player)
    
    if success and (shouldNotify == nil or shouldNotify == true) then
        -- Notificar cliente com itens E ordem (apenas se shouldNotify não for false)
        notifyClient(player)
    end
    
    return success
end

--- Define quantidade exata de um item
function PlayerItemsModule.setItem(player: Player, itemId: number, quantity: number): boolean
    if not isValidItem(itemId) then
        warn("❌ Item ID inválido:", itemId)
        return false
    end
    
    if type(quantity) ~= "number" or quantity < 0 then
        warn("❌ Quantidade inválida:", quantity)
        return false
    end
    
    -- Inicializa cache se necessário
    if not playerItemsCache[player.UserId] then
        playerItemsCache[player.UserId] = {}
    end
    
    local playerItems = playerItemsCache[player.UserId]
    
    if quantity == 0 then
        playerItems[itemId] = nil
    else
        playerItems[itemId] = quantity
    end
    
    -- Salvar no DataStore
    local success = PlayerItemsModule.savePlayerItems(player)
    
    if success then
        -- Notificar cliente com itens E ordem
        notifyClient(player)
    end
    
    return success
end

--- Verifica se o jogador possui um item
function PlayerItemsModule.hasItem(player: Player, itemId: number, quantity: number?): boolean
    if not isValidItem(itemId) then
        return false
    end
    
    local playerItems = PlayerItemsModule.getPlayerItems(player)
    local currentAmount = playerItems[itemId] or 0
    local requiredAmount = quantity or 1
    
    return currentAmount >= requiredAmount
end

--- Obtém quantidade de um item específico
function PlayerItemsModule.getItemQuantity(player: Player, itemId: number): number
    if not isValidItem(itemId) then
        return 0
    end
    
    local playerItems = PlayerItemsModule.getPlayerItems(player)
    return playerItems[itemId] or 0
end

--- Limpa todos os itens do jogador
function PlayerItemsModule.clearAllItems(player: Player): boolean
    playerItemsCache[player.UserId] = {}
    playerOrderCache[player.UserId] = {}
    hotbarCache[player.UserId] = {}
    
    local successItems = PlayerItemsModule.savePlayerItems(player)
    local successOrder = PlayerItemsModule.savePlayerOrder(player)
    local successHotbar = PlayerItemsModule.saveHotbar(player)
    
    if successItems and successOrder and successHotbar then
        -- Notificar cliente com estado completo vazio
        updatePlayerItemsEvent:FireClient(player, {items = {}, order = {}})
        updateHotbarEvent:FireClient(player, {})
        return true
    else
        warn("❌ Erro ao limpar todos os itens")
        return false
    end
end

--- Obtém informações completas dos itens do jogador (com dados da config)
function PlayerItemsModule.getPlayerItemsWithInfo(player: Player): {[number]: {item: any, quantity: number}}
    local playerItems = PlayerItemsModule.getPlayerItems(player)
    local itemsWithInfo = {}
    
    for itemId, quantity in pairs(playerItems) do
        local itemConfig = ITEMS_CONFIG[itemId]
        if itemConfig then
            itemsWithInfo[itemId] = {
                item = itemConfig,
                quantity = quantity
            }
        end
    end
    
    return itemsWithInfo
end

--- Carrega a ordem dos itens do jogador do DataStore
function PlayerItemsModule.loadPlayerOrder(player: Player): {[any]: number}
    local userId = tostring(player.UserId)
    
    local success, order = pcall(function()
        return itemsOrderStore:GetAsync(userId)
    end)
    
    local playerOrder = {}
    
    if success and order and type(order) == "table" then
        playerOrder = order
    end
    
    playerOrderCache[player.UserId] = playerOrder
    return playerOrder
end

--- Salva a ordem dos itens do jogador no DataStore
function PlayerItemsModule.savePlayerOrder(player: Player): boolean
    local userId = player.UserId
    local order = playerOrderCache[userId] or {}
    
    local success = pcall(function()
        itemsOrderStore:SetAsync(tostring(userId), order)
    end)
    
    if not success then
        warn("❌ Erro ao salvar ordem de itens para jogador:", player.Name)
    end
    
    return success
end

--- Obtém a ordem dos itens do jogador (com cache)
function PlayerItemsModule.getPlayerOrder(player: Player): {[any]: number}
    if not playerOrderCache[player.UserId] then
        PlayerItemsModule.loadPlayerOrder(player)
    end
    
    return playerOrderCache[player.UserId] or {}
end

--- Reordena os itens do jogador
function PlayerItemsModule.reorderItems(player: Player, newOrder: any): boolean
    if not newOrder or type(newOrder) ~= "table" then
        warn("❌ Ordem de itens inválida")
        return false
    end
    
    -- Validar que todos os itemIds na ordem existem no inventário do jogador
    local playerItems = PlayerItemsModule.getPlayerItems(player)
    for uniqueId, position in pairs(newOrder) do
        -- Extrair itemId do uniqueId (pode ser "1" ou "1_2")
        local itemIdStr = string.match(tostring(uniqueId), "^(%d+)")
        local itemId = tonumber(itemIdStr)
        
        if not itemId or not playerItems[itemId] then
            warn("❌ Tentativa de reordenar item que o jogador não possui:", uniqueId, itemId)
            return false
        end
        
        if type(position) ~= "number" or position < 0 then
            warn("❌ Posição inválida para item:", uniqueId)
            return false
        end
    end
    
    -- Atualizar cache
    playerOrderCache[player.UserId] = newOrder
    
    -- Salvar no DataStore
    return PlayerItemsModule.savePlayerOrder(player)
end

-- ========================================
-- FUNÇÕES DE HOTBAR
-- ========================================

--- Carrega hotbar do jogador do DataStore
function PlayerItemsModule.loadHotbar(player: Player): {[number]: {itemId: number, quantity: number}?}
    local userId = tostring(player.UserId)
    
    local success, hotbar = pcall(function()
        return hotbarStore:GetAsync(userId)
    end)
    
    local playerHotbar = {}
    
    if success and hotbar and type(hotbar) == "table" then
        -- Validar e filtrar slots inválidos
        for slotIndex, slotData in pairs(hotbar) do
            -- DataStore SEMPRE converte chaves numéricas em strings, converter de volta
            local slotNum = tonumber(slotIndex)
            
            if slotNum and slotNum >= 1 and slotNum <= MAX_HOTBAR_SLOTS then
                if type(slotData) == "table" and slotData.itemId and slotData.quantity then
                    if isValidItem(slotData.itemId) and canItemBeHotbar(slotData.itemId) then
                        -- Garantir que salvamos com chave numérica no cache
                        playerHotbar[slotNum] = {
                            itemId = slotData.itemId,
                            quantity = slotData.quantity
                        }
                    end
                end
            end
        end
    end
    
    hotbarCache[player.UserId] = playerHotbar
    return playerHotbar
end

--- Salva hotbar do jogador no DataStore
function PlayerItemsModule.saveHotbar(player: Player): boolean
    local userId = player.UserId
    local hotbar = hotbarCache[userId] or {}
    
    local success = pcall(function()
        hotbarStore:SetAsync(tostring(userId), hotbar)
    end)
    
    if not success then
        warn("❌ Erro ao salvar hotbar para jogador:", player.Name)
    end
    
    return success
end

--- Obtém hotbar do jogador (com cache)
function PlayerItemsModule.getHotbar(player: Player): {[number]: {itemId: number, quantity: number}?}
    if not hotbarCache[player.UserId] then
        PlayerItemsModule.loadHotbar(player)
    end
    
    -- Cache já deve ter chaves normalizadas, mas garantir
    local hotbar = hotbarCache[player.UserId] or {}
    
    -- Validar que todas as chaves são números (segurança extra)
    local normalizedHotbar = {}
    for slotIndex, slotData in pairs(hotbar) do
        if type(slotIndex) == "number" then
            normalizedHotbar[slotIndex] = slotData
        else
            -- Se por algum motivo há uma string, tentar converter
            local slotNum = tonumber(slotIndex)
            if slotNum then
                normalizedHotbar[slotNum] = slotData
            end
        end
    end
    
    return normalizedHotbar
end

--- Define um slot da hotbar (move item do inventário para hotbar)
function PlayerItemsModule.setHotbarSlot(player: Player, slotIndex: number, itemId: number?, quantity: number?): boolean
    print("🔧 [setHotbarSlot] Iniciando processamento...")
    
    -- Validar slot
    if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > MAX_HOTBAR_SLOTS then
        warn("❌ Slot de hotbar inválido:", slotIndex)
        return false
    end
    print("  ✅ Slot válido:", slotIndex)
    
    -- Inicializar cache se necessário
    if not hotbarCache[player.UserId] then
        hotbarCache[player.UserId] = {}
    end
    
    local hotbar = hotbarCache[player.UserId]
    
    -- Se itemId é nil, está limpando o slot (mover de volta para inventário)
    if not itemId then
        local oldSlotData = hotbar[slotIndex]
        if oldSlotData then
            -- Devolver item ao inventário (SEM notificar ainda)
            PlayerItemsModule.addItem(player, oldSlotData.itemId, oldSlotData.quantity, false)
            
            -- 📍 IMPORTANTE: Adicionar posição no order para o item devolvido
            local order = playerOrderCache[player.UserId]
            if order then
                local oldItemConfig = ITEMS_CONFIG[oldSlotData.itemId]
                local oldItemId = oldSlotData.itemId
                local playerItems = playerItemsCache[player.UserId]
                
                -- Determinar uniqueId para o item devolvido
                local uniqueId
                if oldItemConfig and oldItemConfig.stackable then
                    -- Item stackable: usar apenas o itemId
                    uniqueId = tostring(oldItemId)
                else
                    -- Item não-stackable: usar quantidade total no inventário
                    local totalInInventory = playerItems[oldItemId] or 0
                    uniqueId = tostring(oldItemId) .. "_" .. tostring(totalInInventory)
                end
                
                -- Encontrar próximo slot livre
                local usedPositions = {}
                for _, pos in pairs(order) do
                    usedPositions[pos] = true
                end
                
                local nextPosition = 1
                while usedPositions[nextPosition] do
                    nextPosition = nextPosition + 1
                end
                
                order[uniqueId] = nextPosition
                -- print("   📍 Item devolvido ao inventário:", uniqueId, "→ pos", nextPosition)
            end
            
            hotbar[slotIndex] = nil
            -- print("✅ Slot", slotIndex, "limpo: Item", oldSlotData.itemId, "devolvido ao inventário")
        end
    else
        -- Validar item
        if not isValidItem(itemId) then
            warn("❌ Item ID inválido:", itemId)
            return false
        end
        
        if not canItemBeHotbar(itemId) then
            warn("❌ Item não pode ser colocado na hotbar:", itemId)
            return false
        end
        
        local amount = quantity or 1
        if type(amount) ~= "number" or amount <= 0 then
            warn("❌ Quantidade inválida:", amount)
            return false
        end
        
        -- Verificar se jogador tem o item no inventário
        print("  📦 Verificando se player tem item", itemId, "x", amount)
        local hasItem = PlayerItemsModule.hasItem(player, itemId, amount)
        print("  📦 Player tem item?", hasItem)
        
        if not hasItem then
            warn("❌ Jogador não possui item suficiente no inventário")
            local playerItems = playerItemsCache[player.UserId]
            if playerItems then
                print("  📦 Itens do jogador:", game:GetService("HttpService"):JSONEncode(playerItems))
            end
            return false
        end
        
        -- Se já tem algo no slot, devolver ao inventário primeiro (SEM notificar)
        local oldSlotData = hotbar[slotIndex]
        if oldSlotData then
            PlayerItemsModule.addItem(player, oldSlotData.itemId, oldSlotData.quantity, false)
            
            -- 📍 IMPORTANTE: Adicionar posição no order para o item devolvido
            local order = playerOrderCache[player.UserId]
            if order then
                local oldItemConfig = ITEMS_CONFIG[oldSlotData.itemId]
                local oldItemId = oldSlotData.itemId
                local playerItems = playerItemsCache[player.UserId]
                
                -- Determinar uniqueId para o item devolvido
                local uniqueId
                if oldItemConfig and oldItemConfig.stackable then
                    -- Item stackable: usar apenas o itemId
                    uniqueId = tostring(oldItemId)
                else
                    -- Item não-stackable: usar quantidade total no inventário
                    local totalInInventory = playerItems[oldItemId] or 0
                    uniqueId = tostring(oldItemId) .. "_" .. tostring(totalInInventory)
                end
                
                -- Encontrar próximo slot livre
                local usedPositions = {}
                for _, pos in pairs(order) do
                    usedPositions[pos] = true
                end
                
                local nextPosition = 1
                while usedPositions[nextPosition] do
                    nextPosition = nextPosition + 1
                end
                
                order[uniqueId] = nextPosition
                --print("   📍 Item devolvido ao inventário:", uniqueId, "→ pos", nextPosition)
            end
        end
        
        -- 🐛 BUG FIX: Remover do order ANTES de remover do inventário
        local order = playerOrderCache[player.UserId]
        if order then
            local itemConfig = ITEMS_CONFIG[itemId]
            
            -- Determinar uniqueId para remover do order
            if itemConfig and itemConfig.stackable then
                -- Item stackable: usar apenas o itemId
                local uniqueId = tostring(itemId)
                order[uniqueId] = nil
                print("  🗑️ Removido do order:", uniqueId)
            else
                -- Item não-stackable: remover TODAS as unidades deste item do order
                -- porque vamos remover do inventário
                local itemsToRemove = {}
                for uniqueId, _ in pairs(order) do
                    local idStr = string.match(tostring(uniqueId), "^(%d+)")
                    local uniqueItemId = tonumber(idStr)
                    if uniqueItemId == itemId then
                        table.insert(itemsToRemove, uniqueId)
                    end
                end
                
                -- Remover apenas a quantidade necessária
                for i = 1, math.min(amount, #itemsToRemove) do
                    order[itemsToRemove[i]] = nil
                    print("  🗑️ Removido do order:", itemsToRemove[i])
                end
            end
        end
        
        -- Remover do inventário (SEM notificar)
        PlayerItemsModule.removeItem(player, itemId, amount, false)
        
        -- Adicionar ao slot da hotbar
        hotbar[slotIndex] = {
            itemId = itemId,
            quantity = amount
        }
    end
    
    -- Salvar todos os dados
    local successItems = PlayerItemsModule.savePlayerItems(player)
    local successOrder = PlayerItemsModule.savePlayerOrder(player)
    local successHotbar = PlayerItemsModule.saveHotbar(player)
    
    print("  💾 Salvando dados... Items:", successItems, "Order:", successOrder, "Hotbar:", successHotbar)
    
    if successItems and successOrder and successHotbar then
        print("  📤 Notificando cliente com estado completo")
        -- Notificar TUDO de uma vez (estado completo e consistente)
        notifyFullState(player)
        print("  ✅ SetHotbarSlot concluído com sucesso!")
        return true
    else
        warn("❌ Erro ao salvar dados do jogador")
        return false
    end
end

--- Remove item da hotbar e devolve ao inventário
function PlayerItemsModule.clearHotbarSlot(player: Player, slotIndex: number): boolean
    return PlayerItemsModule.setHotbarSlot(player, slotIndex, nil, nil)
end

--- Faz swap entre dois slots da hotbar (sem mexer no inventário)
function PlayerItemsModule.swapHotbarSlots(player: Player, slotIndex1: number, slotIndex2: number): boolean
    -- Validar slots
    if type(slotIndex1) ~= "number" or slotIndex1 < 1 or slotIndex1 > MAX_HOTBAR_SLOTS then
        warn("❌ Slot 1 de hotbar inválido:", slotIndex1)
        return false
    end
    
    if type(slotIndex2) ~= "number" or slotIndex2 < 1 or slotIndex2 > MAX_HOTBAR_SLOTS then
        warn("❌ Slot 2 de hotbar inválido:", slotIndex2)
        return false
    end
    
    if slotIndex1 == slotIndex2 then
        warn("❌ Slots são iguais")
        return false
    end
    
    -- Inicializar cache se necessário
    if not hotbarCache[player.UserId] then
        hotbarCache[player.UserId] = {}
    end
    
    local hotbar = hotbarCache[player.UserId]
    
    -- Fazer swap simples (pode ser nil em um ou ambos os slots)
    local temp = hotbar[slotIndex1]
    hotbar[slotIndex1] = hotbar[slotIndex2]
    hotbar[slotIndex2] = temp
    
    -- Salvar hotbar
    local success = PlayerItemsModule.saveHotbar(player)
    
    if success then
        -- Notificar apenas hotbar (inventário não mudou)
        notifyHotbarClient(player)
        return true
    else
        warn("❌ Erro ao salvar hotbar após swap")
        return false
    end
end

--- Move item da hotbar para um slot específico do inventário
function PlayerItemsModule.moveHotbarToInventorySlot(player: Player, hotbarSlotIndex: number, targetLayoutOrder: number): boolean
    print("🔧 [moveHotbarToInventorySlot] Recebido:")
    print("  - Player:", player.Name)
    print("  - Hotbar Slot:", hotbarSlotIndex)
    print("  - Target Layout Order:", targetLayoutOrder)
    
    -- Validar hotbar slot
    if type(hotbarSlotIndex) ~= "number" or hotbarSlotIndex < 1 or hotbarSlotIndex > MAX_HOTBAR_SLOTS then
        warn("❌ Slot de hotbar inválido:", hotbarSlotIndex)
        return false
    end
    
    -- Validar layout order
    if type(targetLayoutOrder) ~= "number" or targetLayoutOrder < 1 then
        warn("❌ Layout order inválido:", targetLayoutOrder)
        return false
    end
    
    print("  ✅ Validações passaram")
    
    -- Inicializar caches se necessário
    if not hotbarCache[player.UserId] then
        hotbarCache[player.UserId] = {}
    end
    if not playerOrderCache[player.UserId] then
        playerOrderCache[player.UserId] = {}
    end
    if not playerItemsCache[player.UserId] then
        playerItemsCache[player.UserId] = {}
    end
    
    local hotbar = hotbarCache[player.UserId]
    local order = playerOrderCache[player.UserId]
    local playerItems = playerItemsCache[player.UserId]
    
    -- Obter dados do slot da hotbar
    local slotData = hotbar[hotbarSlotIndex]
    if not slotData then
        warn("❌ Slot da hotbar está vazio:", hotbarSlotIndex)
        return false
    end
    
    local hotbarItemId = slotData.itemId
    local hotbarQuantity = slotData.quantity
    
    -- Verificar se existe um item na posição alvo (para fazer SWAP)
    local conflictingUniqueId = nil
    local conflictingItemId = nil
    
    print("  🔍 Verificando itens na posição", targetLayoutOrder)
    print("  🔍 Order atual:", order)
    
    for uniqueId, layoutOrder in pairs(order) do
        if layoutOrder == targetLayoutOrder then
            conflictingUniqueId = uniqueId
            -- Extrair itemId do uniqueId
            local idStr = string.match(tostring(uniqueId), "^(%d+)")
            conflictingItemId = tonumber(idStr)
            print("  ⚠️ Encontrado item conflitante:", uniqueId, "na pos", layoutOrder)
            break
        end
    end
    
    if not conflictingItemId then
        print("  ✅ Posição está vazia, apenas mover")
    end
    
    -- Se há item no slot alvo, fazer SWAP (ou MERGE se for mesmo item stackable)
    if conflictingItemId and conflictingUniqueId then  
        local inventoryItemConfig = ITEMS_CONFIG[conflictingItemId]
        local inventoryQuantity = 1 -- Itens não-stackable sempre são 1
        
        -- Se é stackable, pegar quantidade do inventário
        if inventoryItemConfig and inventoryItemConfig.stackable then
            inventoryQuantity = playerItems[conflictingItemId] or 1
        end
        
        print("🔄 Conflito detectado! Hotbar slot", hotbarSlotIndex, "com Inventário pos", targetLayoutOrder)
        print("  - Item na hotbar:", hotbarItemId, "qty:", hotbarQuantity)
        print("  - Item no inventory:", conflictingItemId, "qty:", inventoryQuantity)
        
        -- 🐛 BUG FIX: Se for o MESMO item e STACKABLE, fazer MERGE ao invés de SWAP
        local hotbarItemConfig = ITEMS_CONFIG[hotbarItemId]
        if hotbarItemId == conflictingItemId and hotbarItemConfig and hotbarItemConfig.stackable then
            print("  🔗 MERGE! Mesmo item stackable, combinando quantidades")
            
            -- Adicionar quantidade da hotbar ao inventário (sem notificar)
            PlayerItemsModule.addItem(player, hotbarItemId, hotbarQuantity, false)
            
            -- Remover da hotbar
            hotbar[hotbarSlotIndex] = nil
            
            -- Garantir que o order está na posição correta
            order[conflictingUniqueId] = targetLayoutOrder
            
            print("  📦 Total no inventário agora:", playerItems[hotbarItemId], "na pos", targetLayoutOrder)
            
            -- Salvar e notificar
            local successItems = PlayerItemsModule.savePlayerItems(player)
            local successOrder = PlayerItemsModule.savePlayerOrder(player)
            local successHotbar = PlayerItemsModule.saveHotbar(player)
            
            print("  💾 Salvando... Items:", successItems, "Order:", successOrder, "Hotbar:", successHotbar)
            
            if successItems and successOrder and successHotbar then
                notifyFullState(player)
                print("  ✅ MERGE completo:", hotbarQuantity + inventoryQuantity, "unidades em pos", targetLayoutOrder)
                return true
            else
                warn("❌ Erro ao salvar dados do jogador")
                return false
            end
        end
        
        print("  🔄 SWAP! Items diferentes, trocando posições")
        
        -- 1. Remover item do inventário (que vai para hotbar)
        if not canItemBeHotbar(conflictingItemId) then
            warn("❌ Item do inventário não pode ir para hotbar:", conflictingItemId)
            return false
        end
        
        PlayerItemsModule.removeItem(player, conflictingItemId, inventoryQuantity, false)
        order[conflictingUniqueId] = nil
        
        -- 2. Adicionar item do inventário na hotbar
        hotbar[hotbarSlotIndex] = {
            itemId = conflictingItemId,
            quantity = inventoryQuantity
        }
        
        -- 3. Adicionar item da hotbar no inventário
        PlayerItemsModule.addItem(player, hotbarItemId, hotbarQuantity, false)
        
        -- 4. Atualizar ordem do item da hotbar (agora no inventário)
        local hotbarItemConfig = ITEMS_CONFIG[hotbarItemId]
        local newUniqueId
        if hotbarItemConfig and hotbarItemConfig.stackable then
            newUniqueId = tostring(hotbarItemId)
        else
            -- Para não-stackable, precisamos contar TODAS as unidades no playerItems
            local totalInInventory = playerItems[hotbarItemId] or 0
            -- O novo item será o último (totalInInventory porque addItem já adicionou)
            newUniqueId = tostring(hotbarItemId) .. "_" .. tostring(totalInInventory)
        end
        order[newUniqueId] = targetLayoutOrder
        
        print("   📍 Definida posição:", newUniqueId, "→", targetLayoutOrder)
        print("   ✅ SWAP completo: Item", conflictingItemId, "→ hotbar,", "Item", hotbarItemId, "→ inventário pos", targetLayoutOrder)
    else
        -- Não há swap, apenas mover para inventário
        -- Devolver item ao inventário (SEM notificar)
        local addSuccess = PlayerItemsModule.addItem(player, hotbarItemId, hotbarQuantity, false)
        if not addSuccess then
            warn("❌ Erro ao devolver item ao inventário")
            return false
        end
        
        -- Limpar slot da hotbar
        hotbar[hotbarSlotIndex] = nil
        
        -- Atualizar ordem para a nova posição
        local itemConfig = ITEMS_CONFIG[hotbarItemId]
        
        -- Determinar uniqueId do novo item
        local newUniqueId
        if itemConfig and itemConfig.stackable then
            -- Item stackable: usar apenas o itemId
            newUniqueId = tostring(hotbarItemId)
        else
            -- Item não-stackable: usar a quantidade total no inventário
            local totalInInventory = playerItems[hotbarItemId] or 0
            -- O novo item será o último (totalInInventory porque addItem já adicionou)
            newUniqueId = tostring(hotbarItemId) .. "_" .. tostring(totalInInventory)
        end
        
        -- Colocar novo item na posição desejada
        order[newUniqueId] = targetLayoutOrder
        print("  📍 Definida posição:", newUniqueId, "→", targetLayoutOrder)
        print("  ✅ Item movido para inventário (sem swap)")
    end
    
    -- Salvar ambos
    local successItems = PlayerItemsModule.savePlayerItems(player)
    local successOrder = PlayerItemsModule.savePlayerOrder(player)
    local successHotbar = PlayerItemsModule.saveHotbar(player)
    
    print("  💾 Salvando... Items:", successItems, "Order:", successOrder, "Hotbar:", successHotbar)
    
    if successItems and successOrder and successHotbar then
        -- Notificar estado completo
        notifyFullState(player)
        print("  ✅ Item", hotbarItemId, "movido da hotbar slot", hotbarSlotIndex, "→ inventário pos", targetLayoutOrder)
        return true
    else
        warn("❌ Erro ao salvar dados do jogador")
        return false
    end
end

--- Usa item da hotbar (reduz quantidade em 1)
function PlayerItemsModule.useHotbarItem(player: Player, slotIndex: number): boolean
    if type(slotIndex) ~= "number" or slotIndex < 1 or slotIndex > MAX_HOTBAR_SLOTS then
        return false
    end
    
    local hotbar = PlayerItemsModule.getHotbar(player)
    local slotData = hotbar[slotIndex]
    
    if not slotData then
        return false
    end
    
    -- Reduzir quantidade
    slotData.quantity = slotData.quantity - 1
    
    -- Se quantidade chegou a 0, remover do slot
    if slotData.quantity <= 0 then
        hotbar[slotIndex] = nil
    end
    
    -- Salvar e notificar
    PlayerItemsModule.saveHotbar(player)
    notifyHotbarClient(player)
    
    return true
end

--- Limpa toda a hotbar (devolve tudo ao inventário)
function PlayerItemsModule.clearHotbar(player: Player): boolean
    local hotbar = PlayerItemsModule.getHotbar(player)
    
    -- Devolver todos os itens ao inventário (SEM notificar)
    for slotIndex, slotData in pairs(hotbar) do
        if slotData then
            PlayerItemsModule.addItem(player, slotData.itemId, slotData.quantity, false)
        end
    end
    
    -- Limpar hotbar
    hotbarCache[player.UserId] = {}
    
    -- Salvar ambos
    local successItems = PlayerItemsModule.savePlayerItems(player)
    local successHotbar = PlayerItemsModule.saveHotbar(player)
    
    if successItems and successHotbar then
        -- Notificar estado completo
        notifyFullState(player)
        return true
    else
        warn("❌ Erro ao limpar hotbar")
        return false
    end
end

--- Configurar RemoteFunction para obter itens
getPlayerItemsEvent.OnServerInvoke = function(player: Player)
    -- Retorna IDs, quantidades E ordem dos itens
    local items = PlayerItemsModule.getPlayerItemsWithInfo(player)  -- ✅ Retorna com configuração do item
    local order = PlayerItemsModule.getPlayerOrder(player)
    
    return {items = items, order = order}
end

--- Conectar RemoteEvent de reordenar
reorderItemsEvent.OnServerEvent:Connect(function(player, newOrder)
    PlayerItemsModule.reorderItems(player, newOrder)
end)

--- Configurar RemoteFunction para obter hotbar
getHotbarFunction.OnServerInvoke = function(player: Player)
    return PlayerItemsModule.getHotbar(player)
end

--- Conectar RemoteEvent para definir slot da hotbar
setHotbarSlotEvent.OnServerEvent:Connect(function(player, slotIndex, itemId, quantity)
    print("📡 [SERVER] Recebeu SetHotbarSlot:")
    print("  - Player:", player.Name)
    print("  - SlotIndex:", slotIndex, type(slotIndex))
    print("  - ItemId:", itemId, type(itemId))
    print("  - Quantity:", quantity, type(quantity))
    
    local success = PlayerItemsModule.setHotbarSlot(player, slotIndex, itemId, quantity)
    print("  - Resultado:", success and "✅ Sucesso" or "❌ Falhou")
end)

--- Conectar RemoteEvent para fazer swap entre slots da hotbar
swapHotbarSlotsEvent.OnServerEvent:Connect(function(player, slotIndex1, slotIndex2)
    PlayerItemsModule.swapHotbarSlots(player, slotIndex1, slotIndex2)
end)

--- Conectar RemoteEvent para mover item da hotbar para slot específico do inventário
moveHotbarToInventorySlotEvent.OnServerEvent:Connect(function(player, hotbarSlotIndex, targetLayoutOrder)
    PlayerItemsModule.moveHotbarToInventorySlot(player, hotbarSlotIndex, targetLayoutOrder)
end)

--- Carregar itens, ordem e hotbar quando jogador entra
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        PlayerItemsModule.loadPlayerItems(player)
        PlayerItemsModule.loadPlayerOrder(player)
        PlayerItemsModule.loadHotbar(player)
    end)
end)

--- Salvar e limpar cache quando jogador sai
Players.PlayerRemoving:Connect(function(player)
    if playerItemsCache[player.UserId] then
        PlayerItemsModule.savePlayerItems(player)
        PlayerItemsModule.savePlayerOrder(player)
        PlayerItemsModule.saveHotbar(player)
        task.wait(0.5) -- Garantir que salvou
        playerItemsCache[player.UserId] = nil
        playerOrderCache[player.UserId] = nil
        hotbarCache[player.UserId] = nil
    end
end)

--print("✅ Sistema de Itens inicializado!")

return PlayerItemsModule

