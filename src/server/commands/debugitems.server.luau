local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

RegisterCommand({
    name = "debugitems",
    description = "Debug detalhado do sistema de itens",
    aliases = { "debuginv" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local userId = tonumber(params[1])
    local targetPlayer
    
    -- Se não passar ID, debug para si mesmo
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
    
    -- Obter itens do cache
    local items = PlayerItemsModule.getPlayerItems(targetPlayer)
    local order = PlayerItemsModule.getPlayerOrder(targetPlayer)
    local hotbar = PlayerItemsModule.getHotbar(targetPlayer)
    
    print("========================================")
    print("🔍 DEBUG ITENS - Jogador:", targetPlayer.Name, "[UserId:", userId, "]")
    print("========================================")
    
    print("\n📦 ITENS NO CACHE:")
    local itemCount = 0
    for itemId, quantity in pairs(items) do
        itemCount = itemCount + 1
        print("  - Item ID:", itemId, "| Quantidade:", quantity)
    end
    if itemCount == 0 then
        print("  (vazio)")
    end
    
    print("\n📋 ORDEM DOS ITENS:")
    local orderCount = 0
    for uniqueId, position in pairs(order) do
        orderCount = orderCount + 1
        print("  - UniqueId:", uniqueId, "| Posição:", position)
    end
    if orderCount == 0 then
        print("  (vazio)")
    end
    
    print("\n🎯 HOTBAR:")
    local hotbarCount = 0
    for slotIndex, slotData in pairs(hotbar) do
        hotbarCount = hotbarCount + 1
        print("  - Slot", slotIndex, "| Item ID:", slotData.itemId, "| Quantidade:", slotData.quantity)
    end
    if hotbarCount == 0 then
        print("  (vazio)")
    end
    
    print("\n========================================")
    print("Total de tipos de itens:", itemCount)
    print("Total de posições na ordem:", orderCount)
    print("Total de slots na hotbar:", hotbarCount)
    print("========================================\n")
    
    ChatMessage.sendSuccess(player, "✅ Debug completo no console do servidor!")
end)

