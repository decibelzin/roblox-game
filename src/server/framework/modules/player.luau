local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerClass = require(game.ServerScriptService.Server.framework.classes.player.main)

local storage = game:GetService("DataStoreService")
local groupStorage = storage:GetDataStore(STORAGE_DEFINITIONS.group)

return function(cache: {PLAYER_DEFINITION.DefPlayerSchema})
    local self = {}

    function self.fetch(player: Player): PLAYER_DEFINITION.DefPlayerSchema
        local success, groups: PLAYER_DEFINITION.DefPlayerGroups = pcall(function()
            return groupStorage:GetAsync(player.UserId)
        end)

        local data: PLAYER_DEFINITION.DefPlayerSchema = {
            player = player,
            groups = success and groups or {},
        }

        return data
    end

    function self.get(player: Player, insertCache: boolean?)
        if cache[player.UserId] then
            return PlayerClass.new(cache[player.UserId])
        end

        local data = self.fetch(player)

        if not insertCache then
            return PlayerClass.new(data)
        end

        cache[player.UserId] = data
        return PlayerClass.new(cache[player.UserId])
    end

    return self
end