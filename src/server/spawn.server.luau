-- Sistema de Spawn
local players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar o módulo de player para acessar os grupos
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Criar RemoteEvent para enviar mensagens do chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

-- Função para obter cor do grupo
local function getGroupColor(groupName)
    if groupName and GROUPS_CONFIG[groupName] then
        return GROUPS_CONFIG[groupName].color
    end
    return Color3.fromRGB(255, 255, 255) -- Cor padrão
end

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
    
    -- Listar todos os grupos
    local allGroups = playerClass.group.list()
    
    -- Print do JSON dos grupos do jogador
    print("=== GRUPOS DO JOGADOR ===")
    print("Jogador:", player.Name)
    print("JSON dos grupos:", game:GetService("HttpService"):JSONEncode(playerData.groups))
    print("Grupos ativos:", table.concat(allGroups, ", "))
    print("Grupo mais alto:", highestGroup or "Nenhum")
    print("========================")
    
    -- Criar tag no servidor
    playerClass.group.updateServerTag()
    
    -- Enviar mensagem de boas-vindas
    local welcomeMessage = string.format("👋 Bem-vindo, %s!", player.Name)
    if highestGroup and highestGroup ~= "None" then
        welcomeMessage = welcomeMessage .. string.format(" (Grupo: %s)", highestGroup)
    end
    chatMessageEvent:FireClient(player, welcomeMessage)
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
