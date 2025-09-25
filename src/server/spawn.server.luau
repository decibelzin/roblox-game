-- Sistema de Spawn
local players = game:GetService("Players")

-- Importar o módulo de player para acessar os grupos
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])

-- Função para criar/atualizar leaderboard do jogador
local function setupPlayerLeaderboard(player)
    -- Aguardar o PlayerGui carregar
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Criar ou obter leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- Verificar se a coluna Group já existe
    local groupValue = leaderstats:FindFirstChild("Group")
    if not groupValue then
        -- Criar a coluna Group
        groupValue = Instance.new("StringValue")
        groupValue.Name = "Group"
        groupValue.Value = "None"
        groupValue.Parent = leaderstats
    end
    
    -- Função para atualizar os valores
    local function updateLeaderboard()
        -- Obter dados do jogador
        local playerData, playerClass = PlayerModule.get(player, false)
        if not playerData then return end
        
        -- Atualizar grupo
        local highestGroup = playerClass.group.getHighestGroup()

        groupValue.Value = highestGroup or ''
    end

    updateLeaderboard()
end

-- Função para aplicar tags ao jogador
local function applyPlayerTags(player)
    -- Obter dados do player
    local playerData, playerClass = PlayerModule.get(player, true)
    
    -- Obter o grupo mais alto
    local highestGroup = playerClass.group.getHighestGroup()
    
    -- Print do JSON dos grupos do jogador
    print(player.Name..('(%s) entrou no servidor'):format(highestGroup or 'Nenhum'))
    
    -- Criar tag no servidor
    playerClass.group.updateServerTag()
    
    -- Enviar mensagem de boas-vindas
    local welcomeMessage = string.format("👋 Bem-vindo, %s!", player.Name)
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
        
        -- Configurar leaderboard com coluna Group
        setupPlayerLeaderboard(player)
    end)
end)
