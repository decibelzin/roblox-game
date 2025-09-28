local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local clickSound = game.StarterGui:WaitForChild("clicksound", 5)
local hoverSound = game.StarterGui:WaitForChild("hoversound", 5)

local function playClickSound()
    if clickSound then
        clickSound:Play()
    end
end

local function playHoverSound()
    if hoverSound then
        hoverSound:Play()
    end
end

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local uiActive = true
local scriptInitialized = false

local blurEffect = nil

local cameraPositions = {
    Vector3.new(2397.686, -38.726, 47219.496),
    Vector3.new(2342.686, -38.726, 46822.496),
}

local currentPositionIndex = 1
local cameraTween = nil

local function disableMovement()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
end

local function enableMovement()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

local function addBlur()
    if not blurEffect then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Size = 100
        blurEffect.Parent = camera
    end
end

local function removeBlur()
    if blurEffect then
        blurEffect:Destroy()
        blurEffect = nil
    end
end

local function hideUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)
    
    pcall(function()
        local miscGui = player:WaitForChild("PlayerGui"):WaitForChild("MISC")
        if miscGui then
            local blackHolder = miscGui:FindFirstChild("BlackHolder")
            if blackHolder then
                local buttonsToHide = {
                    "CodeButton",
                    "EmoteButton", 
                    "BoomboxButton",
                    "InventoryButton",
                    "ShopButton"
                }
                
                for _, buttonName in pairs(buttonsToHide) do
                    local button = blackHolder:FindFirstChild(buttonName)
                    if button then
                        button.Visible = false
                    end
                end
            end
        end
    end)
end

local function showUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
    end)
    
    pcall(function()
        local miscGui = player:WaitForChild("PlayerGui"):WaitForChild("MISC")
        if miscGui then
            local blackHolder = miscGui:FindFirstChild("BlackHolder")
            if blackHolder then
                local buttonsToShow = {
                    "CodeButton",
                    "EmoteButton", 
                    "BoomboxButton",
                    "InventoryButton",
                    "ShopButton"
                }
                
                for _, buttonName in pairs(buttonsToShow) do
                    local button = blackHolder:FindFirstChild(buttonName)
                    if button then
                        button.Visible = true
                    end
                end
            end
        end
    end)
end

local function setupInitialCamera()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = player.Character.HumanoidRootPart
        local startPosition = cameraPositions[1]
        local lookAt = rootPart.Position
        
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(startPosition, lookAt)
        camera.FieldOfView = 60
    end
end

local function transitionToNextPosition()
    if not uiActive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = player.Character.HumanoidRootPart
    currentPositionIndex = currentPositionIndex + 1
    if currentPositionIndex > #cameraPositions then
        currentPositionIndex = 1
    end
    
    local targetPosition = cameraPositions[currentPositionIndex]
    local lookAt = rootPart.Position
    
    if cameraTween then
        cameraTween:Cancel()
        cameraTween = nil
    end
    
    cameraTween = TweenService:Create(camera, TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        CFrame = CFrame.lookAt(targetPosition, lookAt)
    })
    
    cameraTween:Play()
    
    cameraTween.Completed:Connect(function()
        task.wait(6)
        transitionToNextPosition()
    end)
end

local function stopCameraTransitions()
    if cameraTween then
        cameraTween:Cancel()
        cameraTween = nil
    end
end

local function restoreCamera()
    stopCameraTransitions()
    removeBlur()
    camera.CameraType = Enum.CameraType.Custom
    camera.FieldOfView = 70
end

local function cinematicTransition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    removeBlur()
    
    local rootPart = player.Character.HumanoidRootPart
    local playerPosition = rootPart.Position
    
    local skyPosition = Vector3.new(playerPosition.X, playerPosition.Y + 200, playerPosition.Z)
    camera.CFrame = CFrame.lookAt(skyPosition, playerPosition)
    camera.FieldOfView = 70
    
    local descendTween = TweenService:Create(camera, 
        TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
        {
            CFrame = CFrame.lookAt(
                Vector3.new(playerPosition.X + 5, playerPosition.Y + 8, playerPosition.Z + 5), 
                playerPosition
            ),
            FieldOfView = 70
        }
    )
    
    descendTween:Play()
    descendTween.Completed:Connect(function()
        task.wait(0.5)
        restoreCamera()
        -- AGORA sim libera os controles e marca UI como inativa
        uiActive = false
        enableMovement()
    end)
