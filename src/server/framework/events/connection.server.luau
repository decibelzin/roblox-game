local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local service = game:GetService("Players")
local cache = {
    player = {} :: {PLAYER_DEFINITION.DefPlayerSchema}
}

local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

service.PlayerAdded:Connect(function(player)
    PlayerModule.get(player, true)
end)