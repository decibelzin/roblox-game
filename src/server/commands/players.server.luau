local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

RegisterCommand({
    name = "players",
    description = "Lista todos os jogadores online com IDs e grupos",
    aliases = { "list", "online" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local onlinePlayers = Players:GetPlayers()
    
    if #onlinePlayers == 0 then
        ChatMessage.sendInfo(player, "📭 Nenhum jogador online no momento.")
        return
    end
    
    -- Coletar informações de todos os jogadores
    local playerList = {}
    
    for _, onlinePlayer in pairs(onlinePlayers) do
        local playerData, playerClass = PlayerModule.get(onlinePlayer, false)
        local userId = playerData and playerData.userId or "N/A"
        local highestGroup = playerClass and playerClass.group.getHighestGroup()
        
        -- Obter nome do grupo
        local groupName = "Nenhum"
        if highestGroup and GROUPS_CONFIG[highestGroup] then
            groupName = GROUPS_CONFIG[highestGroup].name or highestGroup
        end
        
        table.insert(playerList, {
            name = onlinePlayer.Name,
            userId = userId,
            group = groupName
        })
    end
    
    -- Ordenar por User ID (números primeiro, depois N/A)
    table.sort(playerList, function(a, b)
        if a.userId == "N/A" and b.userId ~= "N/A" then
            return false
        elseif a.userId ~= "N/A" and b.userId == "N/A" then
            return true
        elseif a.userId ~= "N/A" and b.userId ~= "N/A" then
            return tonumber(a.userId) < tonumber(b.userId)
        else
            return a.name < b.name
        end
    end)
    
    -- Criar mensagem
    local message = "👥 Jogadores Online (" .. #onlinePlayers .. "):\n"
    
    for i, playerInfo in ipairs(playerList) do
        local line = string.format("🆔 %s - %s [%s]", 
            playerInfo.userId, 
            playerInfo.name, 
            playerInfo.group
        )
        message = message .. line
        
        -- Adicionar quebra de linha se não for o último
        if i < #playerList then
            message = message .. "\n"
        end
    end
    
    message = message .. "\n💡 Use /tpto <ID> para teleportar!"
    
    ChatMessage.sendInfo(player, message)
end) 