local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Criar evento para notificar mudanças de skin
local skinUpdateEvent = ReplicatedStorage:FindFirstChild("SkinUpdateEvent")
if not skinUpdateEvent then
    skinUpdateEvent = Instance.new("RemoteEvent")
    skinUpdateEvent.Name = "SkinUpdateEvent"
    skinUpdateEvent.Parent = ReplicatedStorage
end

RegisterCommand({
    name = "copyskin",
    description = "copia a skin do player",
    aliases = {"cs", "copy"},
    permissions = {'owner', 'admin', 'moderator', 'vip-gold'}
}, function(player, params, message)
    local username = params[1]

    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if (not success) then
        return
    end

    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)

    if (not success) then
        return
    end

    local myHumanoid = player.Character.Humanoid

    myHumanoid:ApplyDescription(description)
    
    -- Notificar o client que a skin foi alterada
    skinUpdateEvent:FireClient(player)
end)