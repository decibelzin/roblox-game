-- Utilitários compartilhados
local Utils = {}

-- Função para criar cantos arredondados
function Utils.createRoundedCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius
    return corner
end

-- Função para criar um TextLabel com configurações padrão
function Utils.createTextLabel(config)
    local label = Instance.new("TextLabel")
    label.Name = config.Name or "TextLabel"
    label.Size = config.Size or UDim2.new(0, 100, 0, 50)
    label.Position = config.Position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = config.BackgroundTransparency or 1
    label.Text = config.Text or ""
    label.TextColor3 = config.TextColor3 or Color3.new(1, 1, 1)
    label.TextScaled = config.TextScaled or false
    label.Font = config.Font or Enum.Font.Gotham
    label.TextStrokeTransparency = config.TextStrokeTransparency or 1
    label.TextStrokeColor3 = config.TextStrokeColor3 or Color3.new(0, 0, 0)
    label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Center
    label.TextYAlignment = config.TextYAlignment or Enum.TextYAlignment.Center
    
    if config.Parent then
        label.Parent = config.Parent
    end
    
    return label
end

-- Função para criar um TextButton com configurações padrão
function Utils.createTextButton(config)
    local button = Instance.new("TextButton")
    button.Name = config.Name or "TextButton"
    button.Size = config.Size or UDim2.new(0, 100, 0, 50)
    button.Position = config.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.BackgroundColor3 or Color3.new(0.5, 0.5, 0.5)
    button.Text = config.Text or "Button"
    button.TextColor3 = config.TextColor3 or Color3.new(1, 1, 1)
    button.TextScaled = config.TextScaled or false
    button.Font = config.Font or Enum.Font.Gotham
    
    if config.Parent then
        button.Parent = config.Parent
    end
    
    return button
end

return Utils
