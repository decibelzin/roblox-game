local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

RegisterCommand({
    name = "clearinv",
    description = "Limpa todos os itens do inventário de um jogador pelo User ID",
    aliases = { "limparinv", "clearinventory" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local userId = tonumber(params[1])
    
    -- Validação básica
    if not userId then
        ChatMessage.sendError(player, "❌ Uso: /clearinv <userId>")
        return
    end
    
    -- Buscar jogador pelo User ID customizado
    local targetPlayer = PlayerModule.getPlayerByUserId(userId)
    if not targetPlayer then
        ChatMessage.sendError(player, "❌ Jogador com User ID " .. userId .. " não está online!")
        return
    end
    
    -- Limpar todos os itens do jogador
    local clearSuccess = PlayerItemsModule.clearAllItems(targetPlayer)
    
    if not clearSuccess then
        ChatMessage.sendError(player, "❌ Erro ao limpar inventário!")
        return
    end
    
    ChatMessage.sendSuccess(player, "✅ Inventário de " .. targetPlayer.Name .. " [ID: " .. userId .. "] foi limpo completamente!")
    ChatMessage.sendWarning(targetPlayer, "⚠️ Seu inventário foi completamente limpo por um administrador!")
end)

