local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerClass = require(game.ServerScriptService.Server.framework.classes.player.main)

local storage = game:GetService("DataStoreService")

local groupStorage = storage:GetDataStore(STORAGE_DEFINITIONS.group)
local coinsStorage = storage:GetDataStore(STORAGE_DEFINITIONS.coins)
local playtimeStorage = storage:GetDataStore(STORAGE_DEFINITIONS.playtime)

local memory = require("../classes/cache")
local cache: memory.Cache<PLAYER_DEFINITION.DefPlayerSchema> = require("../classes/cache").new("player-data")

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
