local service = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

service.PlayerAdded:Connect(function(player)
    local cache, methods = PlayerModule.get(player, true)
end)