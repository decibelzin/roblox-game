local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).favoriteEmotes
local ANIMATIONS = require(game.ReplicatedStorage.Shared.animations)
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local favoriteEmotesStore = DataStoreService:GetDataStore(STORAGE_KEY)
local playerFavorites = {} -- Cache: userId -> {emoteIndex -> true}

-- Otimizações de performance
local pendingSaves = {} -- userId -> true (jogadores com alterações pendentes)
local saveDebounce = {} -- userId -> number (timestamp da última tentativa)
local SAVE_DEBOUNCE_TIME = 3 -- segundos entre salvamentos
local BATCH_SAVE_INTERVAL = 10 -- salvar alterações pendentes a cada 10 segundos

-- RemoteEvents
local getFavoritesEvent = Instance.new("RemoteFunction")
getFavoritesEvent.Name = "GetFavoriteEmotes"
getFavoritesEvent.Parent = ReplicatedStorage

local updateFavoriteEvent = Instance.new("RemoteEvent")
updateFavoriteEvent.Name = "UpdateFavoriteEmote"
updateFavoriteEvent.Parent = ReplicatedStorage

local FavoriteEmotesModule = {}

-- Carrega favoritos do DataStore
function FavoriteEmotesModule.loadPlayerFavorites(player)
    local userId = tostring(player.UserId)
    
    local success, favoriteIndices = pcall(function()
        return favoriteEmotesStore:GetAsync(userId)
    end)
    
    local favoriteSet = {}
    
    if success and favoriteIndices and type(favoriteIndices) == "table" then
        -- Converte array de índices para set
        for _, index in pairs(favoriteIndices) do
            if type(index) == "number" and ANIMATIONS.list[index] then
                favoriteSet[index] = true
            end
        end
    end
    
    playerFavorites[player.UserId] = favoriteSet
    return favoriteSet
end

-- Salva favoritos no DataStore (otimizado)
function FavoriteEmotesModule.savePlayerFavorites(player, forceImmediate)
    local userId = player.UserId
    local favoriteSet = playerFavorites[userId] or {}
    
    -- Debouncing: evita salvamentos muito frequentes
    local currentTime = tick()
    if not forceImmediate and saveDebounce[userId] then
        local timeSinceLastSave = currentTime - saveDebounce[userId]
        if timeSinceLastSave < SAVE_DEBOUNCE_TIME then
            -- Marca para salvamento posterior
            pendingSaves[userId] = true
            return false
        end
    end
    
    -- Remove da lista de pendentes
    pendingSaves[userId] = nil
    saveDebounce[userId] = currentTime
    
    -- Converte set para array (otimizado)
    local favoriteArray = {}
    local count = 0
    for index in pairs(favoriteSet) do
        count = count + 1
        favoriteArray[count] = index
    end
    
    local success = pcall(function()
        favoriteEmotesStore:SetAsync(tostring(userId), favoriteArray)
    end)
    
    if not success then
        -- Re-adiciona à lista de pendentes em caso de erro
        pendingSaves[userId] = true
    end
    
    return success
end

-- Obtém favoritos do jogador
function FavoriteEmotesModule.getPlayerFavorites(player)
    if not playerFavorites[player.UserId] then
        FavoriteEmotesModule.loadPlayerFavorites(player)
    end
    
    return playerFavorites[player.UserId] or {}
end

-- Atualiza favorito (otimizado)
function FavoriteEmotesModule.updateEmoteFavorite(player, emoteName, isFavorited)
    -- Validações
    if not player or not emoteName or type(emoteName) ~= "string" or emoteName == "" then
        return false
    end
    
    if type(isFavorited) ~= "boolean" then
        return false
    end
    
    -- Converte nome para índice
    local emoteIndex = ANIMATIONS.nameToIndex[emoteName]
    if not emoteIndex then
        return false
    end
    
    -- Inicializa cache se necessário
    if not playerFavorites[player.UserId] then
        playerFavorites[player.UserId] = {}
    end
    
    -- Verifica se houve mudança real
    local currentState = playerFavorites[player.UserId][emoteIndex] == true
    if currentState == isFavorited then
        return true -- Não há mudança, evita operação desnecessária
    end
    
    -- Atualiza cache
    if isFavorited then
        playerFavorites[player.UserId][emoteIndex] = true
    else
        playerFavorites[player.UserId][emoteIndex] = nil
    end
    
    -- Marca para salvamento com debounce
    pendingSaves[player.UserId] = true
    
    -- Tenta salvar com debounce
    task.spawn(function()
        FavoriteEmotesModule.savePlayerFavorites(player, false)
    end)
    
    return true
end

-- Sistema de batch saving para salvamentos pendentes
local function processPendingSaves()
    for userId in pairs(pendingSaves) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            task.spawn(function()
                FavoriteEmotesModule.savePlayerFavorites(player, true)
            end)
        else
            -- Remove jogadores desconectados da lista
            pendingSaves[userId] = nil
        end
    end
end

-- Timer para batch saving
task.spawn(function()
    while true do
        task.wait(BATCH_SAVE_INTERVAL)
        processPendingSaves()
    end
end)

-- Configura RemoteEvents
getFavoritesEvent.OnServerInvoke = function(player)
    local favoriteIndices = FavoriteEmotesModule.getPlayerFavorites(player)
    
    -- Converte índices para nomes para compatibilidade com cliente
    local favoriteNames = {}
    for index in pairs(favoriteIndices) do
        local animation = ANIMATIONS.list[index]
        if animation then
            favoriteNames[animation.name] = true
        end
    end
    
    return favoriteNames
end

updateFavoriteEvent.OnServerEvent:Connect(function(player, emoteName, isFavorited)
    FavoriteEmotesModule.updateEmoteFavorite(player, emoteName, isFavorited)
end)

-- Cleanup quando jogador sai (otimizado)
Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    
    if playerFavorites[userId] then
        -- Salvamento forçado e imediato na saída
        FavoriteEmotesModule.savePlayerFavorites(player, true)
        
        -- Cleanup após um delay para garantir que o salvamento termine
        task.wait(1)
        playerFavorites[userId] = nil
        pendingSaves[userId] = nil
        saveDebounce[userId] = nil
    end
end)

-- Carrega dados para jogadores já conectados
Players.PlayerAdded:Connect(function(player)
    FavoriteEmotesModule.loadPlayerFavorites(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    FavoriteEmotesModule.loadPlayerFavorites(player)
end

return FavoriteEmotesModule 