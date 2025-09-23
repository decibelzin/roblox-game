-- Sistema de Player Tags (Cliente)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Aguardar o evento ser criado
local groupUpdateEvent = ReplicatedStorage:WaitForChild("framework:update.player.groups")

-- Configuração de grupos
local GROUPS_CONFIG = require(ReplicatedStorage.Shared.groups)

-- Função para obter o grupo mais alto baseado na prioridade
local function getHighestGroup(playerGroups: {[string]: boolean}): string?
    if not playerGroups or type(playerGroups) ~= "table" then
        return nil
    end
    
    local highestGroup = nil
    local highestPriority = 0
    
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup then
            local groupData = GROUPS_CONFIG[groupName]
            if groupData and groupData.priority and groupData.priority > highestPriority then
                highestPriority = groupData.priority
                highestGroup = groupName
            end
        end
    end
    
    return highestGroup
end

-- Função para atualizar a tag de um jogador
local function updatePlayerTag(playerName, playerGroups)
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
    
    -- Obter o grupo mais alto
    local highestGroup = getHighestGroup(playerGroups)
    
    -- Criar nova tag se tiver grupo
    if highestGroup then
        local groupData = GROUPS_CONFIG[highestGroup]
        local groupColor = groupData and groupData.color or Color3.fromRGB(255, 255, 255)
        local groupName = groupData and groupData.name or string.upper(highestGroup)
        
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
        label.Text = groupName
        label.TextColor3 = groupColor
        label.TextSize = 16
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = frame
    end
end

-- Escutar eventos de atualização de grupos
groupUpdateEvent.OnClientEvent:Connect(function(playerGroups)
    print('evento de atualização de grupos recebido para', player.Name)
    updatePlayerTag(player.Name, playerGroups)
end)
