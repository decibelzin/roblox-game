local service = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- Importar o módulo de player para verificar permissões
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)({})

type DefCommand = {
    name: string,
    description: string?,
    aliases: {string}?,
    permissions: {string}? -- Lista de grupos que podem executar o comando
}

type DefCallback = (player: Player, params: {string}, message: string) -> ()

-- Função para verificar se o jogador é owner ou admin do grupo do jogo
local function isGameGroupOwnerOrAdmin(player: Player): boolean
    local success, result = pcall(function()
        return player:GetRankInGroup(game.CreatorId)
    end)
    
    if not success then
        return false
    end
    
    -- Rank 255 = Owner, Rank 254 = Admin (valores típicos do Roblox)
    return result >= 254
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
                print("Owner/Admin do grupo do jogo detectado - permissões ignoradas")
            else
                local playerData, playerClass = PlayerModule.get(player, true)
                local hasPermission = playerClass.group.checkMany(definition.permissions)
                
                if not hasPermission then
                    print("Você não tem permissão para usar este comando!")
                    print("Grupos necessários: " .. table.concat(definition.permissions, ", "))
                    return
                end
            end
        end

        -- Executar o callback do comando
        callback(player, params, message)
    end)
end
