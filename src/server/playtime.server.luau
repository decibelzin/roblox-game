-- Sistema de Playtime com Recompensas (Inicializador)
local Players = game:GetService("Players")

-- Módulos
local PLAYER_MODULE = require(game.ServerScriptService.Server.framework.modules.player)
local PLAYTIME_MODULE = require(game.ServerScriptService.Server.framework.modules.playtime)

-- Inicializar
local cache = { player = {} }
local playerModule = PLAYER_MODULE(cache.player)
local playerClasses = {}

-- Função para obter classe do jogador
local function getPlayerClass(player)
    if not playerClasses[player.UserId] then
        local data, class = playerModule.get(player, true)
        playerClasses[player.UserId] = class
    end
    return playerClasses[player.UserId]
end

-- Inicializar módulo de playtime
PLAYTIME_MODULE.init(playerModule, playerClasses)

-- Eventos
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(2)
        -- Garantir que a classe do jogador existe
        getPlayerClass(player)
        PLAYTIME_MODULE.startTracking(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    PLAYTIME_MODULE.stopTracking(player)
    playerClasses[player.UserId] = nil
end)

-- Loop de salvamento
spawn(function()
    while true do
        wait(PLAYTIME_MODULE.getSaveInterval())
        
        for userId, session in pairs(PLAYTIME_MODULE.getPlayerSessions()) do
            local player = Players:GetPlayerByUserId(userId)
            if player and tick() - session.lastSave >= PLAYTIME_MODULE.getSaveInterval() then
                PLAYTIME_MODULE.saveTime(player)
            end
        end
    end
end)

print("🎮 Playtime com recompensas iniciado!")

