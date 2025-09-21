export type DefGroup = {
    name: string,
    color: Color3,
    organization: string?
}

export type DefGroupList = {[string]: DefGroup}

return {
    owner = {
        name = 'Owner',
        color = Color3.fromRGB(255, 215, 0),
        organization = 'staff'
    },
    admin = {
        name = 'Administrador',
        color = Color3.fromRGB(255, 0, 0),
        organization = 'staff'
    },
    moderator = {
        name = 'Moderador',
        color = Color3.fromRGB(0, 255, 0),
        organization = 'staff'
    },
    ['vip-gold'] = {
        name = 'VIP Gold',
        color = Color3.fromRGB(0, 255, 0),
    },
} :: DefGroupList