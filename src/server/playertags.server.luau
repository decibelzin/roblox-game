-- Sistema de Player Tags
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar módulos
local PLAYER_DEFINITION = require(ReplicatedStorage.Shared.types["player.types"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)

-- Configurar cache
local cache = { player = {} }
local playerModule = PlayerModule(cache.player)

-- Criar RemoteEvent para sincronização de grupos
local groupSyncEvent = ReplicatedStorage:FindFirstChild("GroupSyncEvent")
if not groupSyncEvent then
    groupSyncEvent = Instance.new("RemoteEvent")
    groupSyncEvent.Name = "GroupSyncEvent"
    groupSyncEvent.Parent = ReplicatedStorage
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

-- Função para sincronizar grupos de todos os jogadores
local function syncAllPlayerGroups()
    print("🔄 Sincronizando grupos de todos os jogadores...")
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = playerModule.get(player, false)
        if playerData then
            local highestGroup = getHighestGroup(playerData.groups)
            local allGroups = listPlayerGroups(playerData.groups)
            
            local message = string.format("%s -> %s", player.Name, highestGroup or "nil")
            print("📤 Enviando para todos os clientes:", message)
            
            groupSyncEvent:FireAllClients(player.Name, highestGroup, allGroups)
        end
    end
    
    print("✅ Sincronização concluída!")
end

-- Função para sincronizar grupos de um jogador específico
local function syncPlayerGroups(player)
    local playerData = playerModule.get(player, false)
    if playerData then
        local highestGroup = getHighestGroup(playerData.groups)
        local allGroups = listPlayerGroups(playerData.groups)
        
        local message = string.format("%s : %s -> %s", player.Name, player.Name, highestGroup or "nil")
        print("📤 Enviando para", player.Name, ":", message)
        
        groupSyncEvent:FireClient(player, player.Name, highestGroup, allGroups)
    end
end

-- Eventos
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        print("🔄 Sincronizando grupos para o novo jogador...")
        syncPlayerGroups(player)
        print("✅ Sincronização para novo jogador concluída!")
    end)
end)

-- Sincronização inicial
spawn(function()
    wait(2)
    print("🚀 Iniciando sincronização inicial...")
    syncAllPlayerGroups()
end)

-- Sincronização de segurança (a cada 10 segundos)
spawn(function()
    while true do
        wait(10)
        print("🔄 Sincronização de segurança...")
        syncAllPlayerGroups()
    end
end)

print("🏷️ Sistema de Player Tags iniciado!")
