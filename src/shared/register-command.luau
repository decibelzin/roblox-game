local service = game:GetService("TextChatService")
local Players = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local ChatMessage     = require(game.ServerScriptService.Server.framework.modules["chat-message"])

type DefCommand = {
    name: string,
    description: string?,
    aliases: {string}?,
    permissions: {string}? -- Lista de grupos que podem executar o comando
}

type DefCallback = (player: Player, params: {string}, message: string) -> ()

GROUP_ID = 698108551

local function isGameOwnerOrAdmin(player)
    local success, roleName = pcall(function()
        return player:GetRoleInGroup(GROUP_ID)
    end)

    if not success or not roleName then
        return false
    end
    
    local roles = {
        ["owner"] = true,
        ["admin"] = true,
    }

    return roles[string.lower(roleName)] or false
end

return function(definition: DefCommand, callback: DefCallback)
    local command = Instance.new("TextChatCommand")

    command.Name = definition.name
    command.PrimaryAlias = "/" .. definition.name
    command.Parent = service

    if definition.aliases and #definition.aliases > 0 then
        command.SecondaryAlias = "/" .. definition.aliases[1]
    end

    command.Triggered:Connect(function(textSource, message)
        local params = message:split(" ")
        table.remove(params, 1)

        local player = Players:GetPlayerByUserId(textSource.UserId)
        
        if not player then
            warn("Player não encontrado para UserId:", textSource.UserId)
            return
        end

        if definition.permissions and #definition.permissions > 0 then
            if isGameOwnerOrAdmin(player) then
            else
                local _, methods = PlayerModule.get(player, true)
                local hasPermission = methods.group.checkMany(definition.permissions)

                if not hasPermission then
                    ChatMessage.sendError(player, "❌ Você não tem permissão para executar este comando!")
                    return
                end
            end
        end

        -- Executar o callback do comando
        callback(player, params, message)
    end)
end
