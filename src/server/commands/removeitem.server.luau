local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local ITEMS_MODULE = require(game.ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list
local ITEMS_BY_INDEX = ITEMS_MODULE.byIndex

RegisterCommand({
    name = "removeitem",
    description = "Remove um item de um jogador pelo User ID",
    aliases = { "ri", "takeitem" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local userId = tonumber(params[1])
    local itemIdentifier = params[2] -- Pode ser ID ou nome
    local quantity = tonumber(params[3]) or 1
    
    -- Validações básicas
    if not userId or not itemIdentifier then
        ChatMessage.sendError(player, "❌ Uso: /removeitem <userId> <itemId ou nome> [quantidade]")
        return
    end
    
    -- Tentar converter para ID (se for número) ou buscar por nome
    local itemId = tonumber(itemIdentifier)
    if not itemId then
        -- Não é número, buscar por nome
        local trimmed = string.gsub(itemIdentifier, "^%s*(.-)%s*$", "%1")
        local normalizedName = string.lower(trimmed)
        itemId = ITEMS_BY_INDEX[normalizedName]
        
        if not itemId then
            ChatMessage.sendError(player, "❌ Item '" .. itemIdentifier .. "' não encontrado!")
            return
        end
    end
    
    -- Verificar se o item existe
    if not ITEMS_CONFIG[itemId] then
        ChatMessage.sendError(player, "❌ Item ID '" .. itemId .. "' não existe!")
        return
    end
    
    -- Buscar jogador pelo User ID customizado
    local targetPlayer = PlayerModule.getPlayerByUserId(userId)
    if not targetPlayer then
        ChatMessage.sendError(player, "❌ Jogador com User ID " .. userId .. " não está online!")
        return
    end
    
    -- Remover o item
    local removeSuccess = PlayerItemsModule.removeItem(targetPlayer, itemId, quantity)
    
    if not removeSuccess then
        ChatMessage.sendError(player, "❌ Erro ao remover item! Verifique se o jogador possui quantidade suficiente.")
        return
    end
    
    local itemConfig = ITEMS_CONFIG[itemId]
    local itemName = itemConfig.name or "Item #" .. itemId
    
    ChatMessage.sendSuccess(player, "✅ " .. quantity .. "x '" .. itemName .. "' removido(s) de " .. targetPlayer.Name .. " [ID: " .. userId .. "]!")
    ChatMessage.sendWarning(targetPlayer, "⚠️ " .. quantity .. "x '" .. itemName .. "' foi(ram) removido(s) do seu inventário!")
end)

