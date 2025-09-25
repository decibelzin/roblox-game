local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

RegisterCommand({
    name = "userinfo",
    description = "Mostra informações de um jogador (User ID, grupos, etc.)",
    aliases = { "info", "ui" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local username = params[1]

    -- Se não especificar usuário, mostrar as próprias informações
    if not username then
        username = player.Name
    end

    -- Buscar o usuário pelo nome
    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    local isOnline = targetPlayer ~= nil
    
    local playerData, playerClass
    local customUserId
    local playerGroups = {}
    
    if isOnline then
        -- Se estiver online, usar dados do cache
        playerData, playerClass = PlayerModule.get(targetPlayer, false)
        customUserId = playerData and playerData.userId
        playerGroups = playerData and playerData.groups or {}
    else
        -- Se estiver offline, buscar dados diretamente dos DataStores
        customUserId = UserIdModule.getUserIdByRobloxId(targetUserId)
        
        -- Buscar grupos diretamente do DataStore
        local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
        local DataStoreService = game:GetService("DataStoreService")
        local groupStorage = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.group)
        
        local groupSuccess, groups = pcall(function()
            return groupStorage:GetAsync(targetUserId)
        end)
        
        if groupSuccess and type(groups) == "table" then
            playerGroups = groups
        end
    end
    
    -- Coletar grupos do jogador
    local groupsList = {}
    if playerGroups then
        local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)
        for groupName, hasGroup in pairs(playerGroups) do
            if hasGroup and GROUPS_CONFIG[groupName] then
                local groupData = GROUPS_CONFIG[groupName]
                table.insert(groupsList, groupData.name)
            end
        end
    end
    
    -- Criar mensagem de informações
    local statusText = isOnline and " (Online)" or " (Offline)"
    local infoMessage = "ℹ️ Informações de " .. username .. statusText .. ":\n"
    
    -- Adicionar User ID
    if customUserId then
        infoMessage = infoMessage .. "🆔 User ID: " .. customUserId .. "\n"
    else
        infoMessage = infoMessage .. "🆔 User ID: Não atribuído\n"
    end
    
    -- Adicionar Roblox User ID
    infoMessage = infoMessage .. "🎮 Roblox ID: " .. targetUserId .. "\n"
    
    -- Adicionar grupos
    if #groupsList > 0 then
        infoMessage = infoMessage .. "👥 Grupos: " .. table.concat(groupsList, ", ")
    else
        infoMessage = infoMessage .. "👥 Grupos: Nenhum"
    end
    
    -- Enviar mensagem para o cliente
    ChatMessage.sendInfo(player, infoMessage)
end) 