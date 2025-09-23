local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])
local Players = game:GetService("Players")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

RegisterCommand({
    name = "cleargroups",
    description = "Remove todos os grupos de um jogador",
    aliases = { "cg" },
    permissions = { "owner" }
}, function(player, params, message)
    local username = params[1]

    -- Verificar se o parâmetro foi fornecido
    if not username then
        return
    end

    -- Buscar o usuário pelo nome
    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        return
    end

    -- Obter dados do player alvo
    local targetPlayerData, targetPlayerClass = PlayerModule.get(targetPlayer, true)
    
    -- Listar grupos antes de remover
    local groupsToRemove = {}
    for groupName, hasGroup in pairs(targetPlayerData.groups) do
        if hasGroup then
            table.insert(groupsToRemove, groupName)
        end
    end
    
    if #groupsToRemove == 0 then
        return
    end
    
    for _, groupName in ipairs(groupsToRemove) do
        local groupData = GROUPS_CONFIG[groupName]
        local groupDisplayName = groupData and groupData.name or groupName
    end
    
    -- Remover todos os grupos
    local allRemoved = true
    for _, groupName in ipairs(groupsToRemove) do
        local removeSuccess = targetPlayerClass.group.remove(groupName)
        if not removeSuccess then
            allRemoved = false
        end
    end
    
    if not allRemoved then
        return
    end
    
    -- O evento framework:update.player.groups já é disparado automaticamente
    -- pelo método targetPlayerClass.group.remove() quando um grupo é removido
end)
