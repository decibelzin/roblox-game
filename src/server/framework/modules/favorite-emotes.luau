local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).favoriteEmotes
local ANIMATIONS = require(game.ReplicatedStorage.Shared.animations)
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local favoriteEmotesStore = DataStoreService:GetDataStore(STORAGE_KEY)
local playerFavorites = {} -- Cache: userId -> {emoteIndex -> true}

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

-- Salva favoritos no DataStore
function FavoriteEmotesModule.savePlayerFavorites(player)
    local favoriteSet = playerFavorites[player.UserId] or {}
    
    -- Converte set para array
    local favoriteArray = {}
    for index in pairs(favoriteSet) do
        table.insert(favoriteArray, index)
    end
    
    local success = pcall(function()
        favoriteEmotesStore:SetAsync(tostring(player.UserId), favoriteArray)
    end)
    
    return success
end

-- Obtém favoritos do jogador
function FavoriteEmotesModule.getPlayerFavorites(player)
    if not playerFavorites[player.UserId] then
        FavoriteEmotesModule.loadPlayerFavorites(player)
    end
    
    return playerFavorites[player.UserId] or {}
end

-- Atualiza favorito
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
    
    -- Atualiza cache
    if isFavorited then
        playerFavorites[player.UserId][emoteIndex] = true
    else
        playerFavorites[player.UserId][emoteIndex] = nil
    end
    
    -- Salva assíncronamente
    task.spawn(function()
        FavoriteEmotesModule.savePlayerFavorites(player)
    end)
    
    return true
end

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

-- Cleanup quando jogador sai
Players.PlayerRemoving:Connect(function(player)
    if playerFavorites[player.UserId] then
        FavoriteEmotesModule.savePlayerFavorites(player)
        playerFavorites[player.UserId] = nil
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