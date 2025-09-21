local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local cache = {
    player = {}
}
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)(cache.player)

local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Criar RemoteEvent para enviar mensagens do chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

RegisterCommand({
    name = "listgroups",
    description = "Lista os grupos de um jogador",
    aliases = { "lg" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local username = params[1]

    -- Se não especificar usuário, mostrar os próprios grupos
    if not username then
        username = player.Name
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
    
    -- Coletar grupos do jogador
    local groupsList = {}
    for groupName, hasGroup in pairs(targetPlayerData.groups) do
        if hasGroup and GROUPS_CONFIG[groupName] then
            local groupData = GROUPS_CONFIG[groupName]
            table.insert(groupsList, groupData.name)
        end
    end
    
    -- Criar mensagem para o chat
    local chatMessage
    if #groupsList > 0 then
        chatMessage = "Grupos de " .. username .. ": " .. table.concat(groupsList, ", ")
    else
        chatMessage = "Grupos de " .. username .. ": Nenhum"
    end
    
    -- Enviar mensagem para o cliente via RemoteEvent
    chatMessageEvent:FireClient(player, chatMessage)
    
    -- Também imprimir no console para debug
    print("=== GRUPOS DE " .. username .. " ===")
    print("UserID:", targetPlayer.UserId)
    print("É criador:", targetPlayer.UserId == game.CreatorId)
    print("Grupos:", chatMessage)
    print("================================")
end)
