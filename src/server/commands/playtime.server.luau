-- Comando Playtime (Chat do Jogador)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_MODULE = require(game.ServerScriptService.Server.framework.modules.player)
local PLAYTIME_MODULE = require(game.ServerScriptService.Server.framework.modules.playtime)

-- Cache
local cache = { player = {} }
local playerModule = PLAYER_MODULE(cache.player)

-- Aguardar RemoteEvent
local chatMessageEvent = ReplicatedStorage:WaitForChild("ChatMessageEvent")

local function playtimeCommand(player, params)
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
    
    local total, session = PLAYTIME_MODULE.getCurrentTime(target)
    local totalWithSession = total + session
    
    -- Calcular moedas ganhas na sessão
    local coinsEarned = math.floor((session / 60) * PLAYTIME_MODULE.getCoinsPerMinute())
    
    local message = string.format("📊 %s:\n   Tempo total jogado: %s\n   Moedas: %d", 
        target.Name, 
        PLAYTIME_MODULE.formatTime(totalWithSession),
        data.coins or 0
    )
    
    if coinsEarned > 0 then
        message = message .. string.format("\n   Moedas ganhas nesta sessão: %d", coinsEarned)
    end
    
    -- Enviar mensagem no chat do jogador
    chatMessageEvent:FireClient(player, message)
end

local registerCommand = require(ReplicatedStorage.Shared["register-command"])
registerCommand({
    name = "playtime",
    description = "Ver tempo de jogo e moedas",
    aliases = {"pt", "tempo"}
}, playtimeCommand)

