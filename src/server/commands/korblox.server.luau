local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])

local Players = game:GetService("Players")

local originalLegs = {}
RegisterCommand({
    name = "korblox",
    description = "usar korblox",
    aliases = {"korblox"}
}, function(player, params, message)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end

    local humanoid = player.Character.Humanoid
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    if humanoidDescription.RightLeg == 139607718 then
        if originalLegs[player.UserId] then
            humanoidDescription.RightLeg = originalLegs[player.UserId]
        else
            humanoidDescription.RightLeg = 0
        end
        print("Perna original restaurada para " .. player.Name)
    else
        originalLegs[player.UserId] = humanoidDescription.RightLeg
        humanoidDescription.RightLeg = 139607718
        print("Korblox Deathspeaker Right Leg aplicado para " .. player.Name)
    end
    
    humanoid:ApplyDescription(humanoidDescription)
end)
