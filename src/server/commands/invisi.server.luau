local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

local Players = game:GetService("Players")

local invisStates = {}
local originalTransparency = {}

local function restoreHumanoidDescription(player)
    local userId = player.UserId
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local success, description = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if success and description then
            humanoid:ApplyDescription(description)
        end
    end
end

local function storeOriginalTransparency(player)
    local userId = player.UserId
    if not originalTransparency[userId] then
        originalTransparency[userId] = {}
    end
    
    originalTransparency[userId] = {}
    
    for _, part in ipairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") then
            originalTransparency[userId][part] = part.Transparency
        elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
            originalTransparency[userId][part.Handle] = part.Handle.Transparency
        end
    end
end

local function restoreOriginalTransparency(player)
    local userId = player.UserId
    if originalTransparency[userId] then
        for part, transparency in pairs(originalTransparency[userId]) do
            if part and part.Parent then
                part.Transparency = transparency
                for _, decal in ipairs(part:GetChildren()) do
                    if decal:IsA("Decal") then
                        decal.Transparency = transparency
                    end
                end
            end
        end
        originalTransparency[userId] = {}
    end
end

Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    if originalTransparency[userId] then
        originalTransparency[userId] = nil
    end
    invisStates[userId] = nil
end)

RegisterCommand({
    name = "invisibility",
    description = "Fica invisivel ou visivel ao alternar",
    aliases = {"in", "invisi"},
    permissions = {'owner', 'admin', 'moderator', 'vip-gold'}
}, function(player, params, message)
    if not player.Character then
        return
    end

    local isInvisible = invisStates[player.UserId] or false

    if isInvisible then
        restoreHumanoidDescription(player)
        restoreOriginalTransparency(player)
        
        invisStates[player.UserId] = false
    else
        storeOriginalTransparency(player)
        
        for _, part in ipairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                for _, decal in ipairs(part:GetChildren()) do
                    if decal:IsA("Decal") then
                        decal.Transparency = 1
                    end
                end
            elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
                part.Handle.Transparency = 1
                for _, decal in ipairs(part.Handle:GetChildren()) do
                    if decal:IsA("Decal") then
                        decal.Transparency = 1
                    end
                end
            end
        end
        invisStates[player.UserId] = true
    end
end)