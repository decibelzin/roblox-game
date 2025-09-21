local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local flyStateEvent = ReplicatedStorage:WaitForChild("FlyStateEvent")

local isFlying = false
local flyForce
local connection
local flySpeed = 50

local function getMoveDirection()
    local camera = workspace.CurrentCamera
    if not camera then return Vector3.new(0, 0, 0) end
    
    local lookVector = camera.CFrame.LookVector
    local rightVector = camera.CFrame.RightVector
    local moveDirection = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveDirection = moveDirection - Vector3.new(0, 1, 0)
    end
    
    return moveDirection
end

local function startFlying(speed)
    if isFlying then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    flySpeed = speed or 50
    flyForce = Instance.new("BodyVelocity")
    flyForce.Velocity = Vector3.new(0, 0, 0)
    flyForce.MaxForce = Vector3.new(4000, 4000, 4000)
    flyForce.Parent = humanoidRootPart
    
    isFlying = true
    
    connection = RunService.Heartbeat:Connect(function()
        if not isFlying or not flyForce then return end
        
        local moveDirection = getMoveDirection()
        flyForce.Velocity = moveDirection.Magnitude > 0 and moveDirection.Unit * flySpeed or Vector3.new(0, 0, 0)
    end)
end

local function stopFlying()
    if not isFlying then return end
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    if flyForce then
        flyForce:Destroy()
        flyForce = nil
    end
    
    isFlying = false
end

flyStateEvent.OnClientEvent:Connect(function(flying, speed)
    if flying then
        startFlying(speed)
    else
        stopFlying()
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        stopFlying()
    end
end)
