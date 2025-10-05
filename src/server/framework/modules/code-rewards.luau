-- Módulo para gerenciar recompensas dos códigos resgatáveis
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])

local CodeRewards = {}

-- Definir recompensas para cada código
local REWARDS = {
    ['A098WD98'] = {
        type = "gems",
        amount = 100,
        message = "Você recebeu 100 gemas!"
    },
    ['WELCOME2024'] = {
        type = "experience",
        amount = 500,
        message = "Você recebeu 500 XP de bônus!"
    },
    ['FREEGEMS'] = {
        type = "gems",
        amount = 250,
        message = "Você recebeu 250 gemas grátis!"
    },
    ['NEWPLAYER'] = {
        type = "starter_pack",
        items = {"sword", "shield", "potion"},
        message = "Você recebeu o pacote inicial!"
    }
}

-- Função para dar gemas ao jogador
local function giveGems(player: Player, amount: number)
    -- Aqui você implementaria a lógica para dar gemas
    -- Exemplo: player.leaderstats.Gems.Value = player.leaderstats.Gems.Value + amount
    --print("Dando", amount, "gemas para", player.Name)
end

-- Função para dar experiência ao jogador
local function giveExperience(player: Player, amount: number)
    -- Aqui você implementaria a lógica para dar XP
    -- Exemplo: player.leaderstats.XP.Value = player.leaderstats.XP.Value + amount
    --print("Dando", amount, "XP para", player.Name)
end

-- Função para dar itens ao jogador
local function giveItems(player: Player, items: {string})
    -- Aqui você implementaria a lógica para dar itens
    for _, item in ipairs(items) do
        -- print("Dando item", item, "para", player.Name)
    end
end

-- Função principal para processar recompensa
function CodeRewards.giveReward(player: Player, code: string): boolean
    local reward = REWARDS[code]
    
    if not reward then
        warn("Recompensa não definida para o código:", code)
        return false
    end
    
    -- Processar recompensa baseada no tipo
    if reward.type == "gems" then
        giveGems(player, reward.amount)
    elseif reward.type == "experience" then
        giveExperience(player, reward.amount)
    elseif reward.type == "starter_pack" then
        giveItems(player, reward.items)
    else
        warn("Tipo de recompensa desconhecido:", reward.type)
        return false
    end
    
    -- Enviar mensagem de sucesso
    ChatMessage.sendSuccess(player, reward.message)
    
    return true
end

-- Função para verificar se um código tem recompensa definida
function CodeRewards.hasReward(code: string): boolean
    return REWARDS[code] ~= nil
end

-- Função para obter informações da recompensa (sem dar a recompensa)
function CodeRewards.getRewardInfo(code: string)
    return REWARDS[code]
end

return CodeRewards 