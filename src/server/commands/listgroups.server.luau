local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

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
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    local isOnline = targetPlayer ~= nil
    
    local playerGroups = {}
    local groupsList = {}
    
    if isOnline then
        -- Se estiver online, usar dados do cache
        local playerData, playerClass = PlayerModule.get(targetPlayer, false)
        if playerData and playerClass then
            playerGroups = playerData.groups or {}
        end
    else
        -- Se estiver offline, carregar do DataStore
        local fakePlayer = {UserId = targetUserId}
        local playerData = PlayerModule.fetch(fakePlayer)
        playerGroups = playerData.groups or {}
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
    
    -- Enviar mensagem para o cliente via módulo ChatMessage
    ChatMessage.sendInfo(player, chatMessage)
end)
