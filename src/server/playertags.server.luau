-- Sistema de Player Tags
local Players = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)
local GroupSync = require(game.ServerScriptService.Server.framework.modules['group-sync'])

local playerModule = PlayerModule()

-- Eventos
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        local playerData, playerClass = playerModule.get(player, false)
        if playerData then
            GroupSync.syncPlayerGroups(player, playerClass, playerData.groups)
        end
    end)
end)

-- Sincronização inicial
spawn(function()
    wait(2)
    GroupSync.syncAllPlayerGroups(playerModule)
end)