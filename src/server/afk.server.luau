
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local afkParts = {}
local updateConnections = {}

local remoteEvent = ReplicatedStorage:FindFirstChild("AFKDetection")
if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "AFKDetection"
    remoteEvent.Parent = ReplicatedStorage
end

local function createAFKPart(player)
    if afkParts[player] then 
        return 
    end

    local character = player.Character
    if not character then 
        return 
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then 
        return 
    end

    local rootPart = humanoid.RootPart
    if not rootPart then 
        return 
    end

    local originalPart = workspace:FindFirstChild("zzz")
    if not originalPart then 
        return 
    end

    local zzzPart = originalPart:Clone()
    zzzPart.Name = "zzz_" .. player.Name
    zzzPart.Transparency = 1
    zzzPart.CanCollide = false
    zzzPart.Anchored = false
    zzzPart.CFrame = rootPart.CFrame * CFrame.new(0, 4, 0)
    zzzPart.Parent = workspace

    local particleEmitter = zzzPart:FindFirstChildOfClass("ParticleEmitter")
    if particleEmitter then
        particleEmitter.Enabled = true
    end

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if zzzPart and zzzPart.Parent and rootPart and rootPart.Parent then
            zzzPart.CFrame = rootPart.CFrame * CFrame.new(0, 4, 0)
        else
            if connection then
                connection:Disconnect()
                updateConnections[player] = nil
            end
        end
    end)

    updateConnections[player] = connection
    afkParts[player] = zzzPart
end

local function removeAFKPart(player)
    local part = afkParts[player]
    local connection = updateConnections[player]

    if connection then
        connection:Disconnect()
        updateConnections[player] = nil
    end

    if part then
        part:Destroy()
        afkParts[player] = nil
    end
end

local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        removeAFKPart(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)


remoteEvent.OnServerEvent:Connect(function(player, action)
    if action == "AFK_START" then
        createAFKPart(player)
    elseif action == "AFK_END" then
        removeAFKPart(player)
    end
end)

Players.PlayerRemoving:Connect(removeAFKPart)