end

local function hideStartScreen()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local welcomeScreen = playerGui:FindFirstChild("WelcomeScreen")
    if not welcomeScreen then return end
    
    local frame = welcomeScreen:FindFirstChild("Frame")
    
    if frame and (frame:IsA("Frame") or frame:IsA("ImageLabel")) then
        local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            welcomeScreen.Enabled = false
            showUI()
            cinematicTransition()
        end)
    else
        welcomeScreen.Enabled = false
        showUI()
        cinematicTransition()
    end
end

local function connectPlayButton()
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    
    local welcomeScreen = playerGui:WaitForChild("WelcomeScreen", 10)
    if not welcomeScreen then return end
    
    local frame = welcomeScreen:WaitForChild("Frame", 10)
    if not frame then return end
    
    local playButton = frame:WaitForChild("TextButton", 10)
    if not playButton then return end
    
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleContainer"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.Position = UDim2.new(0, 0, 0, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = -100
    particleContainer.Active = false
    particleContainer.Selectable = false
    particleContainer.Parent = welcomeScreen

    local particleCount = 0
    local MAX_PARTICLES = 200
    
    local function createFloatingParticle()
        local particle = Instance.new("Frame")
        particle.Name = "FloatingParticle"
        
        local size = math.random(4, 8)
        particle.Size = UDim2.new(0, size, 0, size)
        
        local screenWidth = welcomeScreen.AbsoluteSize.X
        local screenHeight = welcomeScreen.AbsoluteSize.Y
        particle.Position = UDim2.new(0, math.random(0, screenWidth), 0, math.random(0, screenHeight))
        
        local colors = {
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(11, 221, 235),
        }
        particle.BackgroundColor3 = colors[math.random(1, #colors)] 
        particle.BorderSizePixel = 0
        particle.Rotation = 45
        particle.ZIndex = -50  
        particle.Active = false
        particle.Selectable = false
        particle.Parent = particleContainer

        local targetX = particle.Position.X.Offset + math.random(-50, 50)
        local targetY = particle.Position.Y.Offset + math.random(-50, 50)
        
        local floatTween = TweenService:Create(particle, 
            TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), 
            {
                Position = UDim2.new(0, targetX, 0, targetY),
                Rotation = 45 + math.random(-15, 15),
                BackgroundTransparency = 0.7
            }
        )
        
        floatTween:Play()
        
        local lifetime = math.random(10, 15)
        Debris:AddItem(particle, lifetime)
        task.spawn(function()
            task.wait(lifetime)
            particleCount = math.max(0, particleCount - 1)
        end)
    end
    
    local function spawnFloatingParticles()
        while uiActive do
            if particleCount < MAX_PARTICLES then
                local numToCreate = math.min(math.random(8, 15), MAX_PARTICLES - particleCount)
                for i = 1, numToCreate do
                    createFloatingParticle()
                    particleCount = particleCount + 1
                end
            end
            task.wait(0.3)
        end
    end
    
    task.spawn(spawnFloatingParticles)
    
    playButton.MouseButton1Click:Connect(function()
        playClickSound()
        hideStartScreen()
    end)
    
    playButton.MouseEnter:Connect(playHoverSound)
end

local function init()
    if scriptInitialized then
        return
    end
    scriptInitialized = true
    
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    
    local welcomeScreen = playerGui:WaitForChild("WelcomeScreen", 10)
    if not welcomeScreen then return end
    
    local frame = welcomeScreen:WaitForChild("Frame", 10)
    if not frame then return end
    
    welcomeScreen.Enabled = true
    frame.Visible = true
    
    disableMovement()
    hideUI()
    addBlur()
    setupInitialCamera()
    connectPlayButton()
    
    task.wait(0.5)
    transitionToNextPosition()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if uiActive and not gameProcessed then
        -- bloquear controles
        return
    end
end)

if player.Character then
    init()
else
    player.CharacterAdded:Connect(function()
        task.wait(1)
        init()
    end)
end
