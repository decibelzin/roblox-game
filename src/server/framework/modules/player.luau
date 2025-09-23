local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerClass = require(game.ServerScriptService.Server.framework.classes.player.main)

local storage = game:GetService("DataStoreService")

local groupStorage = storage:GetDataStore(STORAGE_DEFINITIONS.group)
local coinsStorage = storage:GetDataStore(STORAGE_DEFINITIONS.coins)
local playtimeStorage = storage:GetDataStore(STORAGE_DEFINITIONS.playtime)

local memory = require("../classes/cache")
local isOnlinePlayer = require("../utils/check-player-is-online")
local cache: memory.Cache<PLAYER_DEFINITION.DefPlayerSchema> = require("../classes/cache").new("player-data")

local remoteEventGroups = Instance.new("RemoteEvent")
remoteEventGroups.Name = "framework:update.player.groups"
remoteEventGroups.Parent = game.ReplicatedStorage

local remoteEventCoins = Instance.new("RemoteEvent")
remoteEventCoins.Name = "framework:update.player.coins"
remoteEventCoins.Parent = game.ReplicatedStorage

return function()
    local self = {}

    function self.fetch(player: Player): PLAYER_DEFINITION.DefPlayerSchema
        local statusGroups, groups: PLAYER_DEFINITION.DefPlayerGroups = pcall(function()
            return groupStorage:GetAsync(player.UserId)
        end)

        local statusCoins, coins: number = pcall(function()
            return coinsStorage:GetAsync(player.UserId)
        end)

        local statusPlaytime, playtime: number = pcall(function()
            return playtimeStorage:GetAsync(player.UserId)
        end)

        -- Verificar se groups é uma tabela válida
        if not statusGroups or type(groups) ~= "table" then
            groups = {}
        end

        local data: PLAYER_DEFINITION.DefPlayerSchema = {
            player = player,
            groups = groups,
            coins = statusCoins and coins or 0,
            playtime = statusPlaytime and playtime or 0
        }

        if isOnlinePlayer(player) then
            -- Sempre envia os grupos (mesmo vazio) para sincronizar estado inicial no cliente
            remoteEventGroups:FireClient(player, data.groups)

            if data.coins > 0 then
                remoteEventCoins:FireClient(player, data.coins)
            end
        end

        return data
    end

    function self.get(player: Player, insertCache: boolean?)
        local inCache = cache.get(player.UserId)

        if inCache then
            return PlayerClass.new(inCache)
        end

        local data = self.fetch(player)

        if isOnlinePlayer(player) then
            player:SetAttribute("coins", data.coins)
        end

        if not insertCache then
            return PlayerClass.new(data)
        end

        return PlayerClass.new(cache.set(player.UserId, data))
    end

    return self
end
