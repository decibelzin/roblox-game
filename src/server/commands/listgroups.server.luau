local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Aguardar o cache global estar disponível
local globalPlayerModule, globalCache = _G.getSharedPlayerModule and _G.getSharedPlayerModule() or nil, _G.globalCache

-- Criar RemoteEvent para enviar mensagens do chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

-- Função para obter o grupo mais alto de um jogador
local function getHighestGroup(playerGroups)
    if not playerGroups or type(playerGroups) ~= "table" then
        return nil
    end
    
    local highestGroup = nil
    local highestPriority = 0
    
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

RegisterCommand({
    name = "listgroups",
    description = "Lista os grupos de um jogador (online ou offline)",
    aliases = { "lg" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1]

    -- Se não especificar usuário, mostrar os próprios grupos
    if not username then
        username = player.Name
    end

    -- Buscar o usuário pelo nome
    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        print("Erro: Usuário \"" .. username .. "\" não encontrado!")
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    local isOnline = targetPlayer ~= nil
    
    local playerGroups = {}
    local groupsList = {}
    
    if isOnline and globalPlayerModule then
        -- Se estiver online, usar dados do cache global
        local playerData = globalPlayerModule.get(targetPlayer, false)
        if playerData then
            playerGroups = playerData.groups or {}
        end
    else
        -- Se estiver offline, carregar do DataStore
        if globalPlayerModule then
            local playerData = globalPlayerModule.fetch(Players:GetPlayerByUserId(targetUserId) or {UserId = targetUserId})
            playerGroups = playerData.groups or {}
        end
    end
    
    -- Coletar grupos do jogador
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup and GROUPS_CONFIG[groupName] then
            local groupData = GROUPS_CONFIG[groupName]
            table.insert(groupsList, groupData.name)
        end
    end
    
    -- Criar mensagem para o chat
    local chatMessage
    local statusText = isOnline and " (Online)" or " (Offline)"
    
    if #groupsList > 0 then
        chatMessage = "Grupos de " .. username .. statusText .. ": " .. table.concat(groupsList, ", ")
    else
        chatMessage = "Grupos de " .. username .. statusText .. ": Nenhum"
    end
    
    -- Enviar mensagem para o cliente via RemoteEvent
    chatMessageEvent:FireClient(player, chatMessage)
    
    -- Também imprimir no console para debug
    print("=== GRUPOS DE " .. username .. " ===")
    print("UserID:", targetUserId)
    print("Status:", isOnline and "Online" or "Offline")
    print("É criador:", targetUserId == game.CreatorId)
    print("Grupos:", chatMessage)
    print("================================")
end)
