export type DefGroup = {
    name: string,
    color: Color3,
    organization: string?,
    priority: number
}

export type DefGroupList = {[string]: DefGroup}

return {
    owner = {
        name = 'owner',
        color = Color3.fromRGB(255, 0, 255),
        organization = 'staff',
        priority = 4
    },
    admin = {
        name = 'admin',
        color = Color3.fromRGB(255, 0, 0),
        organization = 'staff',
        priority = 3
    },
    moderator = {
        name = 'moderator',
        color = Color3.fromRGB(0, 238, 255),
        organization = 'staff',
        priority = 2
    },
    ['vip-gold'] = {
        name = 'vip gold',
        color = Color3.fromRGB(255, 238, 0),
        priority = 1
    },
} :: DefGroupList
