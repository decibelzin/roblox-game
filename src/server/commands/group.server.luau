local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

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
        print("Uso: /group <username> <group>")
        print("Grupos disponíveis: owner, admin, moderator, vip-gold")
        return
    end

    -- Verificar se está tentando definir o grupo "owner"
    if group == "owner" and not isGameOwner(player) then
        print("Erro: Apenas o owner do jogo pode definir o grupo \"owner\"!")
        return
    end

    -- Buscar o usuário pelo nome
    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        print("Erro: Usuário \"" .. username .. "\" não encontrado!")
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        print("Erro: Usuário \"" .. username .. "\" não está online!")
        return
    end

    -- Obter dados do player alvo
    local targetPlayerData, targetPlayerClass = PlayerModule.get(targetPlayer, true)
    
    -- Tentar adicionar o grupo
    local addSuccess = targetPlayerClass.group.add(group)
    
    if addSuccess then
        print("Grupo \"" .. group .. "\" adicionado com sucesso para " .. username .. "!")
    else
        print("Erro: Falha ao adicionar grupo \"" .. group .. "\" para " .. username .. "!")
        print("Verifique se o grupo existe e se o usuário não possui um grupo da mesma organização.")
    end
end)
