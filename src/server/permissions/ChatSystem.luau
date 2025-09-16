-- Sistema de mensagens para chat do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatSystem = {}

-- Função para enviar mensagem para o chat do jogador
function ChatSystem.sendMessage(player, message)
    -- Usar o sistema de chat do Roblox
    local success, error = pcall(function()
        -- Criar uma mensagem de sistema
        local chatMessage = "[SISTEMA] " .. message
        
        -- Enviar para o chat usando TextChatService
        local TextChatService = game:GetService("TextChatService")
        if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
            TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(chatMessage, player)
        else
            -- Fallback: usar o método antigo
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = chatMessage,
                Color = Color3.new(1, 1, 1),
                Font = Enum.Font.Gotham,
                FontSize = Enum.FontSize.Size18
            })
        end
    end)
    
    if not success then
        -- Se falhar, usar print como fallback
        print("Erro ao enviar mensagem para o chat: " .. tostring(error))
        print("[SISTEMA] " .. message)
    end
end

-- Função para enviar mensagem para todos os administradores
function ChatSystem.sendToAdmins(message)
    for _, player in pairs(Players:GetPlayers()) do
        -- Verificar se é administrador (nível 4 ou 5)
        local PermissionManager = require(script.Parent.PermissionManager)
        local level = PermissionManager.getPlayerLevel(player)
        
        if level >= 4 then -- ADMIN ou OWNER
            ChatSystem.sendMessage(player, "🔧 [ADMIN] " .. message)
        end
    end
end

-- Função para inicializar o sistema
function ChatSystem.initialize()
    print("Sistema de chat inicializado!")
end

return ChatSystem
