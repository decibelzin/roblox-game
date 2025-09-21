local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])
local Players = game:GetService("Players")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

RegisterCommand({
    name = "ungroup",
    description = "Remove um grupo de um usuário",
    aliases = { "ug" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1]
    local group = params[2]

    -- Verificar se os parâmetros foram fornecidos
    if not username or not group then
        print("Uso: /ungroup <username> <group>")
        print("Grupos disponíveis: owner, admin, moderator, vip-gold")
        return
    end

    -- Verificar se o grupo existe
    if not GROUPS_CONFIG[group] then
        print("Erro: Grupo \"" .. group .. "\" não existe!")
        print("Grupos disponíveis: owner, admin, moderator, vip-gold")
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
    
    -- Verificar se o jogador tem o grupo
    if not targetPlayerClass.group.checkOne(group) then
        print("Erro: " .. username .. " não possui o grupo \"" .. group .. "\"!")
        return
    end
    
    -- Tentar remover o grupo
    local removeSuccess = targetPlayerClass.group.remove(group)
    
    if removeSuccess then
        print("✅ Grupo \"" .. group .. "\" removido com sucesso de " .. username .. "!")
        
        -- Sincronizar grupos após remoção
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local groupSyncEvent = ReplicatedStorage:WaitForChild("GroupSyncEvent")
        
        -- Obter o novo grupo mais alto
        local priorities = {
            owner = 4,
            admin = 3,
            moderator = 2,
            ["vip-gold"] = 1
        }
        
        local highestGroup = nil
        local highestPriority = 0
        
        for groupName, hasGroup in pairs(targetPlayerData.groups) do
            if hasGroup and priorities[groupName] and priorities[groupName] > highestPriority then
                highestPriority = priorities[groupName]
                highestGroup = groupName
            end
        end
        
        -- Enviar atualização para todos os clientes
        groupSyncEvent:FireAllClients(targetPlayer, highestGroup)
        
        if highestGroup then
            print("🔄 Novo grupo principal: " .. (GROUPS_CONFIG[highestGroup] and GROUPS_CONFIG[highestGroup].name or highestGroup))
        else
            print("🔄 Jogador agora não possui grupos")
        end
    else
        print("❌ Erro: Falha ao remover grupo \"" .. group .. "\" de " .. username .. "!")
    end
end)
