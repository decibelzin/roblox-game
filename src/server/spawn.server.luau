-- Sistema de Spawn
local players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar o módulo de player para acessar os grupos
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Módulos adicionais
local PLAYTIME_MODULE = require(game.ServerScriptService.Server.framework.modules.playtime)

-- Criar RemoteEvent para enviar mensagens do chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

-- Função para obter o grupo mais alto de um jogador
local function getHighestGroup(playerGroups)
    -- Verificar se playerGroups é uma tabela válida
    if not playerGroups or type(playerGroups) ~= "table" then
        return "None"
    end
    
    local highestGroup = nil
    local highestPriority = 0
    
    -- Prioridades dos grupos (maior número = maior prioridade)
    local priorities = {
        owner = 4,
        admin = 3,
        moderator = 2,
        ["vip-gold"] = 1
    }
    
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup and priorities[groupName] and priorities[groupName] > highestPriority then
            highestPriority = priorities[groupName]
            highestGroup = groupName
        end
    end
    
    return highestGroup or "None"
end

-- Função para listar todos os grupos de um jogador
local function listPlayerGroups(playerGroups)
    -- Verificar se playerGroups é uma tabela válida
    if not playerGroups or type(playerGroups) ~= "table" then
        return {}
    end
    
    local groups = {}
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup then
            table.insert(groups, groupName)
        end
    end
    return groups
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
    
    -- Verificar se a coluna Minutes já existe
    local minutesValue = leaderstats:FindFirstChild("Minutes")
    if not minutesValue then
        -- Criar a coluna Minutes
        minutesValue = Instance.new("IntValue")
        minutesValue.Name = "Minutes"
        minutesValue.Value = 0
        minutesValue.Parent = leaderstats
    end
    
    -- Função para atualizar os valores
    local function updateLeaderboard()
        -- Obter dados do jogador
        local playerData = PlayerModule.get(player, false)
        if not playerData then return end
        
        -- Atualizar grupo
        local highestGroup = getHighestGroup(playerData.groups)
        groupValue.Value = highestGroup
        
        -- Atualizar minutos
        local totalTime, sessionTime = PLAYTIME_MODULE.getCurrentTime(player)
        local totalMinutes = math.floor((totalTime + sessionTime) / 60)
        minutesValue.Value = totalMinutes
    end
    
    -- Atualizar imediatamente
    updateLeaderboard()
    
    -- Atualizar a cada 30 segundos
    spawn(function()
        while player.Parent do
            wait(30)
            updateLeaderboard()
        end
    end)
end

-- Função para aplicar tags ao jogador
local function applyPlayerTags(player)
    -- Obter dados do player
    local playerData, playerClass = PlayerModule.get(player, true)
    
    -- Obter o grupo mais alto
    local highestGroup = getHighestGroup(playerData.groups)
    
    -- Listar todos os grupos
    local allGroups = listPlayerGroups(playerData.groups)
    
    -- Print do JSON dos grupos do jogador
    print("=== GRUPOS DO JOGADOR ===")
    print("Jogador:", player.Name)
    print("JSON dos grupos:", game:GetService("HttpService"):JSONEncode(playerData.groups))
    print("Grupos ativos:", table.concat(allGroups, ", "))
    print("Grupo mais alto:", highestGroup or "Nenhum")
    print("========================")
    
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
        
        -- Configurar leaderboard com colunas Group e Minutes
        setupPlayerLeaderboard(player)
    end)
end)

-- Removido o evento PlayerRemoving que estava causando erro
-- O sistema de playtime já gerencia isso no arquivo playtime.server.luau
