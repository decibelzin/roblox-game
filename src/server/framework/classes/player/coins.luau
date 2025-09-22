local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).group
local database = game:GetService("DataStoreService"):GetDataStore(STORAGE_KEY)

return function(cache: PLAYER_DEFINITION.DefPlayerSchema)
    local self = {}

    function self.add(amount: number)
        amount = math.max(amount, 0)

        local balance = cache.coins + amount
        
        local success = pcall(function()
            return database:SetAsync(cache.player.UserId, balance)
        end)

        if not success then
            return false
        end

        cache.coins = balance
        return true
    end

    function self.remove(amount: number)
        amount = math.max(amount, 0)

        if not self.hasEnough(amount) then
            return false
        end

        local balance = cache.coins - amount

        local success = pcall(function()
            return database:SetAsync(cache.player.UserId, balance)
        end)

        if not success then
            return false
        end

        cache.coins = balance
        return true
    end

    function self.hasEnough(amount: number)
        return cache.coins >= amount
    end

    return self
end