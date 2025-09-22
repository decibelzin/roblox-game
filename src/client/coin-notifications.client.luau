-- Sistema de Notificações de Moedas - Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Aguardar RemoteEvents
local coinNotificationEvent = ReplicatedStorage:WaitForChild("CoinNotification")

-- Variáveis do UI
local notificationGui = nil
local soundEffect = nil

-- Função para criar a interface de notificação
local function createNotificationGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CoinNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "IconLabel"
    iconLabel.Size = UDim2.new(0, 50, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "💰"
    iconLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -70, 0, 30)
    titleLabel.Position = UDim2.new(0, 70, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Moedas Ganhas!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "AmountLabel"
    amountLabel.Size = UDim2.new(1, -70, 0, 30)
    amountLabel.Position = UDim2.new(0, 70, 0, 40)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "+0 moedas"
    amountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    amountLabel.TextScaled = true
    amountLabel.Font = Enum.Font.Gotham
    amountLabel.Parent = frame
    
    -- Inicialmente escondido
    frame.Visible = false
    
    notificationGui = screenGui
end

-- Função para criar som de moeda
local function createCoinSound()
    local sound = Instance.new("Sound")
    sound.Name = "CoinSound"
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Som padrão do Roblox
    sound.Volume = 0.5
    sound.Parent = SoundService
    return sound
end

-- Função para mostrar notificação
local function showNotification(amount, reason)
    if not notificationGui then
        createNotificationGui()
    end
    
    local frame = notificationGui.NotificationFrame
    local amountLabel = frame.AmountLabel
    
    -- Atualizar texto
    amountLabel.Text = string.format("+%d moedas", amount)
    
    -- Mostrar notificação
    frame.Visible = true
    frame.Position = UDim2.new(1, -320, 0, 20)
    
    -- Animação de entrada
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -320, 0, 20)
    })
    
    -- Animação de saída
    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, 20, 0, 20)
    })
    
    -- Tocar som
    if not soundEffect then
        soundEffect = createCoinSound()
    end
    soundEffect:Play()
    
    -- Executar animações
    tweenIn:Play()
    
    -- Esconder após 3 segundos
    spawn(function()
        wait(3)
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            frame.Visible = false
        end)
    end)
end

-- Conectar ao evento do servidor
coinNotificationEvent.OnClientEvent:Connect(function(amount, reason)
    showNotification(amount, reason)
end)

-- Inicializar interface (mas não mostrar)
player.CharacterAdded:Connect(function()
    wait(1)
    if not notificationGui then
        createNotificationGui()
    end
end)

