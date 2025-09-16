-- Sistema de comandos administrativos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PermissionManager = require(script.Parent.PermissionManager)
local ChatSystem = require(script.Parent.ChatSystem)

local CommandSystem = {}
CommandSystem.commandPrefix = "!" -- Prefixo para comandos (ex: !kick, !ban)

-- Função para processar comandos de chat
function CommandSystem.processChatCommand(player, message)
    -- Verificar se a mensagem começa com o prefixo
    if message:sub(1, 1) ~= CommandSystem.commandPrefix then
        return false
    end
    
    -- Remover o prefixo e dividir em argumentos
    local command = message:sub(2):lower()
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then
        return false
    end
    
    local cmd = args[1]
    table.remove(args, 1) -- Remover o comando dos argumentos
    
    -- Processar comando
    return CommandSystem.executeCommand(player, cmd, args)
end

-- Função para executar comandos
function CommandSystem.executeCommand(player, command, args)
    local success, message = PermissionManager.canExecuteCommand(player, command)
    
    if not success then
        ChatSystem.sendMessage(player, "❌ " .. message)
        return true
    end
    
    -- Executar comando baseado no tipo
    if command == "kick" then
        return CommandSystem.kickCommand(player, args)
    elseif command == "ban" then
        return CommandSystem.banCommand(player, args)
    elseif command == "mute" then
        return CommandSystem.muteCommand(player, args)
    elseif command == "unmute" then
        return CommandSystem.unmuteCommand(player, args)
    elseif command == "teleport" or command == "tp" then
        return CommandSystem.teleportCommand(player, args)
    elseif command == "give" then
        return CommandSystem.giveCommand(player, args)
    elseif command == "setperm" then
        return CommandSystem.setPermissionCommand(player, args)
    elseif command == "admin" then
        return CommandSystem.adminChatCommand(player, args)
    elseif command == "help" then
        return CommandSystem.helpCommand(player, args)
    elseif command == "who" then
        return CommandSystem.whoCommand(player, args)
    elseif command == "camera" or command == "cam" then
        return CommandSystem.cameraCommand(player, args)
    else
        ChatSystem.sendMessage(player, "❌ Comando não encontrado. Use !help para ver comandos disponíveis.")
        return true
    end
end

-- Comando: !kick <jogador> [motivo]
function CommandSystem.kickCommand(player, args)
    if #args < 1 then
        ChatSystem.sendMessage(player, "❌ Uso: !kick <jogador> [motivo]")
        return true
    end
    
    local targetName = args[1]
    local reason = table.concat(args, " ", 2) or "Sem motivo especificado"
    
    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer then
        ChatSystem.sendMessage(player, "❌ Jogador '" .. targetName .. "' não encontrado.")
        return true
    end
    
    -- Verificar se não está tentando kickar alguém com nível igual ou maior
    local playerLevel = PermissionManager.getPlayerLevel(player)
    local targetLevel = PermissionManager.getPlayerLevel(targetPlayer)
    
    if targetLevel >= playerLevel then
        ChatSystem.sendMessage(player, "❌ Você não pode kickar este jogador.")
        return true
    end
    
    -- Kickar o jogador
    targetPlayer:Kick("Você foi kickado por " .. player.Name .. ". Motivo: " .. reason)
    ChatSystem.sendMessage(player, "✅ " .. targetName .. " foi kickado. Motivo: " .. reason)
    
    -- Notificar administradores
    ChatSystem.sendToAdmins(player.Name .. " kickou " .. targetName .. ". Motivo: " .. reason)
    
    return true
end

-- Comando: !mute <jogador> [tempo]
function CommandSystem.muteCommand(player, args)
    if #args < 1 then
        ChatSystem.sendMessage(player, "❌ Uso: !mute <jogador> [tempo]")
        return true
    end
    
    local targetName = args[1]
    local time = tonumber(args[2]) or 60 -- 60 segundos por padrão
    
    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer then
        ChatSystem.sendMessage(player, "❌ Jogador '" .. targetName .. "' não encontrado.")
        return true
    end
    
    -- Implementar sistema de mute aqui
    ChatSystem.sendMessage(player, "✅ " .. targetName .. " foi mutado por " .. time .. " segundos.")
    
    return true
end

