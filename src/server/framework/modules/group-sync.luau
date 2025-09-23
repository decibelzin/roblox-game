-- Módulo de Sincronização de Grupos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)

-- Evento para sincronização de grupos
local groupSyncEvent = Instance.new("RemoteEvent")
groupSyncEvent.Name = "GroupSyncEvent"
groupSyncEvent.Parent = ReplicatedStorage

--- Função para listar todos os grupos de um jogador
local function listPlayerGroups(playerGroups: {[string]: boolean})
    if not playerGroups or type(playerGroups) ~= "table" then
        return {}
    end
    
    local groups = {}
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup then
            table.insert(groups, groupName)
        end
    end
    return groups
end

local GroupSync = {}

--- Sincroniza grupos de um jogador específico
function GroupSync.syncPlayerGroups(player: Player, playerClass: PlayerClass, playerGroups: {[string]: boolean})
    local highestGroup = playerClass.group.getHighestGroup()
    local allGroups = listPlayerGroups(playerGroups)

    print("highestGroup", highestGroup)
    
    groupSyncEvent:FireClient(player, player.Name, highestGroup, allGroups)
end

--- Sincroniza grupos de todos os jogadores
function GroupSync.syncAllPlayerGroups(playerModule)
    for _, player in pairs(Players:GetPlayers()) do
        local playerData, playerClass = playerModule.get(player, false)
        if playerData then
            GroupSync.syncPlayerGroups(player, playerClass, playerData.groups)
        end
    end
end

return GroupSync 