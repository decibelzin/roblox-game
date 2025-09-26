local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Som de clique para feedback
local clickSound = game.StarterGui:WaitForChild("clicksound")
local hoverSound = game.StarterGui:WaitForChild("hoversound")

-- Função para tocar som de clique
local function playClickSound()
    clickSound:Play()
end

-- Função para tocar som de hover
local function playHoverSound()
    hoverSound:Play()
end

-- Controle global de animações
local currentAnimationTrack = nil
local currentPlayingEmote = nil
local allEmotes = {}
local isProcessingAnimation = false

-- Para animação atual
local function stopCurrentAnimation()
    if currentAnimationTrack then
        currentAnimationTrack:Stop()
        currentAnimationTrack:Destroy()
        currentAnimationTrack = nil
        currentPlayingEmote = nil
    end
end

-- Filtra emotes baseado na busca
local function filterEmotes(searchText)
    searchText = searchText:lower()
    
    for _, emoteData in pairs(allEmotes) do
        local emoteName = emoteData.name:lower()
        local emoteGui = emoteData.gui
        
        emoteGui.Visible = searchText == "" or emoteName:find(searchText, 1, true)
    end
end

-- Função principal que configura tudo quando o personagem spawna
local function setupEmoteMenu()
    -- Reset das variáveis de controle
    stopCurrentAnimation()
    isProcessingAnimation = false
    
    -- Aguarda o PlayerGui estar pronto
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Referencias da GUI
    local emoteButton = playerGui:WaitForChild("MISC"):WaitForChild("BlackHolder"):WaitForChild("EmoteButton")
    local emoteMenu = playerGui:WaitForChild("EMOTE"):WaitForChild("BlackHolder")
    local background = emoteMenu:WaitForChild("Background")
    local closeButton = background:WaitForChild("Close")
    local searchBox = background:WaitForChild("Search"):WaitForChild("SeachBox")
    local scrollingFrame = background:WaitForChild("EmotesHolder"):WaitForChild("ScrollingFrame")
    local emoteTemplate = scrollingFrame:WaitForChild("EmoteTemplate")
    
    -- Esconde o template original
    emoteTemplate.Visible = false
    
    -- Limpa emotes anteriores se existirem
    for _, emoteData in pairs(allEmotes) do
        if emoteData.gui and emoteData.gui.Parent then
            emoteData.gui:Destroy()
        end
    end
    allEmotes = {}
    
    -- Função para abrir o menu
    local function openMenu()
        emoteMenu.Visible = true
    end
    
    -- Função para fechar o menu
    local function closeMenu()
        emoteMenu.Visible = false
    end
    
    -- Adiciona um novo emote
    local function addEmote(emoteName, animationId)
        local newEmote = emoteTemplate:Clone()
        newEmote.Label.Text = emoteName
        
        -- Botão Play/Stop
        newEmote.Play.MouseButton1Click:Connect(function()
            playClickSound() -- Som de feedback
            
            -- Previne cliques múltiplos muito rápidos
            if isProcessingAnimation then 
                return 
            end
            isProcessingAnimation = true
            
            local character = player.Character
            if not character then 
                isProcessingAnimation = false
                return 
            end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then 
                isProcessingAnimation = false
                return 
            end
            
            -- Toggle: se já está tocando este emote, para
            if currentPlayingEmote == emoteName then
                stopCurrentAnimation()
                isProcessingAnimation = false
                return
            end
            
            -- Para qualquer animação ativa e toca a nova
            stopCurrentAnimation()
            
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://" .. animationId
                
                currentAnimationTrack = animator:LoadAnimation(animation)
                
                -- Verifica se a animação foi carregada com sucesso
                if currentAnimationTrack then
                    -- Salva a referência local para evitar condição de corrida
                    local animationTrack = currentAnimationTrack
                    
                    -- Aguarda um frame para garantir que a animação anterior parou
                    task.wait()
                    
                    -- Verifica se ainda é a mesma animação após o wait
                    if currentAnimationTrack == animationTrack and animationTrack then
                        animationTrack:Play()
                        currentPlayingEmote = emoteName
                        
                        -- Cleanup quando terminar
                        animationTrack.Ended:Connect(function()
                            if currentAnimationTrack == animationTrack then
                                currentAnimationTrack:Destroy()
                                currentAnimationTrack = nil
                                currentPlayingEmote = nil
                            end
                        end)
                        
                        -- Cleanup quando parar manualmente
                        animationTrack.Stopped:Connect(function()
                            if currentAnimationTrack == animationTrack then
                                currentAnimationTrack:Destroy()
                                currentAnimationTrack = nil
                                currentPlayingEmote = nil
                            end
                        end)
                    end
                else
                    -- Se falhou em carregar a animação, mostra aviso
                    warn("Falha ao carregar animação:", emoteName, "ID:", animationId)
                    currentAnimationTrack = nil
                    currentPlayingEmote = nil
                end
            end
            
            isProcessingAnimation = false
        end)
        
        -- Hover do botão Play
        newEmote.Play.MouseEnter:Connect(function()
            playHoverSound()
        end)
        
        -- Botão Favorite (placeholder)
        newEmote.Favorite.MouseButton1Click:Connect(function()
            playClickSound() -- Som de feedback
            print("Favoritou:", emoteName)
        end)
        
        -- Hover do botão Favorite
        newEmote.Favorite.MouseEnter:Connect(function()
            playHoverSound()
        end)
        
        newEmote.Parent = scrollingFrame
        newEmote.Visible = true
        
        -- Registra para busca
        table.insert(allEmotes, {
            name = emoteName,
            gui = newEmote
        })
    end
    
    -- Sistema de busca
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterEmotes(searchBox.Text)
    end)
    
    -- Controles do menu
    emoteButton.MouseButton1Click:Connect(function()
        playClickSound() -- Som de feedback
        
        if emoteMenu.Visible then
            closeMenu()
        else
            openMenu()
        end
    end)
    
    -- Hover do botão emote
    emoteButton.MouseEnter:Connect(function()
        playHoverSound()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        playClickSound() -- Som de feedback
        closeMenu()
    end)
    
    -- Hover do botão close
    closeButton.MouseEnter:Connect(function()
        playHoverSound()
    end)
    
    -- Adiciona emotes
    addEmote("Wave", "507770239")
    addEmote("Worn", "507770239")
    addEmote("Dance", "507777268")
    addEmote("Cheer", "507770677")
end

-- Configura o menu quando o jogador spawna pela primeira vez
player.CharacterAdded:Connect(setupEmoteMenu)

-- Se o jogador já tem um personagem, configura imediatamente
if player.Character then
    setupEmoteMenu()
end