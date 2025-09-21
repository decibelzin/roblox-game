local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Variáveis para controlar o estado
local isWindowFocused = true
local lastFocusTime = 0
local altTabThreshold = 0.1 -- Tempo mínimo para considerar como Alt + Tab

-- Função chamada quando a janela perde o foco
local function onWindowFocusLost()
    isWindowFocused = false
    lastFocusTime = tick()
    print("⚠️ Jogador perdeu o foco da janela (possível Alt + Tab)")
    
    -- Aqui você pode adicionar lógica adicional quando detectar Alt + Tab
    -- Por exemplo: pausar o jogo, mostrar aviso, etc.
end

-- Função chamada quando a janela ganha o foco
local function onWindowFocusGained()
    local currentTime = tick()
    local timeAway = currentTime - lastFocusTime
    
    if not isWindowFocused and timeAway > altTabThreshold then
        print("✅ Jogador voltou para o jogo após", string.format("%.2f", timeAway), "segundos")
        print("🎮 Alt + Tab detectado!")
        
        -- Aqui você pode adicionar lógica quando o jogador volta do Alt + Tab
        -- Por exemplo: retomar o jogo, mostrar notificação, etc.
    end
    
    isWindowFocused = true
end

-- Função para detectar Alt + Tab através de input (método alternativo)
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    -- Detecta se Alt está pressionado
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        -- Aguarda um pouco para ver se Tab também é pressionado
        task.wait(0.1)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Tab) then
            print("🎯 Alt + Tab detectado via input!")
            -- Lógica adicional aqui
        end
    end
end

-- Conectar os eventos
UserInputService.WindowFocused:Connect(onWindowFocusGained)
UserInputService.WindowFocusReleased:Connect(onWindowFocusLost)
UserInputService.InputBegan:Connect(onInputBegan)

-- Função para verificar se a janela está focada
local function isWindowCurrentlyFocused()
    return isWindowFocused
end

-- Função para obter o tempo desde a última perda de foco
local function getTimeSinceLastFocusLoss()
    if isWindowFocused then
        return 0
    else
        return tick() - lastFocusTime
    end
end

-- Exportar funções para uso em outros scripts
_G.AltTabDetector = {
    isWindowFocused = isWindowCurrentlyFocused,
    getTimeSinceFocusLoss = getTimeSinceLastFocusLoss
}

print("🔍 Sistema de detecção de Alt + Tab inicializado!")
