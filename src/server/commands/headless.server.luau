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

local HEADLESS_HEAD_ID = 15093053680

local function EquipHeadless(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    if not humanoid:GetAttribute("OriginalHead") then
        humanoid:SetAttribute("OriginalHead", humanoidDescription.Head)
    end
    
    humanoidDescription.Head = HEADLESS_HEAD_ID
    humanoid:ApplyDescription(humanoidDescription)
end

local function RemoveHeadless(character)
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    local originalHead = humanoid:GetAttribute("OriginalHead")
    if originalHead and originalHead ~= 0 then
        humanoidDescription.Head = originalHead
    else
        humanoidDescription.Head = 0
    end
    
    humanoid:ApplyDescription(humanoidDescription)
    humanoid:SetAttribute("OriginalHead", nil)
end

RegisterCommand({
    name = "headless",
    description = "Toggle - Alterna entre cabeça original e Headless Head",
    aliases = {"hl", "head"},
    permissions = {'owner', 'admin', 'moderator', 'vip-gold'}
}, function(player, params, message)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local humanoidDescription = humanoid:GetAppliedDescription()
    
    if humanoidDescription.Head == HEADLESS_HEAD_ID then
        RemoveHeadless(character)
    else
        EquipHeadless(character)
    end
    
    -- Notificar o client que a skin foi alterada
    skinUpdateEvent:FireClient(player)
end)