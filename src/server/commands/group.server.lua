local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

RegisterCommand({
    name = "group",
    description = "",
    aliases = {"g"},
    permissions = {'owner', 'admin', 'moderator', 'vip-gold'}
}, function(player, params, message)
    local group = params[1]
    local user = params[2]

    if (not group) then
        return
    end
    
    

end)