local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Garantir que existe apenas um RemoteEvent para mensagens de chat
local chatMessageEvent = ReplicatedStorage:FindFirstChild("ChatMessageEvent")
if not chatMessageEvent then
    chatMessageEvent = Instance.new("RemoteEvent")
    chatMessageEvent.Name = "ChatMessageEvent"
    chatMessageEvent.Parent = ReplicatedStorage
end

local ChatMessage = {}

--- Envia uma mensagem de chat para um jogador específico
function ChatMessage.sendToPlayer(player: Player, message: string, color: Color3?)
    if not player or not message then
        return false
    end
    
    local messageColor = color or Color3.fromRGB(255, 255, 255)
    
    local success = pcall(function()
        chatMessageEvent:FireClient(player, message, messageColor)
    end)
    
    return success
end

--- Envia uma mensagem de chat para todos os jogadores
function ChatMessage.sendToAll(message: string, color: Color3?)
    if not message then
        return false
    end
    
    local messageColor = color or Color3.fromRGB(255, 255, 255)
    
    local success = pcall(function()
        chatMessageEvent:FireAllClients(message, messageColor)
    end)
    
    return success
end

--- Envia uma mensagem de erro (vermelha) para um jogador
function ChatMessage.sendError(player: Player, message: string)
    return ChatMessage.sendToPlayer(player, message, Color3.fromRGB(255, 0, 0))
end

--- Envia uma mensagem de sucesso (verde) para um jogador
function ChatMessage.sendSuccess(player: Player, message: string)
    return ChatMessage.sendToPlayer(player, message, Color3.fromRGB(0, 255, 0))
end

--- Envia uma mensagem de aviso (amarela) para um jogador
function ChatMessage.sendWarning(player: Player, message: string)
    return ChatMessage.sendToPlayer(player, message, Color3.fromRGB(255, 255, 0))
end

--- Envia uma mensagem de informação (azul) para um jogador
function ChatMessage.sendInfo(player: Player, message: string)
    return ChatMessage.sendToPlayer(player, message, Color3.fromRGB(0, 150, 255))
end

return ChatMessage 