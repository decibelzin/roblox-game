local types = require(game.ReplicatedStorage.Shared.types["player.types"])
local GroupModule = require('./group')
local CoinsModule = require('./coins')
local Class = {}

function Class.new(cache: types.DefPlayerSchema)
    local self = {}

    self.group = GroupModule(cache)
    self.coins = CoinsModule(cache)

    return cache, self
end


return Class