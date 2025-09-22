-- Comando Playtime Ranking
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYTIME_MODULE = require(game.ServerScriptService.Server.framework.modules.playtime)

local function rankingCommand(player, params)
    local players = {}
    
    for _, p in pairs(Players:GetPlayers()) do
        local total, session = PLAYTIME_MODULE.getCurrentTime(p)
        table.insert(players, {
            name = p.Name,
            time = total + session
        })
    end
    
    table.sort(players, function(a, b) return a.time > b.time end)
    
    print("🏆 Ranking:")
    for i = 1, math.min(10, #players) do
        local p = players[i]
        print(string.format("   %d. %s - %s", i, p.name, PLAYTIME_MODULE.formatTime(p.time)))
    end
end

local registerCommand = require(ReplicatedStorage.Shared["register-command"])
registerCommand({
    name = "playtimerank",
    description = "Ranking de tempo",
    aliases = {"ptr", "ranking"}
}, rankingCommand)

