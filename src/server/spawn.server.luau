-- Sistema de Spawn
local players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar o módulo de player para acessar os grupos
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

-- Importar configurações de grupos
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

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
        return nil
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
    
    return highestGroup
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

-- Função para aplicar tags ao jogador
local function applyPlayerTags(player)
    -- Obter dados do player
    local playerData, playerClass = PlayerModule.get(player, true)
    
    -- Obter o grupo mais alto
    local highestGroup = getHighestGroup(playerData.groups)
    
    -- Listar todos os grupos
    local allGroups = listPlayerGroups(playerData.groups)
    
    -- Mostrar informações dos grupos
    if #allGroups > 0 then
        print("📋 Grupos de", player.Name, ":", table.concat(allGroups, ", "))
        print("🏆 Grupo mais alto:", highestGroup or "Nenhum")
    else
        print("❌ Nenhum grupo encontrado")
    end
    
    -- Aplicar cor baseada no grupo
    if highestGroup then
        local groupColor = getGroupColor(highestGroup)
        print("🎨 Cor do grupo:", groupColor)
    else
        print("📋 Sem grupos atribuídos")
    end
    
    -- Enviar mensagem de boas-vindas
    local welcomeMessage = string.format("👋 Bem-vindo, %s!", player.Name)
    if highestGroup then
        welcomeMessage = welcomeMessage .. string.format(" (Grupo: %s)", highestGroup)
    end
    chatMessageEvent:FireClient(player, welcomeMessage)
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end

-- Eventos
players.PlayerAdded:Connect(function(player)
    print("👤 Jogador entrou:", player.Name)
    
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Aguardar o character carregar completamente
        
        print("Player spawnou:", player.Name)
        
        -- Aplicar tags do jogador
        applyPlayerTags(player)
    end)
end)

print("🎮 Sistema de Spawn iniciado!")

