local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local ITEMS_CONFIG = require(game.ReplicatedStorage.Shared.itens)

RegisterCommand({
    name = "itemlist",
    description = "Lista todos os itens disponíveis no jogo",
    aliases = { "items", "allitems" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local itemsList = {}
    local totalItems = 0
    
    -- Coletar todos os itens
    for itemId, itemData in pairs(ITEMS_CONFIG) do
        totalItems = totalItems + 1
        local itemName = itemData.name or "Item #" .. itemId
        table.insert(itemsList, {
            id = itemId,
            name = itemName,
            text = string.format("  • [ID: %d] %s", itemId, itemName)
        })
    end
    
    if totalItems == 0 then
        ChatMessage.sendWarning(player, "⚠️ Nenhum item cadastrado no sistema!")
        return
    end
    
    -- Ordenar por ID
    table.sort(itemsList, function(a, b)
        return a.id < b.id
    end)
    
    -- Criar lista de textos
    local itemsText = {}
    for _, item in ipairs(itemsList) do
        table.insert(itemsText, item.text)
    end
    
    local message = "📋 Itens Disponíveis (" .. totalItems .. " total):\n" .. table.concat(itemsText, "\n")
    
    ChatMessage.sendInfo(player, message)
end)

