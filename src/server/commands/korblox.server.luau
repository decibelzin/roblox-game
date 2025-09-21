local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])

local Players = game:GetService("Players")

local KORBLOX_LEG_ID = 139607718

local function EquipKorblox(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    if not humanoid:GetAttribute("OriginalRightLeg") then
        humanoid:SetAttribute("OriginalRightLeg", humanoidDescription.RightLeg)
    end
    
    humanoidDescription.RightLeg = KORBLOX_LEG_ID
    humanoid:ApplyDescription(humanoidDescription)
end

local function RemoveKorblox(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    local originalRightLeg = humanoid:GetAttribute("OriginalRightLeg")
    if originalRightLeg and originalRightLeg ~= 0 then
        humanoidDescription.RightLeg = originalRightLeg
    else
        humanoidDescription.RightLeg = 0
    end
    
    humanoid:ApplyDescription(humanoidDescription)
    humanoid:SetAttribute("OriginalRightLeg", nil)
end

RegisterCommand({
    name = "korblox",
    description = "Toggle - Alterna entre perna original e Korblox Deathspeaker Right Leg",
    aliases = {"korblox"},
    permissions = {'owner', 'admin', 'moderator', 'vip-gold'}
}, function(player, params, message)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    local isKorblox = humanoidDescription.RightLeg == KORBLOX_LEG_ID
    
    if isKorblox then
        RemoveKorblox(character)
        humanoid:SetAttribute("Korblox", false)
        print("Perna original restaurada para " .. player.Name)
    else
        EquipKorblox(character)
        humanoid:SetAttribute("Korblox", true)
        print("Korblox Deathspeaker Right Leg aplicado para " .. player.Name)
    end
end)
