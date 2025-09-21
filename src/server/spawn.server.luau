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

-- Função para verificar se o jogador é o criador do jogo
local function isGameCreator(player)
    return player.UserId == game.CreatorId
end

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

-- Função para listar todos os grupos de um jogador
local function listPlayerGroups(playerGroups)
    local groups = {}
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup and GROUPS_CONFIG[groupName] then
            table.insert(groups, GROUPS_CONFIG[groupName].name)
        end
    end
    return groups
end

-- Função para verificar se o jogador tem permissão de staff
local function isStaff(player)
    local playerData, playerClass = PlayerModule.get(player, true)
    local highestGroup = getHighestGroup(playerData.groups)
    
    -- Verificar se é owner ou admin
    return highestGroup == "owner" or highestGroup == "admin"
end

players.PlayerAdded:Connect(function(player)
    -- Verificar se é o criador do jogo e definir grupo owner automaticamente
    if isGameCreator(player) then
        print("🎮 Criador do jogo detectado:", player.Name)
        
        -- Aguardar um pouco para garantir que os dados do player estejam carregados
        wait(1)
        
        -- Obter dados do player
        local playerData, playerClass = PlayerModule.get(player, true)
        
        -- Verificar se já tem o grupo owner
        if not playerClass.group.checkOne("owner") then
            print("👑 Definindo grupo 'owner' para o criador do jogo...")
            local success = playerClass.group.add("owner")
            if success then
                print("✅ Grupo 'owner' adicionado com sucesso!")
            else
                print("❌ Erro ao adicionar grupo 'owner'")
            end
        else
            print("✅ Já possui grupo 'owner'")
        end
    end
    
    player.CharacterAdded:Connect(function(character)
        print("Player spawnou:", player.Name)
        
        -- Aguardar um pouco para garantir que os dados do player estejam carregados
        wait(1)
        
        -- Obter dados do player
        local playerData, playerClass = PlayerModule.get(player, true)
        
        -- Obter o grupo mais alto
        local highestGroup = getHighestGroup(playerData.groups)
        
        -- Listar todos os grupos
        local allGroups = listPlayerGroups(playerData.groups)
        
        -- Mostrar informações dos grupos
        if highestGroup and GROUPS_CONFIG[highestGroup] then
            local groupData = GROUPS_CONFIG[highestGroup]
            print("🎖️ Grupo principal:", groupData.name)
            print("🎨 Cor:", tostring(groupData.color))
        else
            print("❌ Nenhum grupo encontrado")
        end
        
        if #allGroups > 0 then
            print("📋 Todos os grupos:", table.concat(allGroups, ", "))
        else
            print("📋 Sem grupos atribuídos")
        end
        
        -- Verificar se é staff e enviar mensagem no chat
        if isStaff(player) then
            local groupData = GROUPS_CONFIG[highestGroup]
            local groupName = groupData and groupData.name or highestGroup
            local chatMessage = "👑 " .. player.Name .. " (" .. groupName .. ") entrou no jogo!"
            
            -- Enviar mensagem para todos os clientes
            chatMessageEvent:FireAllClients(chatMessage)
            print("📢 Mensagem de staff enviada:", chatMessage)
        end
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    end)
end)
