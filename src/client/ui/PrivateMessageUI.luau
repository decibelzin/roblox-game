-- Sistema de interface para mensagens privadas no cliente (versão simplificada)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PrivateMessageUI = {}
PrivateMessageUI.messageGui = nil
PrivateMessageUI.messages = {}
PrivateMessageUI.maxMessages = 5

-- Função para criar a interface de mensagens
function PrivateMessageUI.createMessageGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PrivateMessageUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Frame principal para mensagens
    local messageFrame = Instance.new("Frame")
    messageFrame.Name = "MessageFrame"
    messageFrame.Size = UDim2.new(0, 350, 0, 150)
    messageFrame.Position = UDim2.new(1, -370, 0, 20)
    messageFrame.BackgroundTransparency = 1
    messageFrame.Parent = screenGui

    -- Lista de mensagens
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
    scrollFrame.Parent = messageFrame

    -- Layout da lista
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = scrollFrame

    PrivateMessageUI.messageGui = screenGui
    return screenGui
end

-- Função para criar uma mensagem individual
function PrivateMessageUI.createMessage(messageData)
    if not PrivateMessageUI.messageGui then 
        print("Erro: messageGui não existe")
        return 
    end
    
    local mainFrame = PrivateMessageUI.messageGui:FindFirstChild("MessageFrame")
    if not mainFrame then 
        print("Erro: MessageFrame não encontrado")
        return 
    end
    
    local scrollFrame = mainFrame:FindFirstChild("ScrollFrame")
    if not scrollFrame then 
        print("Erro: ScrollFrame não encontrado")
        return 
    end
    
    -- Criar frame da mensagem
    local messageFrame = Instance.new("Frame")
    messageFrame.Name = "Message_" .. #PrivateMessageUI.messages + 1
    messageFrame.Size = UDim2.new(1, -5, 0, 25)
    messageFrame.BackgroundColor3 = PrivateMessageUI.getColorForType(messageData.type)
    messageFrame.BorderSizePixel = 0
    messageFrame.Parent = scrollFrame

    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = messageFrame

    -- Texto da mensagem
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -10, 1, 0)
    messageLabel.Position = UDim2.new(0, 5, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = messageData.message
    messageLabel.TextColor3 = Color3.new(1, 1, 1)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.TextWrapped = true
    messageLabel.Parent = messageFrame

    -- Adicionar à lista de mensagens
    table.insert(PrivateMessageUI.messages, messageFrame)
    
    -- Remover mensagens antigas se necessário
    if #PrivateMessageUI.messages > PrivateMessageUI.maxMessages then
        local oldMessage = table.remove(PrivateMessageUI.messages, 1)
        if oldMessage then
            oldMessage:Destroy()
        end
    end

    -- Atualizar tamanho do conteúdo
    local listLayout = scrollFrame:FindFirstChild("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        
        -- Scroll para baixo
        scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
    end

    -- Auto-remover após 8 segundos
    game:GetService("Debris"):AddItem(messageFrame, 8)
end

-- Função para obter cor baseada no tipo de mensagem
function PrivateMessageUI.getColorForType(messageType)
    if messageType == "error" then
        return Color3.new(0.8, 0.2, 0.2) -- Vermelho
    elseif messageType == "success" then
        return Color3.new(0.2, 0.8, 0.2) -- Verde
    elseif messageType == "warning" then
        return Color3.new(0.8, 0.6, 0.2) -- Amarelo
    elseif messageType == "admin" then
        return Color3.new(0.6, 0.2, 0.8) -- Roxo
    else
        return Color3.new(0.2, 0.4, 0.8) -- Azul (info)
    end
end

-- Função para processar mensagem recebida
function PrivateMessageUI.processMessage(messageData)
    print("Processando mensagem:", messageData.message)
    PrivateMessageUI.createMessage(messageData)
end

-- Função para inicializar
function PrivateMessageUI.initialize()
    -- Criar interface
    PrivateMessageUI.createMessageGui()
    
    -- Conectar ao RemoteEvent
    local privateMessageEvent = ReplicatedStorage:WaitForChild("PrivateMessage")
    privateMessageEvent.OnClientEvent:Connect(PrivateMessageUI.processMessage)
    
    print("Interface de mensagens privadas inicializada!")
end

return PrivateMessageUI
