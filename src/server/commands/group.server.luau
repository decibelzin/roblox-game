local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Função para verificar se o jogador é owner do jogo
local function isGameOwner(player)
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
        
        -- Para dar grupo "owner", apenas cargo "Owner" pode
        return string.lower(roleName) == "owner"
    end
    
    return false
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
        ChatMessage.sendError(player, "❌ Uso: /group <username> <grupo>")
        return
    end

    -- Verificar se o grupo existe
    if not GROUPS_CONFIG[group] then
        ChatMessage.sendError(player, "❌ Grupo '" .. group .. "' não existe!")
        return
    end

    -- Verificar se está tentando definir o grupo "owner"
    if group == "owner" and not isGameOwner(player) then
        ChatMessage.sendError(player, "❌ Apenas o owner do jogo pode dar o grupo 'owner'!")
        return
    end

    -- Buscar o usuário pelo nome
    local success, targetUserId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not success then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
        return
    end

    -- Verificar se o usuário está online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não está online!")
        return
    end

    -- Obter dados do player alvo
    local targetPlayerData, targetPlayerClass = PlayerModule.get(targetPlayer, true)
    
    if not targetPlayerData or not targetPlayerClass then
        ChatMessage.sendError(player, "❌ Erro ao carregar dados do jogador!")
        return
    end
    
    -- Tentar adicionar o grupo
    local addSuccess = targetPlayerClass.group.add(group)
    
    if not addSuccess then
        ChatMessage.sendError(player, "❌ Erro ao adicionar grupo!")
        return
    end
    
    -- Feedback de sucesso
    local groupData = GROUPS_CONFIG[group]
    local groupName = groupData and groupData.name or group
    ChatMessage.sendSuccess(player, "✅ Grupo '" .. groupName .. "' adicionado para " .. username .. "!")
    
    -- O evento framework:update.player.groups já é disparado automaticamente
    -- pelo método targetPlayerClass.group.add() quando um grupo é adicionado
end)
