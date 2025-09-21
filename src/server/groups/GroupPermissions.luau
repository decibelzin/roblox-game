-- Definições reais de permissões (NUNCA enviar ao cliente)
return {
    Admin = {
        canBan = true,
        canKick = true,
        canGiveItems = true,
        canTeleport = true,
        canManageGroups = true,
        canUseAdminCommands = true,
        canMute = true,
        canUnmute = true
    },
    Moderator = {
        canKick = true,
        canMute = true,
        canUnmute = true,
        canUseModCommands = true
    },
    Vip = {
        canUseVIPCommands = true,
        canUseVIPItems = true
    }
}
