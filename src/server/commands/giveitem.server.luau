local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local ITEMS_CONFIG = require(game.ReplicatedStorage.Shared.itens)

RegisterCommand({
    name = "giveitem",
    description = "Dá um item para um jogador",
    aliases = { "gi", "item" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local username = params[1]
    local itemId = tonumber(params[2])
    local quantity = tonumber(params[3]) or 1
    
    -- Validações
    if not username or not itemId then
        ChatMessage.sendError(player, "❌ Uso: /giveitem <username> <itemId> [quantidade]")
        return
    end
    
    -- Verificar se o item existe
    if not ITEMS_CONFIG[itemId] then
        ChatMessage.sendError(player, "❌ Item ID '" .. itemId .. "' não existe!")
        return
    end
    
    -- Buscar jogador
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
    
    -- Dar o item
    local addSuccess = PlayerItemsModule.addItem(targetPlayer, itemId, quantity)
    
    if not addSuccess then
        ChatMessage.sendError(player, "❌ Erro ao adicionar item!")
        return
    end
    
    local itemConfig = ITEMS_CONFIG[itemId]
    local itemName = itemConfig.name or "Item #" .. itemId
    
    ChatMessage.sendSuccess(player, "✅ " .. quantity .. "x '" .. itemName .. "' dado(s) para " .. username .. "!")
    ChatMessage.sendSuccess(targetPlayer, "🎁 Você recebeu " .. quantity .. "x '" .. itemName .. "'!")
end)

