local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()



RegisterCommand({
    name = "tpto",
    description = "Teleporta para um jogador (nome ou ID)",
    aliases = { "tp" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local targetInput = params[1]
    
    -- Verifica se foi fornecido um parâmetro
    if not targetInput then
        ChatMessage.sendError(player, "❌ Uso: /tpto <nome ou ID>")
        return
    end
    
    local target = nil
    local searchMethod = ""
    
    -- Verifica se o input é um número (User ID)
    local userId = tonumber(targetInput)
    if userId then
        -- Buscar por User ID customizado
        target = PlayerModule.getPlayerByUserId(userId)
        searchMethod = "ID " .. userId
    else
        -- Buscar por nome de jogador
        target = Players:FindFirstChild(targetInput)
        searchMethod = "nome '" .. targetInput .. "'"
    end
    
    -- Verifica se encontrou o jogador
    if not target then
        ChatMessage.sendError(player, "❌ Jogador com " .. searchMethod .. " não encontrado ou não está online!")
        return
    end
    
    -- Verifica se o jogador alvo tem um personagem
    local targetCharacter = target.Character
    if not targetCharacter then
        ChatMessage.sendError(player, "❌ " .. target.Name .. " não tem um personagem ativo!")
        return
    end
    
    -- Verifica se o jogador atual tem um personagem
    local playerCharacter = player.Character
    if not playerCharacter then
        ChatMessage.sendError(player, "❌ Você não tem um personagem ativo!")
        return
    end
    
    local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart or not targetRootPart then
        ChatMessage.sendError(player, "❌ Erro ao localizar posições dos personagens!")
        return
    end
    
    -- Teleporta o jogador para a posição do alvo
    humanoidRootPart.CFrame = targetRootPart.CFrame
    
    -- Obter User ID do jogador alvo para mostrar na mensagem
    local targetPlayerData, _ = PlayerModule.get(target, false)
    local targetUserId = targetPlayerData and targetPlayerData.userId
    
    local successMessage = "✅ Teleportado para " .. target.Name
    if targetUserId then
        successMessage = successMessage .. " [ID: " .. targetUserId .. "]"
    end
    
    ChatMessage.sendSuccess(player, successMessage)
end)
