local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

-- Função para encontrar jogador por User ID customizado
local function findPlayerByUserId(userId)
    for _, player in pairs(Players:GetPlayers()) do
        local playerData, _ = PlayerModule.get(player, false)
        if playerData and playerData.userId == userId then
            return player
        end
    end
    return nil
end

RegisterCommand({
    name = "tptome",
    description = "Teleporta um jogador até você (nome ou ID)",
    aliases = { "bring", "summon" },
    permissions = { "owner", "admin", "moderator" }
}, function(player, params, message)
    local targetInput = params[1]
    
    -- Verifica se foi fornecido um parâmetro
    if not targetInput then
        ChatMessage.sendError(player, "❌ Uso: /tptome <nome ou ID>")
        return
    end
    
    local target = nil
    local searchMethod = ""
    
    -- Verifica se o input é um número (User ID)
    local userId = tonumber(targetInput)
    if userId then
        -- Buscar por User ID customizado
        target = findPlayerByUserId(userId)
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
    
    -- Verificar se não está tentando teleportar a si mesmo
    if target == player then
        ChatMessage.sendError(player, "❌ Você não pode teleportar a si mesmo!")
        return
    end
    
    -- Verifica se o jogador atual tem um personagem
    local playerCharacter = player.Character
    if not playerCharacter then
        ChatMessage.sendError(player, "❌ Você não tem um personagem ativo!")
        return
    end
    
    -- Verifica se o jogador alvo tem um personagem
    local targetCharacter = target.Character
    if not targetCharacter then
        ChatMessage.sendError(player, "❌ " .. target.Name .. " não tem um personagem ativo!")
        return
    end
    
    local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not playerRootPart or not targetRootPart then
        ChatMessage.sendError(player, "❌ Erro ao localizar posições dos personagens!")
        return
    end
    
    -- Teleporta o jogador alvo para a posição do jogador atual
    targetRootPart.CFrame = playerRootPart.CFrame * CFrame.new(3, 0, 0) -- Offset de 3 studs para não colidir
    
    -- Obter User ID do jogador alvo para mostrar na mensagem
    local targetPlayerData, _ = PlayerModule.get(target, false)
    local targetUserId = targetPlayerData and targetPlayerData.userId
    
    local successMessage = "✅ " .. target.Name
    if targetUserId then
        successMessage = successMessage .. " [ID: " .. targetUserId .. "]"
    end
    successMessage = successMessage .. " foi teleportado até você!"
    
    ChatMessage.sendSuccess(player, successMessage)
    
    -- Notificar o jogador que foi teleportado
    local notifyMessage = "📍 Você foi teleportado até " .. player.Name
    local playerData, _ = PlayerModule.get(player, false)
    if playerData and playerData.userId then
        notifyMessage = notifyMessage .. " [ID: " .. playerData.userId .. "]"
    end
    
    ChatMessage.sendInfo(target, notifyMessage)
end)
