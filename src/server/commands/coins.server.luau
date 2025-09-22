-- Comando Coins (Chat do Jogador)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_MODULE = require(game.ServerScriptService.Server.framework.modules.player)
local PLAYTIME_MODULE = require(game.ServerScriptService.Server.framework.modules.playtime)

-- Cache
local cache = { player = {} }
local playerModule = PLAYER_MODULE()

-- Aguardar RemoteEvent
local chatMessageEvent = ReplicatedStorage:WaitForChild("ChatMessageEvent")

local function coinsCommand(player, params)
    local target = #params > 0 and Players:FindFirstChild(params[1]) or player
    
    if not target then
        chatMessageEvent:FireClient(player, "❌ Jogador não encontrado")
        return
    end
    
    local data = playerModule.get(target, false)
    if not data then
        chatMessageEvent:FireClient(player, "❌ Erro ao carregar dados do jogador")
        return
    end
    
    local totalTime, sessionTime = PLAYTIME_MODULE.getCurrentTime(target)
    local totalWithSession = totalTime + sessionTime
    
    local message = string.format("💰 %s:\n   Tempo total jogado: %s\n   Moedas: %d", 
        target.Name,
        PLAYTIME_MODULE.formatTime(totalWithSession),
        data.coins or 0
    )
    
    -- Mostrar próximos marcos
    local milestones = PLAYTIME_MODULE.getMilestones()
    local totalMinutes = totalWithSession / 60
    local nextMilestone = nil
    
    for minutes, bonus in pairs(milestones) do
        if totalMinutes < minutes then
            if not nextMilestone or minutes < nextMilestone.minutes then
                nextMilestone = {minutes = minutes, bonus = bonus}
            end
        end
    end
    
    if nextMilestone then
        local remaining = nextMilestone.minutes - totalMinutes
        message = message .. string.format("\n   Próximo marco: %d min (faltam %.1f min) - +%d moedas", 
            nextMilestone.minutes, remaining, nextMilestone.bonus)
    else
        message = message .. "\n   🏆 Todos os marcos alcançados!"
    end
    
    -- Enviar mensagem no chat do jogador
    chatMessageEvent:FireClient(player, message)
end

local registerCommand = require(ReplicatedStorage.Shared["register-command"])
registerCommand({
    name = "coins",
    description = "Ver moedas e recompensas",
    aliases = {"money", "dinheiro"}
}, coinsCommand)

