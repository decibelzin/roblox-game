-- Gerenciador de permissões do servidor
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Permissions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("permissions"):WaitForChild("Permissions"))

local PermissionManager = {}
PermissionManager.playerPermissions = {} -- Cache de permissões dos jogadores
PermissionManager.dataStore = DataStoreService:GetDataStore("PlayerPermissions")

-- Lista de administradores por UserId (pode ser configurada)
PermissionManager.ADMIN_USER_IDS = {
    -- Adicione UserIds de administradores aqui
    -- Exemplo: 123456789, 987654321
}

-- Lista de VIPs por UserId
PermissionManager.VIP_USER_IDS = {
    -- Adicione UserIds de VIPs aqui
    -- Exemplo: 111222333, 444555666
}

-- Função para obter o nível de permissão de um jogador
function PermissionManager.getPlayerLevel(player)
    local userId = player.UserId
    
    -- Verificar se é dono (UserIds especiais)
    if userId == game.CreatorId then
        return Permissions.LEVELS.OWNER
    end
    
    -- Verificar se é administrador
    for _, adminId in ipairs(PermissionManager.ADMIN_USER_IDS) do
        if userId == adminId then
            return Permissions.LEVELS.ADMIN
        end
    end
    
    -- Verificar se é VIP
    for _, vipId in ipairs(PermissionManager.VIP_USER_IDS) do
        if userId == vipId then
            return Permissions.LEVELS.VIP
        end
    end
    
    -- Verificar se tem permissões salvas no DataStore
    local savedLevel = PermissionManager.playerPermissions[userId]
    if savedLevel then
        return savedLevel
    end
    
    -- Tentar carregar do DataStore
    local success, level = pcall(function()
        return PermissionManager.dataStore:GetAsync("level_" .. userId)
    end)
    
    if success and level then
        PermissionManager.playerPermissions[userId] = level
        return level
    end
    
    -- Padrão: jogador normal
    return Permissions.LEVELS.PLAYER
end

-- Função para verificar se um jogador tem uma permissão
function PermissionManager.hasPermission(player, permission)
    local level = PermissionManager.getPlayerLevel(player)
    return Permissions.hasPermission(level, permission)
end

-- Função para definir o nível de permissão de um jogador
function PermissionManager.setPlayerLevel(player, level)
    local userId = player.UserId
    
    -- Verificar se quem está tentando definir tem permissão
    if not PermissionManager.hasPermission(player, Permissions.FLAGS.SET_PERMISSIONS) then
        return false, "Você não tem permissão para definir níveis de permissão"
    end
    
    -- Salvar no cache
    PermissionManager.playerPermissions[userId] = level
    
    -- Salvar no DataStore
    local success, error = pcall(function()
        PermissionManager.dataStore:SetAsync("level_" .. userId, level)
    end)
    
    if success then
        print(player.Name .. " teve seu nível alterado para: " .. Permissions.getLevelName(level))
        return true, "Nível de permissão alterado com sucesso"
    else
        return false, "Erro ao salvar permissão: " .. tostring(error)
    end
end

-- Função para obter informações de permissão de um jogador
function PermissionManager.getPlayerInfo(player)
    local level = PermissionManager.getPlayerLevel(player)
    local permissions = Permissions.getLevelPermissions(level)
    
    return {
        level = level,
        levelName = Permissions.getLevelName(level),
        permissions = permissions,
        userId = player.UserId,
        username = player.Name
    }
end

-- Função para listar todos os jogadores e suas permissões
function PermissionManager.getAllPlayersInfo()
    local playersInfo = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(playersInfo, PermissionManager.getPlayerInfo(player))
    end
    
    return playersInfo
end

-- Função para verificar se um jogador pode executar um comando
function PermissionManager.canExecuteCommand(player, command)
    -- Comandos que não precisam de permissão específica
    local freeCommands = {
        "help",
        "who"
    }
    
    -- Verificar se é um comando livre
    for _, freeCmd in ipairs(freeCommands) do
        if command:lower() == freeCmd then
            return true, "Comando livre"
        end
    end
    
    -- Mapeamento de comandos para permissões necessárias
    local commandPermissions = {
        ["kick"] = Permissions.FLAGS.KICK,
        ["ban"] = Permissions.FLAGS.BAN,
        ["mute"] = Permissions.FLAGS.MUTE,
        ["unmute"] = Permissions.FLAGS.UNMUTE,
        ["teleport"] = Permissions.FLAGS.TELEPORT,
        ["tp"] = Permissions.FLAGS.TELEPORT,
        ["give"] = Permissions.FLAGS.GIVE_ITEMS,
        ["setperm"] = Permissions.FLAGS.SET_PERMISSIONS,
        ["admin"] = Permissions.FLAGS.ADMIN_CHAT
    }
    
    local requiredPermission = commandPermissions[command:lower()]
    if not requiredPermission then
        return false, "Comando não reconhecido"
    end
    
    if PermissionManager.hasPermission(player, requiredPermission) then
        return true, "Permissão concedida"
    else
        return false, "Você não tem permissão para executar este comando"
    end
end

-- Função para inicializar o sistema de permissões
function PermissionManager.initialize()
    print("Sistema de permissões inicializado!")
    print("Administradores configurados: " .. #PermissionManager.ADMIN_USER_IDS)
    print("VIPs configurados: " .. #PermissionManager.VIP_USER_IDS)
end

return PermissionManager
