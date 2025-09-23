local service = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

-- Limpar cache quando player sair
service.PlayerRemoving:Connect(function(player)
    local cache = require(game.ServerScriptService.Server.framework.classes.cache)
    local playerCache = cache.instance("player-data")
    playerCache.remove(player.UserId)
end)

service.PlayerAdded:Connect(function(player)
    local cache, methods = PlayerModule.get(player, true)
end)
