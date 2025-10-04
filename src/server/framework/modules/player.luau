local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerClass = require(game.ServerScriptService.Server.framework.classes.player.main)
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

local storage = game:GetService("DataStoreService")

local groupStorage = storage:GetDataStore(STORAGE_DEFINITIONS.group)

local memory = require("../classes/cache")
local isOnlinePlayer = require("../utils/check-player-is-online")
local cache: memory.Cache<PLAYER_DEFINITION.DefPlayerSchema> = require("../classes/cache").new("player-data")

-- Cache reverso para mapear User ID customizado -> Player (performance otimizada)
local userIdToPlayerCache = {}

local remoteEventGroups = Instance.new("RemoteEvent")
remoteEventGroups.Name = "framework:update.player.groups"
remoteEventGroups.Parent = game.ReplicatedStorage

-- Limpar cache reverso quando jogadores saem (evitar vazamentos de memória)
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(player)
    -- Remover do cache reverso
    for userId, cachedPlayer in pairs(userIdToPlayerCache) do
        if cachedPlayer == player then
            userIdToPlayerCache[userId] = nil
            break
        end
    end
end)



return function()
    local self = {}

    function self.fetch(player: Player): PLAYER_DEFINITION.DefPlayerSchema
        -- Validar se o player tem UserId válido
        if not player or not player.UserId or type(player.UserId) ~= "number" or player.UserId <= 0 then
            warn("❌ Player inválido ou sem UserId válido fornecido para fetch")
            -- Retornar dados padrão em caso de erro
            return {
                player = player,
                groups = {},
                userId = 0,
                items = {}
            }
        end
        
        local statusGroups, groups: PLAYER_DEFINITION.DefPlayerGroups = pcall(function()
            return groupStorage:GetAsync(player.UserId)
        end)

        -- Verificar se groups é uma tabela válida
        if not statusGroups or type(groups) ~= "table" then
            groups = {}
        end

        -- Obter ou criar User ID para o jogador
        local userId = 0
        if player.Name then
            -- Se é um player real (tem Name), tentar criar/obter User ID
            userId = UserIdModule.getOrCreateUserId(player)
            if not userId then
                warn("❌ Erro ao obter/criar User ID para jogador:", player.Name)
                userId = 0 -- Fallback
            end
        else
            -- Se é um "fake player" (para jogadores offline), apenas buscar o ID existente
            userId = UserIdModule.getUserIdByRobloxId(player.UserId)
            if not userId then
                userId = 0 -- Não criar novo ID para jogadores offline
            end
        end

        local data: PLAYER_DEFINITION.DefPlayerSchema = {
            player = player,
            groups = groups,
            userId = userId,
            items = {} -- Itens são gerenciados separadamente pelo player-items module
        }

        -- Só enviar para cliente se for um player real e online
        if player.Name and isOnlinePlayer(player) then
            -- Sempre envia os grupos (mesmo vazio) para sincronizar estado inicial no cliente
            remoteEventGroups:FireClient(player, data.groups)
        end

        return data
    end

    function self.get(player: Player, insertCache: boolean?)
        local inCache = cache.get(player.UserId)

        if inCache then
            return PlayerClass.new(inCache)
        end

        local data = self.fetch(player)

        -- Atualizar cache reverso se o jogador tem User ID customizado
        if data.userId and data.userId > 0 then
            userIdToPlayerCache[data.userId] = player
        end

        if not insertCache then
            return PlayerClass.new(data)
        end

        return PlayerClass.new(cache.set(player.UserId, data))
    end

    --- Encontra um jogador online pelo User ID customizado (otimizado com cache)
    function self.getPlayerByUserId(userId: number): Player?
        if not userId or type(userId) ~= "number" or userId <= 0 then
            return nil
        end
        
        -- Primeiro, verificar no cache reverso (O(1))
        local cachedPlayer = userIdToPlayerCache[userId]
        if cachedPlayer then
            local Players = game:GetService("Players")
            -- Verificar se o jogador ainda está online
            if Players:FindFirstChild(cachedPlayer.Name) then
                return cachedPlayer
            else
                -- Jogador saiu, limpar cache
                userIdToPlayerCache[userId] = nil
            end
        end
        
        -- Se não está no cache, provavelmente o jogador não está online
        -- ou ainda não teve seus dados carregados
        
        return nil
    end

    return self
end
