-- Tela inicial com bloqueio de UI e câmera com transições sequenciais
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local uiActive = true
local scriptInitialized = false -- Previne execuções múltiplas

-- Posições da câmera para transições (coordenadas absolutas)
local cameraPositions = {
    Vector3.new(2397.686, -38.726, 47219.496),  -- Posição 1
    Vector3.new(2342.686, -38.726, 46822.496),  -- Posição 2
}

local currentPositionIndex = 1
local cameraTween = nil

-- Desabilita movimento
local function disableMovement()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.PlatformStand = true
    end
end

-- Habilita movimento
local function enableMovement()
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.PlatformStand = false
    end
end

-- Esconde UI do Roblox com verificação de segurança
local function hideUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        -- Removido PlayerList para evitar conflito com GuiService
    end)
end

-- Mostra UI do Roblox com verificação de segurança
local function showUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        -- Removido PlayerList para evitar conflito com GuiService
    end)
end

-- Configura câmera inicial
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

-- Transição para próxima posição
local function transitionToNextPosition()
    if not uiActive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = player.Character.HumanoidRootPart
    currentPositionIndex = currentPositionIndex + 1
    if currentPositionIndex > #cameraPositions then
        currentPositionIndex = 1 -- Volta para a primeira posição
    end
    
    local targetPosition = cameraPositions[currentPositionIndex]
    local lookAt = rootPart.Position
    
    -- Para o tween anterior se existir
    if cameraTween then
        cameraTween:Cancel()
    end
    
    -- Cria novo tween para a próxima posição (MUITO LENTO)
    cameraTween = TweenService:Create(camera, TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        CFrame = CFrame.lookAt(targetPosition, lookAt)
    })
    
    cameraTween:Play()
    
    -- Agenda próxima transição
    cameraTween.Completed:Connect(function()
        wait(6) -- Pausa MUITO LONGA de 6 segundos
        transitionToNextPosition()
    end)
end

-- Para transições da câmera
local function stopCameraTransitions()
    if cameraTween then
        cameraTween:Cancel()
        cameraTween = nil
    end
end

-- Restaura câmera normal
local function restoreCamera()
    stopCameraTransitions()
    camera.CameraType = Enum.CameraType.Custom
    camera.FieldOfView = 70
end

-- Esconde tela inicial
local function hideStartScreen()
    local menu = player:WaitForChild("PlayerGui"):WaitForChild("Menu")
    local frame = menu:FindFirstChild("Frame") or menu
    
    if frame:IsA("Frame") or frame:IsA("ImageLabel") then
        local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            menu.Enabled = false
            uiActive = false
            enableMovement()
            showUI()
            restoreCamera()
        end)
    else
        menu.Enabled = false
        uiActive = false
        enableMovement()
        showUI()
        restoreCamera()
    end
end

-- Conecta botão play
local function connectPlayButton()
    local playButton = player:WaitForChild("PlayerGui"):WaitForChild("Menu"):WaitForChild("Frame"):WaitForChild("main"):WaitForChild("play")
    playButton.MouseButton1Click:Connect(hideStartScreen)
end

-- Inicializa com verificação de execução única
local function init()
    -- Previne execuções múltiplas
    if scriptInitialized then
        return
    end
    scriptInitialized = true
    
    disableMovement()
    hideUI()
    setupInitialCamera()
    connectPlayButton()
    
    -- Inicia transições após 0.5 segundos (MAIS RÁPIDO)
    wait(0.5)
    transitionToNextPosition()
end

-- Bloqueia input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if uiActive and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode ~= Enum.KeyCode.Escape then
            return
        end
    end
end)

-- Executa com verificação de execução única
if player.Character then
    init()
else
    player.CharacterAdded:Connect(function()
        -- Aguarda um pouco para garantir que a UI esteja carregada
        wait(1)
        init()
    end)
end
