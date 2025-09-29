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
    name = "resetskin",
    description = "Reseta a skin do personagem para a skin atual",
    aliases = {"rs", "reset"}
}, function(player, params, message)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end

    local humanoid = player.Character.Humanoid
    
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)
    
    if success then
        humanoid:ApplyDescription(description)
        -- Notificar o client que a skin foi alterada
        skinUpdateEvent:FireClient(player)
    else
        warn("Erro ao resetar skin para " .. player.Name)
    end
end)
