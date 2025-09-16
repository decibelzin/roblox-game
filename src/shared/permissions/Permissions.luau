-- Sistema de permissões - Definições e enums
local Permissions = {}

-- Níveis de permissão (ordem crescente de poder)
Permissions.LEVELS = {
    GUEST = 0,      -- Visitante (sem permissões especiais)
    PLAYER = 1,     -- Jogador normal
    VIP = 2,        -- VIP (permissões especiais)
    MODERATOR = 3,  -- Moderador
    ADMIN = 4,      -- Administrador
    OWNER = 5       -- Dono do jogo
}

-- Permissões específicas
Permissions.FLAGS = {
    -- Permissões básicas
    CHAT = "chat",
    PLAY = "play",
    SPAWN = "spawn",
    
    -- Permissões de moderação
    KICK = "kick",
    BAN = "ban",
    MUTE = "mute",
    UNMUTE = "unmute",
    TELEPORT = "teleport",
    
    -- Permissões administrativas
    ADMIN_CHAT = "admin_chat",
    GIVE_ITEMS = "give_items",
    SET_PERMISSIONS = "set_permissions",
    SERVER_COMMANDS = "server_commands",
    
    -- Permissões de dono
    ALL_PERMISSIONS = "all_permissions",
    SHUTDOWN = "shutdown",
    RESTART = "restart"
}

-- Mapeamento de permissões por nível
Permissions.LEVEL_PERMISSIONS = {
    [Permissions.LEVELS.GUEST] = {
        Permissions.FLAGS.CHAT,
        Permissions.FLAGS.PLAY
    },
    
    [Permissions.LEVELS.PLAYER] = {
        Permissions.FLAGS.CHAT,
        Permissions.FLAGS.PLAY,
        Permissions.FLAGS.SPAWN
    },
    
    [Permissions.LEVELS.VIP] = {
        Permissions.FLAGS.CHAT,
        Permissions.FLAGS.PLAY,
        Permissions.FLAGS.SPAWN,
        Permissions.FLAGS.TELEPORT
    },
    
    [Permissions.LEVELS.MODERATOR] = {
        Permissions.FLAGS.CHAT,
        Permissions.FLAGS.PLAY,
        Permissions.FLAGS.SPAWN,
        Permissions.FLAGS.TELEPORT,
        Permissions.FLAGS.KICK,
        Permissions.FLAGS.MUTE,
        Permissions.FLAGS.UNMUTE
    },
    
    [Permissions.LEVELS.ADMIN] = {
        Permissions.FLAGS.CHAT,
        Permissions.FLAGS.PLAY,
        Permissions.FLAGS.SPAWN,
        Permissions.FLAGS.TELEPORT,
        Permissions.FLAGS.KICK,
        Permissions.FLAGS.BAN,
        Permissions.FLAGS.MUTE,
        Permissions.FLAGS.UNMUTE,
        Permissions.FLAGS.ADMIN_CHAT,
        Permissions.FLAGS.GIVE_ITEMS,
        Permissions.FLAGS.SET_PERMISSIONS
    },
    
    [Permissions.LEVELS.OWNER] = {
        -- Dono tem todas as permissões
        Permissions.FLAGS.ALL_PERMISSIONS
    }
}

-- Função para verificar se um nível tem uma permissão
function Permissions.hasPermission(level, permission)
    if level == Permissions.LEVELS.OWNER then
        return true -- Dono tem todas as permissões
    end
    
    local permissions = Permissions.LEVEL_PERMISSIONS[level] or {}
    for _, perm in ipairs(permissions) do
        if perm == permission then
            return true
        end
    end
    
    return false
end

-- Função para obter o nome do nível
function Permissions.getLevelName(level)
    for name, value in pairs(Permissions.LEVELS) do
        if value == level then
            return name
        end
    end
    return "UNKNOWN"
end

-- Função para obter todas as permissões de um nível
function Permissions.getLevelPermissions(level)
    if level == Permissions.LEVELS.OWNER then
        -- Retorna todas as permissões para o dono
        local allPermissions = {}
        for _, flag in pairs(Permissions.FLAGS) do
            table.insert(allPermissions, flag)
        end
        return allPermissions
    end
    
    return Permissions.LEVEL_PERMISSIONS[level] or {}
end

return Permissions
