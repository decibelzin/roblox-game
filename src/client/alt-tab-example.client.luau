-- Exemplo de uso do sistema de detecção de Alt + Tab
-- Este script demonstra como usar o AltTabDetector em outros scripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Aguardar o sistema de detecção ser carregado
local AltTabDetector = _G.AltTabDetector
if not AltTabDetector then
    warn("AltTabDetector não foi encontrado! Certifique-se de que alt-tab-detector.client.luau está carregado.")
    return
end

-- Exemplo 1: Verificar se a janela está focada
local function checkWindowFocus()
    if AltTabDetector.isWindowFocused() then
        print("🟢 Janela do jogo está focada")
    else
        print("🔴 Janela do jogo NÃO está focada")
        local timeAway = AltTabDetector.getTimeSinceFocusLoss()
        print("⏱️ Tempo fora do foco:", string.format("%.2f", timeAway), "segundos")
    end
end

-- Exemplo 2: Sistema de pausa automática quando Alt + Tab
local isGamePaused = false
local originalWalkSpeed = 16

local function pauseGame()
    if isGamePaused then return end
    
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        originalWalkSpeed = character.Humanoid.WalkSpeed
        character.Humanoid.WalkSpeed = 0
        isGamePaused = true
        print("⏸️ Jogo pausado devido ao Alt + Tab")
    end
end

local function resumeGame()
    if not isGamePaused then return end
    
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = originalWalkSpeed
        isGamePaused = false
        print("▶️ Jogo retomado")
    end
end

-- Exemplo 3: Sistema de aviso quando Alt + Tab
local function showAltTabWarning()
    print("🚨 ATENÇÃO: Você fez Alt + Tab!")
    print("💡 Dica: Evite fazer Alt + Tab durante o jogo para melhor experiência")
end

-- Conectar eventos personalizados
local function onAltTabDetected()
    showAltTabWarning()
    pauseGame()
end

local function onReturnToGame()
    resumeGame()
end

-- Monitorar mudanças de foco
local lastFocusState = true
local function monitorFocus()
    local currentFocus = AltTabDetector.isWindowFocused()
    
    if currentFocus ~= lastFocusState then
        if currentFocus then
            onReturnToGame()
        else
            onAltTabDetected()
        end
        lastFocusState = currentFocus
    end
end

-- Loop de monitoramento
spawn(function()
    while true do
        monitorFocus()
        wait(0.1) -- Verificar a cada 0.1 segundos
    end
end)

-- Comando para testar manualmente
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        checkWindowFocus()
    elseif input.KeyCode == Enum.KeyCode.F10 then
        if isGamePaused then
            resumeGame()
        else
            pauseGame()
        end
    end
end)

print("📋 Sistema de exemplo carregado!")
print("🎮 Pressione F9 para verificar o foco da janela")
print("🎮 Pressione F10 para pausar/retomar o jogo manualmente")
