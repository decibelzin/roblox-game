local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

local Players = game:GetService("Players")

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
        print("Skin resetada com sucesso para " .. player.Name)
    else
        warn("Erro ao resetar skin para " .. player.Name)
    end
end)
