-- Sistema de interface de permissões no cliente
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PermissionUI = {}
PermissionUI.permissionGui = nil
PermissionUI.isOpen = false

-- Função para criar a interface de permissões
function PermissionUI.createPermissionGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PermissionUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔐 Sistema de Permissões"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame

    -- Botão de fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton

    -- Lista de permissões
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = mainFrame

    -- Conteúdo da lista
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame

    PermissionUI.permissionGui = screenGui
    return screenGui
end

-- Função para atualizar a lista de permissões
function PermissionUI.updatePermissionsList(permissions)
    if not PermissionUI.permissionGui then return end
    
    local scrollFrame = PermissionUI.permissionGui:FindFirstChild("MainFrame"):FindFirstChild("ScrollFrame")
    if not scrollFrame then return end
    
    -- Limpar lista atual
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Adicionar permissões
    for i, permission in ipairs(permissions) do
        local permissionFrame = Instance.new("Frame")
        permissionFrame.Name = "Permission_" .. i
        permissionFrame.Size = UDim2.new(1, 0, 0, 30)
        permissionFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        permissionFrame.BorderSizePixel = 0
        permissionFrame.Parent = scrollFrame

        local permissionCorner = Instance.new("UICorner")
        permissionCorner.CornerRadius = UDim.new(0, 5)
        permissionCorner.Parent = permissionFrame

        local permissionLabel = Instance.new("TextLabel")
        permissionLabel.Name = "PermissionLabel"
        permissionLabel.Size = UDim2.new(1, -10, 1, 0)
        permissionLabel.Position = UDim2.new(0, 5, 0, 0)
        permissionLabel.BackgroundTransparency = 1
        permissionLabel.Text = "✅ " .. permission
        permissionLabel.TextColor3 = Color3.new(1, 1, 1)
        permissionLabel.TextScaled = true
        permissionLabel.Font = Enum.Font.Gotham
        permissionLabel.TextXAlignment = Enum.TextXAlignment.Left
        permissionLabel.TextYAlignment = Enum.TextYAlignment.Center
        permissionLabel.Parent = permissionFrame
    end
    
    -- Atualizar tamanho do conteúdo
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

-- Função para mostrar informações do jogador
function PermissionUI.showPlayerInfo(playerInfo)
    if not PermissionUI.permissionGui then return end
    
    local scrollFrame = PermissionUI.permissionGui:FindFirstChild("MainFrame"):FindFirstChild("ScrollFrame")
    if not scrollFrame then return end
    
    -- Limpar lista atual
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Informações do jogador
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "PlayerInfo"
    infoFrame.Size = UDim2.new(1, 0, 0, 60)
    infoFrame.BackgroundColor3 = Color3.new(0.2, 0.4, 0.8)
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = scrollFrame

    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 5)
    infoCorner.Parent = infoFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "👤 " .. playerInfo.username
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, -10, 0.5, 0)
    levelLabel.Position = UDim2.new(0, 5, 0.5, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "🔑 Nível: " .. playerInfo.levelName
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = infoFrame

    -- Adicionar permissões
    PermissionUI.updatePermissionsList(playerInfo.permissions)
end

-- Função para alternar a interface
function PermissionUI.toggle()
    if PermissionUI.isOpen then
        PermissionUI.close()
    else
        PermissionUI.open()
    end
end

-- Função para abrir a interface
function PermissionUI.open()
    if PermissionUI.isOpen then return end
    
    if not PermissionUI.permissionGui then
        PermissionUI.createPermissionGui()
    end
    
    PermissionUI.permissionGui.Enabled = true
    PermissionUI.isOpen = true
    
    -- Conectar botão de fechar
    local closeButton = PermissionUI.permissionGui:FindFirstChild("MainFrame"):FindFirstChild("CloseButton")
    if closeButton then
        closeButton.MouseButton1Click:Connect(function()
            PermissionUI.close()
        end)
    end
end

-- Função para fechar a interface
function PermissionUI.close()
    if not PermissionUI.isOpen then return end
    
    if PermissionUI.permissionGui then
        PermissionUI.permissionGui.Enabled = false
    end
    
    PermissionUI.isOpen = false
end

-- Função para inicializar
function PermissionUI.initialize()
    -- Conectar tecla de atalho (F2)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F2 then
            PermissionUI.toggle()
        end
    end)
    
    print("Interface de permissões inicializada! Pressione F2 para abrir.")
end

return PermissionUI