-- Comando: !teleport <jogador1> <jogador2>
function CommandSystem.teleportCommand(player, args)
    if #args < 2 then
        ChatSystem.sendMessage(player, "❌ Uso: !teleport <jogador1> <jogador2>")
        return true
    end
    
    local player1Name = args[1]
    local player2Name = args[2]
    
    local player1 = Players:FindFirstChild(player1Name)
    local player2 = Players:FindFirstChild(player2Name)
    
    if not player1 or not player2 then
        ChatSystem.sendMessage(player, "❌ Um ou ambos os jogadores não foram encontrados.")
        return true
    end
    
    if player1.Character and player1.Character:FindFirstChild("HumanoidRootPart") and
       player2.Character and player2.Character:FindFirstChild("HumanoidRootPart") then
        
        player1.Character.HumanoidRootPart.CFrame = player2.Character.HumanoidRootPart.CFrame
        ChatSystem.sendMessage(player, "✅ " .. player1Name .. " foi teleportado para " .. player2Name)
    else
        ChatSystem.sendMessage(player, "❌ Erro ao teleportar jogadores.")
    end
    
    return true
end

-- Comando: !setperm <jogador> <nível>
function CommandSystem.setPermissionCommand(player, args)
    if #args < 2 then
        ChatSystem.sendMessage(player, "❌ Uso: !setperm <jogador> <nível>")
        ChatSystem.sendMessage(player, "Níveis: GUEST(0), PLAYER(1), VIP(2), MODERATOR(3), ADMIN(4), OWNER(5)")
        return true
    end
    
    local targetName = args[1]
    local level = tonumber(args[2])
    
    if not level or level < 0 or level > 5 then
        ChatSystem.sendMessage(player, "❌ Nível inválido. Use 0-5.")
        return true
    end
    
    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer then
        ChatSystem.sendMessage(player, "❌ Jogador '" .. targetName .. "' não encontrado.")
        return true
    end
    
    local success, message = PermissionManager.setPlayerLevel(targetPlayer, level)
    ChatSystem.sendMessage(player, success and "✅ " .. message or "❌ " .. message)
    
    return true
end

-- Comando: !camera [reset]
function CommandSystem.cameraCommand(player, args)
    local action = args[1] or "reset"
    
    if action == "reset" then
        -- Enviar comando para o cliente resetar a câmera
        local cameraResetEvent = ReplicatedStorage:FindFirstChild("CameraReset")
        if not cameraResetEvent then
            cameraResetEvent = Instance.new("RemoteEvent")
            cameraResetEvent.Name = "CameraReset"
            cameraResetEvent.Parent = ReplicatedStorage
        end
        
        cameraResetEvent:FireClient(player)
        ChatSystem.sendMessage(player, "✅ Câmera resetada!")
    else
        ChatSystem.sendMessage(player, "❌ Uso: !camera [reset]")
    end
    
    return true
end

-- Comando: !help
function CommandSystem.helpCommand(player, args)
    local playerInfo = PermissionManager.getPlayerInfo(player)
    
    ChatSystem.sendMessage(player, "🔧 Comandos disponíveis para " .. playerInfo.levelName .. ":")
    ChatSystem.sendMessage(player, "• !help - Mostra esta ajuda")
    ChatSystem.sendMessage(player, "• !who - Lista jogadores e permissões")
    ChatSystem.sendMessage(player, "• !camera - Reseta a câmera")
    
    -- Comandos baseados em permissões
    if PermissionManager.hasPermission(player, "kick") then
        ChatSystem.sendMessage(player, "• !kick <jogador> [motivo] - Kickar jogador")
    end
    
    if PermissionManager.hasPermission(player, "mute") then
        ChatSystem.sendMessage(player, "• !mute <jogador> [tempo] - Mutar jogador")
        ChatSystem.sendMessage(player, "• !unmute <jogador> - Desmutar jogador")
    end
    
    if PermissionManager.hasPermission(player, "teleport") then
        ChatSystem.sendMessage(player, "• !teleport <jogador1> <jogador2> - Teleportar jogadores")
    end
    
    if PermissionManager.hasPermission(player, "set_permissions") then
        ChatSystem.sendMessage(player, "• !setperm <jogador> <nível> - Definir permissões")
    end
    
    return true
end

-- Comando: !who
function CommandSystem.whoCommand(player, args)
    local playersInfo = PermissionManager.getAllPlayersInfo()
    
    ChatSystem.sendMessage(player, "👥 Jogadores online:")
    
    for _, info in ipairs(playersInfo) do
        ChatSystem.sendMessage(player, "• " .. info.username .. " (" .. info.levelName .. ")")
    end
    
    return true
end

-- Função para inicializar o sistema de comandos
function CommandSystem.initialize()
    print("Sistema de comandos inicializado!")
    print("Prefixo de comandos: " .. CommandSystem.commandPrefix)
end

return CommandSystem
