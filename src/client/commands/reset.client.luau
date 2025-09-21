local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

RegisterCommand({
    name = "reset",
    description = "comando de teste",
    aliases = {"r", "res"}
}, function(player, params, message)
    if (not player.Character) then return end

    player:LoadCharacterAppearance()

end)