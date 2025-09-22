-- Comando Teste de Notificação
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYER_MODULE = require(game.ServerScriptService.Server.framework.modules.player)

-- Cache
local cache = { player = {} }
local playerModule = PLAYER_MODULE(cache.player)

-- Aguardar RemoteEvents
local chatMessageEvent = ReplicatedStorage:WaitForChild("ChatMessageEvent")
local coinNotificationEvent = ReplicatedStorage:WaitForChild("CoinNotification")

local function testNotificationCommand(player, params)
    local amount = tonumber(params[1]) or 10
    local reason = table.concat(params, " ", 2) or "Teste"
    
    -- Dar moedas ao jogador
    local data, playerClass = playerModule.get(player, true)
    if playerClass and playerClass.coins then
        local success = playerClass.coins.add(amount)
        if success then
            -- Enviar notificação
            coinNotificationEvent:FireClient(player, amount, reason)
            
            -- Confirmar no chat
            chatMessageEvent:FireClient(player, string.format("✅ Teste: +%d moedas (%s)", amount, reason))
        else
            chatMessageEvent:FireClient(player, "❌ Erro ao adicionar moedas")
        end
    else
        chatMessageEvent:FireClient(player, "❌ Erro ao carregar dados do jogador")
    end
end

local registerCommand = require(ReplicatedStorage.Shared["register-command"])
registerCommand({
    name = "testcoin",
    description = "Testar notificação de moedas",
    aliases = {"testmoeda", "testnotification"}
}, testNotificationCommand)

