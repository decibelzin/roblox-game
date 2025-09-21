local service = game:GetService("TextChatService")

type DefCommand = {
    name: string,
    description: string?
}

type DefCallback = (textSource: TextSource, params: {string}, message: string) -> ()

return function(definition: DefCommand, callback: DefCallback)
    local command = Instance.new("TextChatCommand")

    command.Name = definition.name
    command.PrimaryAlias = '/' .. command.name
    command.Parent = service

    command.Triggered:Connect(function(textSource, message)
        local params = message:split(" ")
        table.remove(params, 1)

        callback(textSource, params, message)
    end)
end