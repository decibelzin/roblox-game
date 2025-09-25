local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerClass = require(game.ServerScriptService.Server.framework.classes.player.main)
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

local storage = game:GetService("DataStoreService")

local groupStorage = storage:GetDataStore(STORAGE_DEFINITIONS.group)

local memory = require("../classes/cache")
local isOnlinePlayer = require("../utils/check-player-is-online")
local cache: memory.Cache<PLAYER_DEFINITION.DefPlayerSchema> = require("../classes/cache").new("player-data")

local remoteEventGroups = Instance.new("RemoteEvent")
remoteEventGroups.Name = "framework:update.player.groups"
remoteEventGroups.Parent = game.ReplicatedStorage

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
                userId = 0
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
            userId = userId
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

        if not insertCache then
            return PlayerClass.new(data)
        end

        return PlayerClass.new(cache.set(player.UserId, data))
    end

    return self
end
