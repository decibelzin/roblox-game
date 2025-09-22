local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

local Players = game:GetService("Players")

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
end)