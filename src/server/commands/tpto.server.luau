local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")

RegisterCommand({
    name = "tpto",
    description = "Teleporta para um jogador",
    aliases = { "tp" },
    permissions = { "owner", "admin" }
}, function(player, params, message)
    local targetPlayer = params[1]
    
    -- Verifica se foi fornecido um nome de jogador
    if not targetPlayer then
        return
    end
    
    -- Procura pelo jogador alvo
    local target = Players:FindFirstChild(targetPlayer)
    if not target then
        return
    end
    
    -- Verifica se o jogador alvo tem um personagem
    local targetCharacter = target.Character
    if not targetCharacter then
        return
    end
    
    -- Verifica se o jogador atual tem um personagem
    local playerCharacter = player.Character
    if not playerCharacter then
        return
    end
    
    local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart or not targetRootPart then
        return
    end
    
    -- Teleporta o jogador para a posição do alvo
    humanoidRootPart.CFrame = targetRootPart.CFrame
end)
