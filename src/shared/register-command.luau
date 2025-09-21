local service = game:GetService("TextChatService")
local Players = game:GetService("Players")

type DefCommand = {
    name: string,
    description: string?,
    aliases: {string}?
}

type DefCallback = (player: Player, params: {string}, message: string) -> ()

return function(definition: DefCommand, callback: DefCallback)
    local command = Instance.new("TextChatCommand")

    command.Name = definition.name
    command.PrimaryAlias = '/' .. definition.name
    command.Parent = service

    if definition.aliases and #definition.aliases > 0 then
        command.SecondaryAlias = '/' .. definition.aliases[1]
    end

    command.Triggered:Connect(function(textSource, message)
        local params = message:split(" ")
        table.remove(params, 1)

        local player = Players:GetPlayerByUserId(textSource.UserId)
        
        if player then
            callback(player, params, message)
        else
            warn("Player não encontrado para UserId:", textSource.UserId)
        end
    end)
end