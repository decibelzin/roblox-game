local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local ITEMS_CONFIG = require(game.ReplicatedStorage.Shared.itens)

RegisterCommand({
    name = "testitems",
    description = "Dá todos os itens cadastrados para testar o inventário",
    aliases = { "testinv" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1] or player.Name
    
    -- Buscar jogador
    local targetPlayer = player
    if username ~= player.Name then
        local success, targetUserId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        
        if not success then
            ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
            return
        end
        
        targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer then
            ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não está online!")
            return
        end
    end
    
    -- Dar todos os itens cadastrados
    local itemsGiven = 0
    for itemId, itemData in pairs(ITEMS_CONFIG) do
        local quantity = math.random(1, 10) -- Quantidade aleatória entre 1 e 10
        local success = PlayerItemsModule.addItem(targetPlayer, itemId, quantity)
        if success then
            itemsGiven = itemsGiven + 1
        end
    end
    
    if itemsGiven > 0 then
        ChatMessage.sendSuccess(player, "✅ " .. itemsGiven .. " tipo(s) de item adicionado(s) ao inventário de " .. targetPlayer.Name .. "!")
        if targetPlayer ~= player then
            ChatMessage.sendSuccess(targetPlayer, "🎁 Você recebeu itens de teste no inventário!")
        end
    else
        ChatMessage.sendError(player, "❌ Nenhum item foi adicionado!")
    end
end)

