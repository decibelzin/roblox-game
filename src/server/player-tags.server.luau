-- Sistema de Tags dos Jogadores
local players = game:GetService("Players")

-- Importar módulos necessários
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])

-- Função para aplicar tags ao jogador
local function applyPlayerTags(player)
    -- Obter dados do player
    local playerData, playerClass = PlayerModule.get(player, true)
    
    -- Obter o grupo mais alto
    local highestGroup = playerClass.group.getHighestGroup()
    
    -- Print com User ID e grupo do jogador
    local userIdText = ""
    if playerData.userId and type(playerData.userId) == "number" and playerData.userId > 0 then
        userIdText = " [ID: " .. playerData.userId .. "]"
    end
    print(player.Name .. userIdText .. (' (%s) entrou no servidor'):format(highestGroup or 'Nenhum'))
    
    -- Criar tag no servidor
    playerClass.group.updateServerTag()
    
    -- Enviar mensagem de boas-vindas
    local welcomeMessage = string.format("👋 Bem-vindo, %s!", player.Name)
    if playerData.userId and type(playerData.userId) == "number" and playerData.userId > 0 then
        welcomeMessage = welcomeMessage .. string.format(" [ID: %d]", playerData.userId)
    end
    if highestGroup and highestGroup ~= "None" then
        welcomeMessage = welcomeMessage .. string.format(" (Grupo: %s)", highestGroup)
    end
    ChatMessage.sendSuccess(player, welcomeMessage)
end

-- Eventos
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Aguardar o character carregar completamente
        
        -- Aplicar tags do jogador
        applyPlayerTags(player)
    end)
end) 