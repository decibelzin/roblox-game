-- Módulo de Playtime com Recompensas e Notificações (Corrigido)
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)

local PlaytimeModule = {}
local playtimeStorage = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.playtime)

-- Configurações
local SAVE_INTERVAL = 120 -- 2 minutos
local COINS_PER_30_MINUTES = 20 -- 20 moedas a cada 30 minutos
local COINS_CHECK_INTERVAL = 1800 -- 30 minutos em segundos
local MILESTONE_BONUS = {
    [60] = 10,    -- 1 hora = 10 moedas extras
    [300] = 50,   -- 5 horas = 50 moedas extras
    [600] = 100,  -- 10 horas = 100 moedas extras
    [1800] = 300, -- 30 horas = 300 moedas extras
    [3600] = 500  -- 60 horas = 500 moedas extras
}

-- Estado
local playerSessions = {}
local playerModule = nil
local playerClasses = {}
local coinNotificationEvent = nil

-- Inicializar módulo
function PlaytimeModule.init(module, classes)
    playerModule = module
    playerClasses = classes
    coinNotificationEvent = ReplicatedStorage:WaitForChild("CoinNotification")
end

-- Utilitários
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    return hours > 0 
        and string.format("%02d:%02d:%02d", hours, minutes, secs)
        or string.format("%02d:%02d", minutes, secs)
end

local function calculateCoinsEarned(sessionTime)
    -- Calcular quantos intervalos de 30 minutos foram completados
    local intervals = math.floor(sessionTime / COINS_CHECK_INTERVAL)
    return intervals * COINS_PER_30_MINUTES
end

local function sendCoinNotification(player, amount, reason)
    if coinNotificationEvent then
        coinNotificationEvent:FireClient(player, amount, reason)
    end
end

local function checkMilestones(totalTime, player)
    local totalMinutes = totalTime / 60
    local milestones = {}
    
    for minutes, bonus in pairs(MILESTONE_BONUS) do
        if totalMinutes >= minutes then
            table.insert(milestones, {minutes = minutes, bonus = bonus})
        end
    end
    
    -- Ordenar por tempo (maior primeiro)
    table.sort(milestones, function(a, b) return a.minutes > b.minutes end)
    
    -- Dar bônus apenas para o maior marco alcançado
    if #milestones > 0 then
        local milestone = milestones[1]
        local playerClass = playerClasses[player.UserId]
        
        if playerClass and playerClass.coins then
            local success = playerClass.coins.add(milestone.bonus)
            if success then
                -- Enviar notificação
                sendCoinNotification(player, milestone.bonus, string.format("Marco de %d minutos!", milestone.minutes))
            end
        end
    end
end

-- API Pública
function PlaytimeModule.startTracking(player)
    if playerSessions[player.UserId] then return end
    
    playerSessions[player.UserId] = {
        startTime = tick(),
        lastSave = tick(),
        lastCoinsCheck = 0
    }
end

function PlaytimeModule.stopTracking(player)
    local session = playerSessions[player.UserId]
    if not session then return end
    
    PlaytimeModule.saveTime(player)
    playerSessions[player.UserId] = nil
end

function PlaytimeModule.saveTime(player)
    local data = playerModule.get(player, false)
    local session = playerSessions[player.UserId]
    
    if not data or not session then return end
    
    local sessionTime = tick() - session.startTime
    local totalTime = (data.playtime or 0) + sessionTime
    
    -- Calcular moedas ganhas (apenas intervalos completos de 30 minutos)
    local coinsEarned = calculateCoinsEarned(sessionTime)
    
    -- Dar moedas ao jogador (apenas se ganhou moedas)
    local playerClass = playerClasses[player.UserId]
    if playerClass and playerClass.coins and coinsEarned > 0 then
        local success = playerClass.coins.add(coinsEarned)
        if success then
            -- Enviar notificação apenas se ganhou moedas
            sendCoinNotification(player, coinsEarned, "Tempo jogado (30min)")
        end
    end
    
    -- Verificar marcos
    checkMilestones(totalTime, player)
    
    -- Salvar no DataStore
    local success = pcall(function()
        playtimeStorage:SetAsync(player.UserId, totalTime)
    end)
    
    if success then
        data.playtime = totalTime
        session.lastSave = tick()
    end
end

function PlaytimeModule.getCurrentTime(player)
    local data = playerModule.get(player, false)
    local session = playerSessions[player.UserId]
    
    if not data then return 0, 0 end
    
    local totalTime = data.playtime or 0
    local sessionTime = session and (tick() - session.startTime) or 0
    
    return totalTime, sessionTime
end

function PlaytimeModule.formatTime(seconds)
    return formatTime(seconds)
end

function PlaytimeModule.getPlayerSessions()
    return playerSessions
end

function PlaytimeModule.getSaveInterval()
    return SAVE_INTERVAL
end

function PlaytimeModule.getCoinsPer30Minutes()
    return COINS_PER_30_MINUTES
end

function PlaytimeModule.getMilestones()
    return MILESTONE_BONUS
end

return PlaytimeModule
