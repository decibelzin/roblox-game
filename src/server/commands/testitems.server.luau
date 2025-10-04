local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local ITEMS_MODULE = require(game.ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list

RegisterCommand({
    name = "testitems",
    description = "Dá todos os itens cadastrados para testar o inventário",
    aliases = { "testinv" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local userId = tonumber(params[1])
    local targetPlayer
    
    -- Se não passar ID, dá para si mesmo
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
        ChatMessage.sendSuccess(player, "✅ " .. itemsGiven .. " tipo(s) de item adicionado(s) ao inventário de " .. targetPlayer.Name .. " [ID: " .. userId .. "]!")
        if targetPlayer ~= player then
            ChatMessage.sendSuccess(targetPlayer, "🎁 Você recebeu itens de teste no inventário!")
        end
    else
        ChatMessage.sendError(player, "❌ Nenhum item foi adicionado!")
    end
end)

