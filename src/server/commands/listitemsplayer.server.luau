local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

RegisterCommand({
    name = "listitems",
    description = "Lista todos os itens de um jogador pelo User ID",
    aliases = { "li", "inventory" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local userId = tonumber(params[1])
    local targetPlayer
    
    -- Se não passar ID, lista os próprios itens
    if not userId then
        targetPlayer = player
        local playerData, _ = PlayerModule.get(player, false)
        userId = playerData and playerData.userId or 0
    else
        -- Buscar jogador pelo User ID customizado
        targetPlayer = PlayerModule.getPlayerByUserId(userId)
        if not targetPlayer then
            ChatMessage.sendError(player, "❌ Jogador com User ID " .. userId .. " não está online!")
            return
        end
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
        ChatMessage.sendInfo(player, "📦 Inventário de " .. targetPlayer.Name .. " [ID: " .. userId .. "] está vazio!")
        return
    end
    
    -- Ordenar alfabeticamente
    table.sort(itemsList)
    
    local message = "📦 Inventário de " .. targetPlayer.Name .. " [ID: " .. userId .. "] (" .. totalItems .. " tipo(s) de item):\n" .. table.concat(itemsList, "\n")
    
    ChatMessage.sendInfo(player, message)
end)

