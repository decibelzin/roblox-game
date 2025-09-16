-- Módulo da Tela de Boas-vindas
local WelcomeScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Função para criar a tela de boas-vindas
function WelcomeScreen.createWelcomeScreen()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Criar ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WelcomeScreenGui"
    screenGui.Parent = playerGui
    
    -- Criar Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
    
    -- Título do jogo
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 600, 0, 100)
    titleLabel.Position = UDim2.new(0.5, -300, 0.3, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "NOME DO JOGO"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.FredokaOne
    titleLabel.Parent = mainFrame
    
    -- Botão de jogar
    local playButton = Instance.new("TextButton")
    playButton.Name = "PlayButton"
    playButton.Size = UDim2.new(0, 200, 0, 60)
    playButton.Position = UDim2.new(0.5, -100, 0.6, 0)
    playButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    playButton.Text = "JOGAR"
    playButton.TextColor3 = Color3.new(1, 1, 1)
    playButton.TextScaled = true
    playButton.Font = Enum.Font.FredokaOne
    playButton.Parent = mainFrame
    
    -- Adicionar cantos arredondados ao botão
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = playButton
    
    -- Função para esconder tela de boas-vindas e resetar câmera
    local function hideWelcomeScreen()
        -- Resetar câmera IMEDIATAMENTE quando clicar
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = Players.LocalPlayer.Character:WaitForChild("Humanoid")
        
        -- Reabilitar movimento do personagem
        local humanoid = Players.LocalPlayer.Character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        
        -- Remover efeitos de câmera se existirem
        for _, effect in pairs(camera:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect:Destroy()
            end
        end
        
        -- Animações da tela
        local tween = TweenService:Create(mainFrame, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        })
        
        local titleTween = TweenService:Create(titleLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            TextTransparency = 1
        })
        
        local buttonTween = TweenService:Create(playButton, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        
        tween:Play()
        titleTween:Play()
        buttonTween:Play()
        
        tween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end
    
    -- Conectar evento do botão
    playButton.MouseButton1Click:Connect(hideWelcomeScreen)
end

-- Função para configurar câmera
function WelcomeScreen.setupCamera()
    local camera = workspace.CurrentCamera
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Desabilitar movimento do personagem
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    
    -- Posicionar câmera na frente do personagem, olhando para o rosto
    local cameraOffset = Vector3.new(0, 1, -5)
    local cameraPosition = character:WaitForChild("HumanoidRootPart").Position + cameraOffset
    local headPosition = head.Position + Vector3.new(0, 0.5, 0)
    
    camera.CFrame = CFrame.lookAt(cameraPosition, headPosition)
    camera.CameraType = Enum.CameraType.Scriptable
end

-- Executar automaticamente quando o script carregar
local player = Players.LocalPlayer

-- Criar a tela de boas-vindas
WelcomeScreen.createWelcomeScreen()

-- Configurar câmera quando o personagem carregar
if player.Character then
    WelcomeScreen.setupCamera()
else
    player.CharacterAdded:Connect(function()
        WelcomeScreen.setupCamera()
    end)
end
