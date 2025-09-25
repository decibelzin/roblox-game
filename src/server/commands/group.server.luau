local Players         = game:GetService("Players")
local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage     = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule    = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG   = require(game.ReplicatedStorage.Shared.groups)

RegisterCommand({
    name = "group",
    description = "Dá um grupo para um usuário",
    aliases = { "g" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1]
    local group    = params[2]

    if not username or not group then
        ChatMessage.sendError(player, "❌ Uso: /group <username> <grupo>")
        return
    end

    if not GROUPS_CONFIG[group] then
        ChatMessage.sendError(player, "❌ Grupo '" .. group .. "' não existe!")
        return
    end

    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
        return
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não está online!")
        return
    end

    local targetPlayerData, targetPlayerClass = PlayerModule.get(targetPlayer, true)
    
    if not targetPlayerData or not targetPlayerClass then
        ChatMessage.sendError(player, "❌ Erro ao carregar dados do jogador!")
        return
    end

    local addSuccess = targetPlayerClass.group.add(group)

    if not addSuccess then
        ChatMessage.sendError(player, "❌ Erro ao adicionar grupo!")
        return
    end

    local groupData = GROUPS_CONFIG[group]
    local groupName = groupData and groupData.name or group

    ChatMessage.sendSuccess(player, "✅ Grupo '" .. groupName .. "' adicionado para " .. username .. "!")
end)
