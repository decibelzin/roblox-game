-- Serviço responsável por gerenciar a interface do usuário
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameConfig"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("utils"):WaitForChild("Utils"))

local UIService = {}
UIService.menuGui = nil
UIService.isInMenu = true

-- Função para ocultar elementos padrão do Roblox
function UIService.hideDefaultGui()
    -- Ocultar a interface padrão do Roblox (incluindo chat)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    
    -- Ocultar elementos existentes do PlayerGui
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui.Name ~= "MainMenu" then
            gui:Destroy()
        end
    end
    
    print("Interface padrão do Roblox ocultada (chat desabilitado)")
end

-- Função para restaurar elementos padrão do Roblox
function UIService.restoreDefaultGui()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    
    print("Interface padrão do Roblox restaurada (chat habilitado)")
end

-- Função para criar o menu principal
function UIService.createMainMenu()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui

    -- Título do jogo (centralizado)
    local titleLabel = Utils.createTextLabel({
        Name = "TitleLabel",
        Size = GameConfig.UI.TITLE_SIZE,
        Position = GameConfig.UI.TITLE_POSITION,
        BackgroundTransparency = 1,
        Text = GameConfig.GAME_NAME,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Parent = mainFrame
    })

    -- Botão PLAY (centralizado)
    local playButton = Utils.createTextButton({
        Name = "PlayButton",
        Size = GameConfig.UI.PLAY_BUTTON_SIZE,
        Position = GameConfig.UI.PLAY_BUTTON_POSITION,
        BackgroundColor3 = Color3.new(0.2, 0.8, 0.2),
        Text = "PLAY",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = mainFrame
    })

    -- Adicionar cantos arredondados ao botão
    local corner = Utils.createRoundedCorner(GameConfig.UI.CORNER_RADIUS)
    corner.Parent = playButton

    UIService.menuGui = screenGui
    return screenGui
end

-- Função para remover o menu
function UIService.removeMainMenu()
    if UIService.menuGui then
        UIService.menuGui:Destroy()
        UIService.menuGui = nil
    end
end

-- Função para conectar eventos do menu
function UIService.connectMenuEvents(onPlayClicked)
    if not UIService.menuGui then return end
    
    local playButton = UIService.menuGui:FindFirstChild("MainFrame"):FindFirstChild("PlayButton")
    if playButton then
        playButton.MouseButton1Click:Connect(onPlayClicked)
        print("Botão PLAY conectado!")
    else
        print("ERRO: Botão PLAY não encontrado!")
    end
end

return UIService
