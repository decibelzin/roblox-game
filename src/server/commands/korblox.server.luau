local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])

local Players = game:GetService("Players")

RegisterCommand({
    name = "korblox",
    description = "usar korblox",
    aliases = {"korblox"}
}, function(player, params, message)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end

    local humanoid = player.Character.Humanoid
    
    -- Obter a descrição atual do humanoid
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    -- Aplicar o Korblox Deathspeaker Right Leg usando o ID do asset
    humanoidDescription.RightLeg = 139607718 -- ID do Korblox Deathspeaker Right Leg
    
    -- Aplicar a nova descrição
    humanoid:ApplyDescription(humanoidDescription)
    
    print("Korblox Deathspeaker Right Leg aplicado com sucesso para " .. player.Name)
end)
