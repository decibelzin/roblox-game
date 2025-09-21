-- Cliente para exibir mensagens do chat enviadas pelo servidor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Aguardar o RemoteEvent ser criado
local chatMessageEvent = ReplicatedStorage:WaitForChild("ChatMessageEvent")

-- Conectar ao evento de mensagem do chat
chatMessageEvent.OnClientEvent:Connect(function(message)
    -- Exibir a mensagem no chat do jogo
    local textChannel = TextChatService.TextChannels.RBXGeneral
    textChannel:DisplaySystemMessage(message)
    
    -- Também imprimir no console do cliente para debug
    print("📨 Mensagem do chat recebida:", message)
end)

print("✅ Sistema de mensagens do chat inicializado!")
