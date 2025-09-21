local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Criar RemoteEvent para enviar mensagens do chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

-- Função para buscar grupos de um jogador (online ou offline)
local function getPlayerGroups(userId)
    local groupStorage = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.group)
    local success, groups = pcall(function()
        return groupStorage:GetAsync(userId)
    end)
    
    return success and groups or {}
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
    
    -- Buscar grupos do jogador (funciona mesmo se estiver offline)
    local playerGroups = getPlayerGroups(targetUserId)
    
    -- Coletar grupos do jogador
    local groupsList = {}
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
