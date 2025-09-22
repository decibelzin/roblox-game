-- Sistema de Player Tags (Cliente)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Aguardar o evento ser criado
local groupSyncEvent = ReplicatedStorage:WaitForChild("GroupSyncEvent")

-- Cores para cada grupo
local groupColors = {
    owner = Color3.fromRGB(255, 0, 0),      -- Vermelho
    admin = Color3.fromRGB(255, 100, 0),    -- Laranja
    moderator = Color3.fromRGB(0, 255, 0),  -- Verde
    ["vip-gold"] = Color3.fromRGB(255, 215, 0) -- Dourado
}

-- Função para atualizar a tag de um jogador
local function updatePlayerTag(playerName, highestGroup, allGroups)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Remover tag anterior se existir
    local existingTag = character:FindFirstChild("GroupTag")
    if existingTag then
        existingTag:Destroy()
    end
    
    -- Criar nova tag se tiver grupo
    if highestGroup then
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "GroupTag"
        billboardGui.Size = UDim2.new(0, 100, 0, 30)
        billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        billboardGui.Parent = character
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = billboardGui
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = string.upper(highestGroup)
        label.TextColor3 = groupColors[highestGroup] or Color3.fromRGB(255, 255, 255)
        label.TextSize = 16
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = frame
        
        print("🏷️ Tag atualizada para " .. playerName .. ": " .. highestGroup)
    else
        print("🏷️ Tag removida para " .. playerName)
    end
end

-- Escutar eventos de sincronização de grupos
groupSyncEvent.OnClientEvent:Connect(function(playerName, highestGroup, allGroups)
    updatePlayerTag(playerName, highestGroup, allGroups)
end)

-- Atualizar tags quando personagens spawnarem
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Aguardar um pouco para garantir que o servidor já processou
        -- A sincronização será feita pelo servidor via GroupSyncEvent
    end)
end)

print("🏷️ Sistema de Player Tags (Cliente) iniciado!")
