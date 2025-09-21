-- Servidor para sincronizar grupos com o cliente
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar o módulo de player
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

-- Criar RemoteEvent para sincronizar grupos
local groupSyncEvent = Instance.new("RemoteEvent")
groupSyncEvent.Name = "GroupSyncEvent"
groupSyncEvent.Parent = ReplicatedStorage

-- Função para obter o grupo mais alto de um jogador
local function getHighestGroup(playerGroups)
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

-- Função para sincronizar grupos de todos os jogadores
local function syncAllPlayerGroups()
    print("🔄 Sincronizando grupos de todos os jogadores...")
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        local playerData, playerClass = PlayerModule.get(targetPlayer, true)
        local highestGroup = getHighestGroup(playerData.groups)
        
        print("📤 Enviando para todos os clientes:", targetPlayer.Name, "->", highestGroup or "nil")
        
        -- Enviar para todos os clientes (incluindo o próprio jogador)
        groupSyncEvent:FireAllClients(targetPlayer, highestGroup)
    end
    print("✅ Sincronização concluída!")
end

-- Função para sincronizar grupos de um jogador específico
local function syncPlayerGroups(targetPlayer)
    local playerData, playerClass = PlayerModule.get(targetPlayer, true)
    local highestGroup = getHighestGroup(playerData.groups)
    
    print("�� Sincronizando", targetPlayer.Name, "->", highestGroup or "nil")
    
    -- Enviar para todos os clientes
    groupSyncEvent:FireAllClients(targetPlayer, highestGroup)
end

-- Quando um jogador entra
Players.PlayerAdded:Connect(function(player)
    print("👤 Jogador entrou:", player.Name)
    
    -- Aguardar um pouco para garantir que o cliente esteja pronto
    wait(3)
    
    -- Sincronizar grupos de todos os jogadores para o novo jogador
    print("🔄 Sincronizando grupos para o novo jogador...")
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        local playerData, playerClass = PlayerModule.get(targetPlayer, true)
        local highestGroup = getHighestGroup(playerData.groups)
        
        print("📤 Enviando para", player.Name, ":", targetPlayer.Name, "->", highestGroup or "nil")
        groupSyncEvent:FireClient(player, targetPlayer, highestGroup)
    end
    print("✅ Sincronização para novo jogador concluída!")
end)

-- Quando um jogador sai
Players.PlayerRemoving:Connect(function(player)
    print("👋 Jogador saindo:", player.Name)
    -- Notificar todos os clientes que o jogador saiu
    groupSyncEvent:FireAllClients(player, nil)
end)

-- Sincronizar grupos iniciais após um delay
wait(2)
print("🚀 Iniciando sincronização inicial...")
syncAllPlayerGroups()

-- Sincronizar novamente após 5 segundos para garantir
wait(5)
print("🔄 Sincronização de segurança...")
syncAllPlayerGroups()
