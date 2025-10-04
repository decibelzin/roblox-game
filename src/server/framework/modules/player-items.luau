local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).playerItems
local ITEMS_MODULE = require(game.ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local playerItemsStore = DataStoreService:GetDataStore(STORAGE_KEY)
local playerItemsCache = {} -- Cache: userId -> {itemId -> quantidade}

-- RemoteEvents
local getPlayerItemsEvent = Instance.new("RemoteFunction")
getPlayerItemsEvent.Name = "GetPlayerItems"
getPlayerItemsEvent.Parent = ReplicatedStorage

local updatePlayerItemsEvent = Instance.new("RemoteEvent")
updatePlayerItemsEvent.Name = "UpdatePlayerItems"
updatePlayerItemsEvent.Parent = ReplicatedStorage

local PlayerItemsModule = {}

--- Valida se um item existe na configuração
local function isValidItem(itemId: number): boolean
    return type(itemId) == "number" and ITEMS_CONFIG[itemId] ~= nil
end

--- Valida dados de itens
local function validateItemsData(items: {[number]: number}): boolean
    if type(items) ~= "table" then
        return false
    end
    
    for itemId, quantity in pairs(items) do
        if not isValidItem(itemId) or type(quantity) ~= "number" or quantity < 0 then
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
            if isValidItem(itemId) and type(quantity) == "number" and quantity > 0 then
                playerItems[itemId] = quantity
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
    
    return playerItemsCache[player.UserId] or {}
end

--- Adiciona item ao inventário do jogador
function PlayerItemsModule.addItem(player: Player, itemId: number, quantity: number?): boolean
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
    
    local playerItems = playerItemsCache[player.UserId]
    local currentAmount = playerItems[itemId] or 0
    playerItems[itemId] = currentAmount + amount
    
    -- Salvar no DataStore
    local success = PlayerItemsModule.savePlayerItems(player)
    
    if success then
        -- Notificar cliente apenas com IDs e quantidades (cliente tem a config em shared)
        updatePlayerItemsEvent:FireClient(player, playerItems)
    end
    
    return success
end

--- Remove item do inventário do jogador
function PlayerItemsModule.removeItem(player: Player, itemId: number, quantity: number?): boolean
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
    
    if success then
        -- Notificar cliente apenas com IDs e quantidades (cliente tem a config em shared)
        updatePlayerItemsEvent:FireClient(player, playerItems)
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
        -- Notificar cliente apenas com IDs e quantidades (cliente tem a config em shared)
        updatePlayerItemsEvent:FireClient(player, playerItems)
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
    
    local success = PlayerItemsModule.savePlayerItems(player)
    
    if success then
        -- Notificar cliente com tabela vazia (mas no formato correto)
        updatePlayerItemsEvent:FireClient(player, {})
    end
    
    return success
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

--- Configurar RemoteFunction para obter itens
getPlayerItemsEvent.OnServerInvoke = function(player: Player)
    -- Retorna apenas IDs e quantidades (cliente tem a config em shared)
    return PlayerItemsModule.getPlayerItems(player)
end

--- Carregar itens quando jogador entra
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        PlayerItemsModule.loadPlayerItems(player)
        print("✅ Itens carregados para:", player.Name)
    end)
end)

--- Salvar e limpar cache quando jogador sai
Players.PlayerRemoving:Connect(function(player)
    if playerItemsCache[player.UserId] then
        PlayerItemsModule.savePlayerItems(player)
        task.wait(0.5) -- Garantir que salvou
        playerItemsCache[player.UserId] = nil
    end
end)

print("✅ Sistema de Itens inicializado!")

return PlayerItemsModule

