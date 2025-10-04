local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])

RegisterCommand({
    name = "listitems",
    description = "Lista todos os itens de um jogador",
    aliases = { "li", "inventory" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local username = params[1] or player.Name
    
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
    
    -- Obter itens com informações
    local itemsWithInfo = PlayerItemsModule.getPlayerItemsWithInfo(targetPlayer)
    
    -- Contar total de itens
    local totalItems = 0
    local itemsList = {}
    
    for itemId, data in pairs(itemsWithInfo) do
        totalItems = totalItems + 1
        local itemName = data.item.name or "Item #" .. itemId
        table.insert(itemsList, string.format("  • %s (ID: %d) x%d", itemName, itemId, data.quantity))
    end
    
    -- Criar mensagem
    if totalItems == 0 then
        ChatMessage.sendInfo(player, "📦 Inventário de " .. username .. " está vazio!")
        return
    end
    
    -- Ordenar alfabeticamente
    table.sort(itemsList)
    
    local message = "📦 Inventário de " .. username .. " (" .. totalItems .. " tipo(s) de item):\n" .. table.concat(itemsList, "\n")
    
    ChatMessage.sendInfo(player, message)
end)

