local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Função para verificar se o jogador é owner do jogo
local function isGameOwner(player)
    local success, result = pcall(function()
        return player:GetRankInGroup(game.CreatorId)
    end)

    if not success then
        return false
    end

    -- Rank 255 = Owner do grupo do jogo
    return result >= 255
end
 
RegisterCommand({
    name = "group",
    description = "Dá um grupo para um usuário",
    aliases = { "g" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1]
    local group = params[2]

    -- Verificar se os parâmetros foram fornecidos
    if not username or not group then
        return
    end

    -- Verificar se o grupo existe
    if not GROUPS_CONFIG[group] then
        return
    end

    -- Verificar se está tentando definir o grupo "owner"
    if group == "owner" and not isGameOwner(player) then
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
    
    if not targetPlayerData or not targetPlayerClass then
        return
    end
    
    -- Tentar adicionar o grupo
    local addSuccess = targetPlayerClass.group.add(group)
    
    if not addSuccess then
        return
    end
    
    -- O evento framework:update.player.groups já é disparado automaticamente
    -- pelo método targetPlayerClass.group.add() quando um grupo é adicionado
end)
