local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Sons de feedback
local clickSound = game.StarterGui:WaitForChild("clicksound")
local hoverSound = game.StarterGui:WaitForChild("hoversound")

-- Funções de som
local function playClickSound()
    clickSound:Play()
end

local function playHoverSound()
    hoverSound:Play()
end

-- Importar lista de códigos válidos
local redeemableCodes = require(ReplicatedStorage.Shared["redeemable-codes"])

-- Aguardar ou criar o RemoteEvent para códigos
local codeRedeemEvent = ReplicatedStorage:FindFirstChild("CodeRedeemEvent")
if not codeRedeemEvent then
    -- Se não existir, aguardar que o servidor crie
    codeRedeemEvent = ReplicatedStorage:WaitForChild("CodeRedeemEvent")
end

-- Conectar para receber feedback do servidor sobre códigos
codeRedeemEvent.OnClientEvent:Connect(function(success, message, code)
    if success then 
    else
        if message:find("já resgatou") then 
        else 
        end
    end
end)

-- Função para configurar o botão de códigos
local function setupCodeRedeemer()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Verificar se as interfaces necessárias existem
    local miscGui = playerGui:WaitForChild("MISC", 10)
    if not miscGui then
        warn("Interface MISC não encontrada!")
        return
    end
    
    local codeButton = miscGui.BlackHolder:FindFirstChild("CodeButton")
    if not codeButton then
        warn("CodeButton não encontrado em MISC.BlackHolder!")
        return
    end
    
    local codesGui = playerGui:WaitForChild("CODES", 10)
    if not codesGui then
        warn("Interface CODES não encontrada!")
        return
    end
    
    local codesMenu = codesGui:FindFirstChild("BlackHolder")
    if not codesMenu then
        warn("BlackHolder não encontrado em CODES!")
        return
    end
    
    -- Buscar CodeBox recursivamente na interface
    local function findCodeBox(parent)
        -- Primeiro, procurar diretamente no parent
        local directBox = parent:FindFirstChild("CodeBox")
        if directBox and directBox:IsA("TextBox") then
            return directBox
        end
        
        -- Se não encontrou, procurar em todos os filhos
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                local foundBox = findCodeBox(child)
                if foundBox then
                    return foundBox
                end
            end
        end
        
        return nil
    end
    
    local codeBox = findCodeBox(codesMenu)
    if not codeBox then
        warn("CodeBox não encontrado em CODES.BlackHolder! Elementos disponíveis:")
        local function printChildren(parent, indent)
            for _, child in ipairs(parent:GetChildren()) do 
                if child:IsA("GuiObject") and #child:GetChildren() > 0 then
                    printChildren(child, indent .. "  ")
                end
            end
        end
        printChildren(codesMenu, "  ")
        return
    end
    
    -- Buscar botão de resgate recursivamente
    local function findRedeemButton(parent)
        -- Procurar por nomes possíveis de botão
        local possibleNames = {"PurchaseButton", "RedeemButton", "SubmitButton", "Button"}
        
        for _, name in ipairs(possibleNames) do
            local button = parent:FindFirstChild(name)
            if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
                return button
            end
        end
        
        -- Se não encontrou, procurar em todos os filhos
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                local foundButton = findRedeemButton(child)
                if foundButton then
                    return foundButton
                end
            end
        end
        
        return nil
    end
    
    local redeemButton = findRedeemButton(codesMenu)
    if not redeemButton then
        warn("Botão de resgate não encontrado em CODES.BlackHolder!")
        return
    end
    
    -- Buscar botão Close (pode estar dentro de Background)
    local closeButton = codesMenu:FindFirstChild("Close")
    
    -- Se não encontrou diretamente, procurar dentro de Background
    if not closeButton then
        local background = codesMenu:FindFirstChild("Background")
        if background then
            closeButton = background:FindFirstChild("Close")
        end
    end
    
    if closeButton and (closeButton:IsA("TextButton") or closeButton:IsA("ImageButton")) then
     else
     end 
    -- Configurar clique no botão de códigos (abrir/fechar menu)
    codeButton.MouseButton1Click:Connect(function()
        playClickSound()
        codesMenu.Visible = not codesMenu.Visible
    end)
    
    -- Configurar clique no botão Close (fechar menu)
    if closeButton then
        closeButton.MouseButton1Click:Connect(function()
            playClickSound()
            codesMenu.Visible = false
        end)
    end
    
    -- Configurar clique no botão de resgate
    redeemButton.MouseButton1Click:Connect(function()
        playClickSound()
        local codeText = codeBox.Text
        
        -- Validar se o input não está vazio
        if not codeText or codeText == "" or type(codeText) ~= "string" then
            -- Mostrar erro visual ou som (opcional)
            warn("Código inválido: campo vazio ou inválido")
            return
        end
        
        -- Limpar espaços em branco
        codeText = string.gsub(codeText, "^%s*(.-)%s*$", "%1")
        
        -- Verificar se o código existe na lista de códigos válidos
        if redeemableCodes[codeText] then
            -- Código válido, enviar para o servidor 
            codeRedeemEvent:FireServer(codeText)
            
            -- Limpar o campo de texto após envio
            codeBox.Text = ""
        else
            -- Código inválido - enviar mensagem no chat usando TextChatService
            local textChannel = TextChatService.TextChannels.RBXGeneral
            textChannel:DisplaySystemMessage("❌ Código inválido!")
             
        end
    end)
    
    -- Hover nos botões
    codeButton.MouseEnter:Connect(playHoverSound)
    redeemButton.MouseEnter:Connect(playHoverSound)
    if closeButton then
        closeButton.MouseEnter:Connect(playHoverSound)
    end
end

-- Inicialização
player.CharacterAdded:Connect(setupCodeRedeemer)
if player.Character then
    setupCodeRedeemer()
end
