-- Arquivo principal do servidor - orquestra todos os serviços
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar serviços
local PlayerService = require(script.services.PlayerService)
local PermissionManager = require(script.permissions.PermissionManager)
local CommandSystem = require(script.permissions.CommandSystem)
local PrivateMessageSystem = require(script.permissions.PrivateMessageSystem)

-- Criar RemoteEvent para comunicação cliente-servidor
local playerReadyEvent = Instance.new("RemoteEvent")
playerReadyEvent.Name = "PlayerReady"
playerReadyEvent.Parent = ReplicatedStorage

-- Criar RemoteFunction para enviar configurações para o cliente
local configRemote = Instance.new("RemoteFunction")
configRemote.Name = "GetGameConfig"
configRemote.Parent = ReplicatedStorage

-- Criar RemoteFunction para obter informações de permissão
local permissionRemote = Instance.new("RemoteFunction")
permissionRemote.Name = "GetPlayerPermissions"
permissionRemote.Parent = ReplicatedStorage

-- Criar RemoteEvent para reset da câmera
local cameraResetEvent = Instance.new("RemoteEvent")
cameraResetEvent.Name = "CameraReset"
cameraResetEvent.Parent = ReplicatedStorage

-- Função para retornar as configurações
configRemote.OnServerInvoke = function(player)
    local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameConfig"))
    return GameConfig
end

-- Função para retornar informações de permissão do jogador
permissionRemote.OnServerInvoke = function(player)
    return PermissionManager.getPlayerInfo(player)
end

-- Função para processar mensagens de chat
local function onPlayerChatted(player, message)
    -- Verificar se é um comando
    if CommandSystem.processChatCommand(player, message) then
        return -- Comando processado, não enviar para o chat
    end
    
    -- Verificar se o jogador tem permissão para usar o chat
    if not PermissionManager.hasPermission(player, "chat") then
        -- Jogador não tem permissão para usar o chat
        PrivateMessageSystem.sendMessage(player, "❌ Você não tem permissão para usar o chat.", "error")
        return
    end
    
    -- Permitir mensagem normal do chat
end

-- Conectar eventos
Players.PlayerAdded:Connect(PlayerService.onPlayerAdded)
playerReadyEvent.OnServerEvent:Connect(PlayerService.onPlayerReady)

-- Conectar sistema de chat
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

-- Inicializar sistemas
PermissionManager.initialize()
CommandSystem.initialize()
PrivateMessageSystem.initialize()

print("Servidor iniciado com sistema de permissões completo!")
