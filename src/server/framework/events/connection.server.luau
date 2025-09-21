local service = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

service.PlayerAdded:Connect(function(player)
    PlayerModule.get(player, true)
end)