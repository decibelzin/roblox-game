local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ANIMATIONS = require(ReplicatedStorage.Shared.animations)

local player = Players.LocalPlayer

-- RemoteEvents para comunicação com o servidor
local getFavoritesFunction = ReplicatedStorage:WaitForChild("GetFavoriteEmotes", 5)
local updateFavoriteEvent = ReplicatedStorage:WaitForChild("UpdateFavoriteEmote", 5)

-- Sons de feedback
local clickSound = game.StarterGui:WaitForChild("clicksound")
local hoverSound = game.StarterGui:WaitForChild("hoversound")

-- Estado global
local currentAnimationTrack = nil
local currentPlayingEmote = nil
local allEmotes = {}
local favoritedEmotes = {}
local isProcessingAnimation = false

-- Funções de som
local function playClickSound()
    clickSound:Play()
end

local function playHoverSound()
    hoverSound:Play()
end

-- Para animação atual
local function stopCurrentAnimation()
    if currentAnimationTrack then
        currentAnimationTrack:Stop()
        currentAnimationTrack:Destroy()
        currentAnimationTrack = nil
        currentPlayingEmote = nil
    end
end

-- Carrega favoritos do servidor
local function loadFavorites()
    if not getFavoritesFunction then
        favoritedEmotes = {}
        return
    end
    
    local success, serverFavorites = pcall(function()
        return getFavoritesFunction:InvokeServer()
    end)
    
    favoritedEmotes = (success and serverFavorites and type(serverFavorites) == "table") and serverFavorites or {}
end

-- Filtra emotes baseado na busca
local function filterEmotes(searchText)
    searchText = searchText:lower()
    
    for _, emoteData in pairs(allEmotes) do
        local emoteName = emoteData.name:lower()
        emoteData.gui.Visible = searchText == "" or emoteName:find(searchText, 1, true)
    end
end

-- Atualiza estado do favorito no servidor
local function updateFavoriteOnServer(emoteName, isFavorited)
    if not updateFavoriteEvent then return end
    
    pcall(function()
        updateFavoriteEvent:FireServer(emoteName, isFavorited)
    end)
end

-- Reordena os emotes na lista (favoritos primeiro)
local function reorderEmotes()
    -- Ordena o array de emotes
    table.sort(allEmotes, function(a, b)
        local aFavorited = favoritedEmotes[a.name] or false
        local bFavorited = favoritedEmotes[b.name] or false
        
        -- Se um é favorito e outro não, favorito vem primeiro
        if aFavorited and not bFavorited then
            return true
        elseif not aFavorited and bFavorited then
            return false
        else
            -- Se ambos são favoritos ou ambos não são, ordena alfabeticamente
            return a.name < b.name
        end
    end)
    
    -- Reposiciona os elementos na GUI
    for i, emoteData in ipairs(allEmotes) do
        emoteData.gui.LayoutOrder = i
    end
end

-- Configura botões de favorito
local function setupFavoriteButtons(emoteGui, emoteName)
    local unfavorited = emoteGui:FindFirstChild("Unfavorited")
    local favorited = emoteGui:FindFirstChild("Favorited")
    
    if not unfavorited or not favorited then return end
    
    -- Estado inicial
    local isFavorited = favoritedEmotes[emoteName] or false
    unfavorited.Visible = not isFavorited
    favorited.Visible = isFavorited
    
    -- Clique no botão "Unfavorited" → Favoritar
    unfavorited.MouseButton1Click:Connect(function()
        playClickSound()
        unfavorited.Visible = false
        favorited.Visible = true
        favoritedEmotes[emoteName] = true
        updateFavoriteOnServer(emoteName, true)
        reorderEmotes() -- Reordena a lista
    end)
    
    -- Clique no botão "Favorited" → Desfavoritar
    favorited.MouseButton1Click:Connect(function()
        playClickSound()
        unfavorited.Visible = true
        favorited.Visible = false
        favoritedEmotes[emoteName] = nil
        updateFavoriteOnServer(emoteName, false)
        reorderEmotes() -- Reordena a lista
    end)
    
    -- Hover
    unfavorited.MouseEnter:Connect(playHoverSound)
    favorited.MouseEnter:Connect(playHoverSound)
end

