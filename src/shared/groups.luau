-- Informações de display dos grupos (seguro para o cliente)
return {
    -- Grupos especiais do Roblox
    Owner = {
        displayName = "Owner",
        color = Color3.fromRGB(255, 215, 0), -- Dourado
        priority = 5
    },
    GroupAdmin = {
        displayName = "Admin do Grupo",
        color = Color3.fromRGB(255, 165, 0), -- Laranja
        priority = 4
    },
    
    -- Grupos personalizados
    Admin = {
        displayName = "Administrador",
        color = Color3.fromRGB(255, 0, 0),
        priority = 3
    },
    Moderator = {
        displayName = "Moderador", 
        color = Color3.fromRGB(0, 255, 0),
        priority = 2
    },
    Vip = {
        displayName = "VIP",
        color = Color3.fromRGB(255, 255, 0),
        priority = 1
    }
}
