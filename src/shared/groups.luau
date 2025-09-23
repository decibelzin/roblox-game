export type DefGroup = {
    name: string,
    color: Color3,
    organization: string?,
    priority: number
}

export type DefGroupList = {[string]: DefGroup}

return {
    owner = {
        name = 'Owner',
        color = Color3.fromRGB(255, 215, 0),
        organization = 'staff',
        priority = 4
    },
    admin = {
        name = 'Administrador',
        color = Color3.fromRGB(255, 0, 0),
        organization = 'staff',
        priority = 3
    },
    moderator = {
        name = 'Moderador',
        color = Color3.fromRGB(0, 255, 0),
        organization = 'staff',
        priority = 2
    },
    ['vip-gold'] = {
        name = 'VIP Gold',
        color = Color3.fromRGB(255, 238, 0),
        priority = 1
    },
} :: DefGroupList
