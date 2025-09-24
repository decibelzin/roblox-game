local types = require(game.ReplicatedStorage.Shared.types["player.types"])
local GroupModule = require('./group')
local Class = {}

function Class.new(cache: types.DefPlayerSchema)
    local self = {}

    self.group = GroupModule(cache)

    return cache, self
end


return Class