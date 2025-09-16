-- Sistema de mensagens privadas para comandos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrivateMessageSystem = {}

-- Criar RemoteEvent para mensagens privadas
local privateMessageEvent = Instance.new("RemoteEvent")
privateMessageEvent.Name = "PrivateMessage"
privateMessageEvent.Parent = ReplicatedStorage

-- Função para enviar mensagem privada para um jogador
function PrivateMessageSystem.sendMessage(player, message, messageType)
    messageType = messageType or "info"
    
    -- Enviar via RemoteEvent
    privateMessageEvent:FireClient(player, {
        message = message,
        type = messageType,
        timestamp = os.time()
    })
    
    -- Também imprimir no console do servidor
    print("[" .. player.Name .. "] " .. message)
end

-- Função para enviar mensagem para o chat do jogador
function PrivateMessageSystem.sendChatMessage(player, message)
    -- Usar o sistema de chat do Roblox
    local success, error = pcall(function()
        -- Criar uma mensagem de chat personalizada
        local chatMessage = "[SISTEMA] " .. message
        
        -- Enviar para o chat do jogador
        game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage(chatMessage, player)
    end)
    
    if not success then
        -- Fallback: usar o método antigo se o novo falhar
        print("Erro ao enviar mensagem para o chat: " .. tostring(error))
        PrivateMessageSystem.sendMessage(player, message, "info")
    end
end

-- Função para enviar mensagem para todos os administradores
function PrivateMessageSystem.sendToAdmins(message, messageType)
    messageType = messageType or "admin"
    
    for _, player in pairs(Players:GetPlayers()) do
        -- Verificar se é administrador (nível 4 ou 5)
        local PermissionManager = require(script.Parent.PermissionManager)
        local level = PermissionManager.getPlayerLevel(player)
        
        if level >= 4 then -- ADMIN ou OWNER
            PrivateMessageSystem.sendChatMessage(player, "🔧 [ADMIN] " .. message)
        end
    end
end

-- Função para inicializar o sistema
function PrivateMessageSystem.initialize()
    print("Sistema de mensagens privadas inicializado!")
end

return PrivateMessageSystem
