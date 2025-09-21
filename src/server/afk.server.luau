-- Sistema AFK - Server (Versão otimizada)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local afkParts = {}
local updateConnections = {}

-- Criar RemoteEvent no servidor
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "AFKDetection"
remoteEvent.Parent = ReplicatedStorage

print("📡 RemoteEvent criado no servidor")

-- Função para criar part AFK
local function createAFKPart(player)
    print("🔧 Tentando criar part AFK para " .. player.Name)
    
    local character = player.Character
    if not character then 
        print("❌ Character não encontrado para " .. player.Name)
        return 
    end
    
    if afkParts[player] then 
        print("⚠️ Part AFK já existe para " .. player.Name)
        return 
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then 
        print("❌ Humanoid não encontrado para " .. player.Name)
        return 
    end
    
    local rootPart = humanoid.RootPart
    if not rootPart then 
        print("❌ RootPart não encontrado para " .. player.Name)
        return 
    end
    
    local originalPart = workspace:FindFirstChild("zzz")
    if not originalPart then 
        print("❌ Part zzz original não encontrada no workspace")
        return 
    end
    
    print("✅ Criando part AFK para " .. player.Name)
    
    local zzzPart = originalPart:Clone()
    zzzPart.Name = "zzz_" .. player.Name
    zzzPart.Transparency = 1
    zzzPart.CanCollide = false
    zzzPart.Anchored = true -- Ancorada para melhor performance
    zzzPart.CFrame = rootPart.CFrame * CFrame.new(0, 4, 0)
    zzzPart.Parent = workspace
    
    -- Garantir que o ParticleEmitter funcione corretamente
    local particleEmitter = zzzPart:FindFirstChildOfClass("ParticleEmitter")
    if particleEmitter then
        particleEmitter.Enabled = true
        print("✅ ParticleEmitter ativado para " .. player.Name)
    end
    
    -- Loop para atualizar posição (mais eficiente que WeldConstraint)
    local connection = RunService.Heartbeat:Connect(function()
        if zzzPart and zzzPart.Parent and rootPart and rootPart.Parent then
            zzzPart.CFrame = rootPart.CFrame * CFrame.new(0, 4, 0)
        else
            connection:Disconnect()
            updateConnections[player] = nil
        end
    end)
    
    updateConnections[player] = connection
    afkParts[player] = zzzPart
    print("🔴 " .. player.Name .. " está AFK")
end

-- Função para remover part AFK
local function removeAFKPart(player)
    local part = afkParts[player]
    local connection = updateConnections[player]
    
    if connection then
        connection:Disconnect()
        updateConnections[player] = nil
    end
    
    if part then
        part:Destroy()
        afkParts[player] = nil
        print("✅ " .. player.Name .. " voltou")
    else
        print("⚠️ Nenhuma part AFK encontrada para " .. player.Name)
    end
end

-- Conectar eventos
remoteEvent.OnServerEvent:Connect(function(player, action)
    print("📨 Recebido: " .. action .. " de " .. player.Name)
    if action == "AFK_START" then
        createAFKPart(player)
    elseif action == "AFK_END" then
        removeAFKPart(player)
    end
end)

-- Limpar ao sair
Players.PlayerRemoving:Connect(removeAFKPart)

print("🚀 AFK Server iniciado")
