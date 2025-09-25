local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

RegisterCommand({
    name = "changeid",
    description = "Altera o User ID de um jogador específico",
    aliases = { "setid", "alterid" },
    permissions = { "owner" } -- Apenas owners podem alterar IDs
}, function(player, params, message)
    local username = params[1]
    local newUserIdStr = params[2]

    -- Validar parâmetros
    if not username then
        ChatMessage.sendError(player, "❌ Uso correto: /changeid <username> <novo_id>")
        return
    end

    if not newUserIdStr then
        ChatMessage.sendError(player, "❌ Você deve especificar o novo User ID!")
        return
    end

    -- Converter novo ID para número
    local newUserId = tonumber(newUserIdStr)
    if not newUserId or newUserId <= 0 then
        ChatMessage.sendError(player, "❌ O novo User ID deve ser um número positivo!")
        return
    end

    -- Buscar o usuário pelo nome
    local success, targetRobloxId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
        return
    end

    -- Verificar se o usuário já possui um User ID
    local currentUserId = UserIdModule.getUserIdByRobloxId(targetRobloxId)
    
    if not currentUserId then
        ChatMessage.sendError(player, "❌ O usuário '" .. username .. "' não possui um User ID atribuído!")
        return
    end

    -- Verificar se o novo ID é diferente do atual
    if currentUserId == newUserId then
        ChatMessage.sendError(player, "❌ O usuário '" .. username .. "' já possui o User ID " .. newUserId .. "!")
        return
    end

    -- Tentar alterar o User ID
    local changeSuccess = UserIdModule.changeUserId(targetRobloxId, newUserId)
    
    if not changeSuccess then
        ChatMessage.sendError(player, "❌ Falha ao alterar o User ID! Verifique os logs do servidor.")
        return
    end

    -- Atualizar cache se o jogador estiver online
    local targetPlayer = Players:GetPlayerByUserId(targetRobloxId)
    if targetPlayer then
        local playerData, playerClass = PlayerModule.get(targetPlayer, false)
        if playerData and playerClass then
            playerData.userId = newUserId
            print("🔄 Cache atualizado para jogador online:", targetPlayer.Name)
        end
    end

    -- Confirmar sucesso
    local successMessage = "✅ User ID alterado com sucesso!\n"
    successMessage = successMessage .. "👤 Jogador: " .. username .. "\n"
    successMessage = successMessage .. "🆔 ID Anterior: " .. currentUserId .. "\n"
    successMessage = successMessage .. "🆔 Novo ID: " .. newUserId

    ChatMessage.sendSuccess(player, successMessage)
    
    -- Log da operação
    print("🔧 [ADMIN] " .. player.Name .. " alterou o User ID de " .. username .. " de " .. currentUserId .. " para " .. newUserId)
end) 