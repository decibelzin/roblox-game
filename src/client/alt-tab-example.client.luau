-- Sistema de detecção de Alt + Tab com decal visual
-- Mostra um decal acima da cabeça do player quando ele der alt+tab

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Aguardar o sistema de detecção ser carregado
local AltTabDetector = _G.AltTabDetector
if not AltTabDetector then
    warn("AltTabDetector não foi encontrado! Certifique-se de que alt-tab-detector.client.luau está carregado.")
    return
end

-- Variáveis para o sistema de decal
local altTabDecal = nil
local decalPart = nil
local isDecalVisible = false

-- Função para buscar o decal na parte zzz do workspace
local function findDecalInWorkspace()
    local workspace = game.Workspace
    local zzzPart = workspace:FindFirstChild("zzz")
    
    if not zzzPart then
        warn("Parte 'zzz' não encontrada no workspace!")
        return nil
    end
    
    -- Procurar por um Decal na parte zzz
    local decal = zzzPart:FindFirstChildOfClass("Decal")
    if not decal then
        warn("Nenhum Decal encontrado na parte 'zzz'!")
        return nil
    end
    
    print("✅ Decal encontrado:", decal.Name)
    return decal
end

-- Função para criar a parte do decal acima da cabeça
local function createDecalPart()
    local character = player.Character
    if not character then return nil end
    
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    -- Criar uma parte para o decal
    local part = Instance.new("Part")
    part.Name = "AltTabDecal"
    part.Size = Vector3.new(4, 4, 0.1)
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Bright red")
    part.CanCollide = false
    part.Anchored = true
    part.Transparency = 0.3
    
    -- Posicionar acima da cabeça
    part.CFrame = head.CFrame * CFrame.new(0, 5, 0)
    
    -- Adicionar o decal
    local decal = altTabDecal:Clone()
    decal.Parent = part
    
    -- Adicionar à workspace
    part.Parent = workspace
    
    return part
end

-- Função para mostrar o decal
local function showAltTabDecal()
    if isDecalVisible then return end
    
    local character = player.Character
    if not character then return end
    
    -- Buscar o decal se ainda não foi encontrado
    if not altTabDecal then
        altTabDecal = findDecalInWorkspace()
        if not altTabDecal then return end
    end
    
    -- Criar a parte do decal
    decalPart = createDecalPart()
    if not decalPart then return end
    
    isDecalVisible = true
    
    -- Efeito de fade in
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(decalPart, tweenInfo, {Transparency = 0.3})
    tween:Play()
    
    print("🔴 Decal de Alt+Tab mostrado!")
end

-- Função para esconder o decal
local function hideAltTabDecal()
    if not isDecalVisible or not decalPart then return end
    
    -- Efeito de fade out
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(decalPart, tweenInfo, {Transparency = 1})
    
    tween:Play()
    tween.Completed:Connect(function()
        if decalPart then
            decalPart:Destroy()
            decalPart = nil
        end
        isDecalVisible = false
    end)
    
    print("🟢 Decal de Alt+Tab escondido!")
end

-- Função para atualizar a posição do decal
local function updateDecalPosition()
    if not isDecalVisible or not decalPart then return end
    
    local character = player.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    -- Atualizar posição para ficar acima da cabeça
    decalPart.CFrame = head.CFrame * CFrame.new(0, 5, 0)
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
    showAltTabDecal() -- Mostrar decal quando alt+tab for detectado
end

local function onReturnToGame()
    resumeGame()
    hideAltTabDecal() -- Esconder decal quando voltar ao jogo
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
        updateDecalPosition() -- Atualizar posição do decal
        wait(0.1) -- Verificar a cada 0.1 segundos
    end
end)

-- Conectar evento de spawn do player
Players.PlayerAdded:Connect(function(plr)
    if plr == player then
        -- Quando o player spawnar, esconder qualquer decal visível
        hideAltTabDecal()
    end
end)

-- Conectar evento de respawn
player.CharacterAdded:Connect(function(character)
    -- Esconder decal quando o player respawnar
    hideAltTabDecal()
    
    -- Aguardar a cabeça ser criada
    character:WaitForChild("Head")
    
    -- Se o decal estava visível antes do respawn, mostrar novamente
    if isDecalVisible then
        task.wait(1) -- Aguardar um pouco para o character estar totalmente carregado
        showAltTabDecal()
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
    elseif input.KeyCode == Enum.KeyCode.F11 then
        -- Testar decal manualmente
        if isDecalVisible then
            hideAltTabDecal()
        else
            showAltTabDecal()
        end
    end
end)

print("📋 Sistema de Alt+Tab com decal visual carregado!")
print("🎮 Pressione F9 para verificar o foco da janela")
print("🎮 Pressione F10 para pausar/retomar o jogo manualmente")
print("🎮 Pressione F11 para testar o decal manualmente")
print("🔍 Procurando decal na parte 'zzz' do workspace...")