-- Configura botão de play
local function setupPlayButton(emoteGui, emoteName, animationId)
    local playButton = emoteGui.Play
    
    playButton.MouseButton1Click:Connect(function()
        playClickSound()
        
        if isProcessingAnimation then return end
        isProcessingAnimation = true
        
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        
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
        
        -- Para animação atual e toca nova
        stopCurrentAnimation()
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            isProcessingAnimation = false
            return
        end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. animationId
        
        currentAnimationTrack = animator:LoadAnimation(animation)
        
        if currentAnimationTrack then
            local animationTrack = currentAnimationTrack
            
            task.wait()
            
            if currentAnimationTrack == animationTrack then
                animationTrack:Play()
                currentPlayingEmote = emoteName
                
                -- Cleanup automático
                local function cleanup()
                    if currentAnimationTrack == animationTrack then
                        currentAnimationTrack:Destroy()
                        currentAnimationTrack = nil
                        currentPlayingEmote = nil
                    end
                end
                
                animationTrack.Ended:Connect(cleanup)
                animationTrack.Stopped:Connect(cleanup)
            end
        end
        
        isProcessingAnimation = false
    end)
    
    playButton.MouseEnter:Connect(playHoverSound)
end

-- Adiciona um emote
local function addEmote(emoteName, animationId)
    local emoteTemplate = game.Players.LocalPlayer.PlayerGui.EMOTE.BlackHolder.Background.EmotesHolder.ScrollingFrame.EmoteTemplate
    local newEmote = emoteTemplate:Clone()
    
    newEmote.Label.Text = emoteName
    newEmote.Parent = emoteTemplate.Parent
    newEmote.Visible = true
    
    setupFavoriteButtons(newEmote, emoteName)
    setupPlayButton(newEmote, emoteName, animationId)
    
    -- Registra para busca
    table.insert(allEmotes, {
        name = emoteName,
        gui = newEmote
    })
end

-- Configura o menu principal
local function setupEmoteMenu()
    stopCurrentAnimation()
    isProcessingAnimation = false
    
    loadFavorites()
    
    local playerGui = player:WaitForChild("PlayerGui")
    local emoteButton = playerGui.MISC.BlackHolder.EmoteButton
    local emoteMenu = playerGui.EMOTE.BlackHolder
    local background = emoteMenu.Background
    local closeButton = background.Close
    local searchBox = background.Search.SeachBox

    
    -- Limpa emotes anteriores
    for _, emoteData in pairs(allEmotes) do
        if emoteData.gui and emoteData.gui.Parent then
            emoteData.gui:Destroy()
        end
    end
    allEmotes = {}
    
    -- Controles do menu
    local function toggleMenu()
        emoteMenu.Visible = not emoteMenu.Visible
    end
    
    emoteButton.MouseButton1Click:Connect(function()
        playClickSound()
        toggleMenu()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        playClickSound()
        emoteMenu.Visible = false
    end)
    
    -- Sistema de busca
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterEmotes(searchBox.Text)
    end)
    
    -- Hover nos botões
    emoteButton.MouseEnter:Connect(playHoverSound)
    closeButton.MouseEnter:Connect(playHoverSound)
    
    -- Adiciona emotes do sistema (favoritos primeiro)
    local sortedAnimations = {}
    
    -- Converte para array ordenável
    for _, animation in pairs(ANIMATIONS.list) do
        table.insert(sortedAnimations, animation)
    end
    
    -- Ordena: favoritos primeiro, depois alfabética
    table.sort(sortedAnimations, function(a, b)
        local aFavorited = favoritedEmotes[a.name] or false
        local bFavorited = favoritedEmotes[b.name] or false
        
        -- Se um é favorito e outro não, favorito vem primeiro
        if aFavorited and not bFavorited then
            return true
        elseif not aFavorited and bFavorited then
            return false
        else
            -- Se ambos são favoritos ou ambos não são, ordena alfabeticamente
            return a.name < b.name
        end
    end)
    
    -- Adiciona emotes na ordem correta
    for _, animation in ipairs(sortedAnimations) do
        addEmote(animation.name, animation.id)
    end
end

-- Inicialização
player.CharacterAdded:Connect(setupEmoteMenu)
if player.Character then
    setupEmoteMenu()
end