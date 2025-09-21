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
    name = "mygroups",
    description = "Mostra os grupos do jogador",
    aliases = { "mg" },
    permissions = {}
}, function(player, params, message)
    local playerData, playerClass = PlayerModule.get(player, true)
    
    -- Coletar grupos do jogador
    local groupsList = {}
    for groupName, hasGroup in pairs(playerData.groups) do
        if hasGroup and GROUPS_CONFIG[groupName] then
            local groupData = GROUPS_CONFIG[groupName]
            table.insert(groupsList, groupData.name)
        end
    end
    
    -- Criar mensagem para o chat
    local chatMessage
    if #groupsList > 0 then
        chatMessage = "Grupos de " .. player.Name .. ": " .. table.concat(groupsList, ", ")
    else
        chatMessage = "Grupos de " .. player.Name .. ": Nenhum"
    end
    
    -- Enviar mensagem para o cliente via RemoteEvent
    chatMessageEvent:FireClient(player, chatMessage)
    
    -- Também imprimir no console para debug
    print("=== GRUPOS DE " .. player.Name .. " ===")
    print("UserID:", player.UserId)
    print("CreatorId:", game.CreatorId)
    print("É criador:", player.UserId == game.CreatorId)
    print("Grupos:", chatMessage)
    print("================================")
end)
