local service = game:GetService("TextChatService")
local Players = game:GetService("Players")
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

type DefCommand = {
    name: string,
    description: string?,
    aliases: {string}?,
    permissions: {string}? -- Lista de grupos que podem executar o comando
}

type DefCallback = (player: Player, params: {string}, message: string) -> ()

-- Função para verificar se o jogador é owner ou admin do jogo
local function isGameGroupOwnerOrAdmin(player: Player): boolean
    -- Primeiro, verificar se o jogador é o criador direto do jogo
    if game.CreatorType == Enum.CreatorType.User then
        return player.UserId == game.CreatorId
    end
    
    -- Se o jogo pertence a um grupo, verificar o cargo no grupo
    if game.CreatorType == Enum.CreatorType.Group then
        local success, roleName = pcall(function()
            return player:GetRoleInGroup(game.CreatorId)
        end)
        
        if not success or not roleName then
            return false
        end
        
        -- Verificar se o cargo é owner ou admin
        local lowerRoleName = string.lower(roleName)

        print(roleName)

        return lowerRoleName == "owner" or lowerRoleName == "admin"
    end
    
    return false
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

        -- Verificar permissões se especificadas
        if definition.permissions and #definition.permissions > 0 then
            -- Se o jogador for owner ou admin do grupo do jogo, ignora a validação de permissões
            if isGameGroupOwnerOrAdmin(player) then
                -- Owner/Admin do grupo do jogo detectado - permissões ignoradas
            else
                local _, methods = PlayerModule.get(player, true)
                local hasPermission = methods.group.checkMany(definition.permissions)
                
                if not hasPermission then
                    return
                end
            end
        end

        -- Executar o callback do comando
        callback(player, params, message)
    end)
end
