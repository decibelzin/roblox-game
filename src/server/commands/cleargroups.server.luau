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
        print("Uso: /cleargroups <username>")
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
    
    -- Listar grupos antes de remover
    local groupsToRemove = {}
    for groupName, hasGroup in pairs(targetPlayerData.groups) do
        if hasGroup then
            table.insert(groupsToRemove, groupName)
        end
    end
    
    if #groupsToRemove == 0 then
        print("❌ " .. username .. " não possui grupos para remover!")
        return
    end
    
    print("🗑️ Removendo grupos de " .. username .. ":")
    for _, groupName in ipairs(groupsToRemove) do
        local groupData = GROUPS_CONFIG[groupName]
        local groupDisplayName = groupData and groupData.name or groupName
        print("  - " .. groupDisplayName .. " (" .. groupName .. ")")
    end
    
    -- Remover todos os grupos
    local allRemoved = true
    for _, groupName in ipairs(groupsToRemove) do
        local removeSuccess = targetPlayerClass.group.remove(groupName)
        if not removeSuccess then
            print("❌ Erro ao remover grupo: " .. groupName)
            allRemoved = false
        end
    end
    
    if allRemoved then
        print("✅ Todos os grupos foram removidos com sucesso!")
        
        -- Sincronizar grupos após remoção
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local groupSyncEvent = ReplicatedStorage:WaitForChild("GroupSyncEvent")
        
        -- Enviar atualização para todos os clientes (sem grupos)
        groupSyncEvent:FireAllClients(targetPlayer, nil)
        
        print("🔄 Jogador agora não possui grupos")
    else
        print("⚠️ Alguns grupos não puderam ser removidos!")
    end
end)
