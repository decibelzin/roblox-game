local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupsData = require(script.Parent.GroupsDataStore)
local GroupPermissions = require(script.Parent.GroupPermissions)

-- Criar RemoteEvents
local GetPlayerGroups = Instance.new("RemoteEvent")
GetPlayerGroups.Name = "GetPlayerGroups"
GetPlayerGroups.Parent = ReplicatedStorage

local CheckPermission = Instance.new("RemoteFunction")
CheckPermission.Name = "CheckPermission"
CheckPermission.Parent = ReplicatedStorage

local GetGroupInfo = Instance.new("RemoteFunction")
GetGroupInfo.Name = "GetGroupInfo"
GetGroupInfo.Parent = ReplicatedStorage

-- Função para verificar permissões
function CheckPermission.OnServerInvoke(player, permission)
    local data = GroupsData.Get(player)
    
    -- Verificar se o player tem algum grupo que permite essa permissão
    for groupName, _ in pairs(data.groups) do
        if GroupPermissions[groupName] and GroupPermissions[groupName][permission] then
            return true
        end
    end
    
    return false
end

-- Função para obter grupos do player
GetPlayerGroups.OnServerEvent:Connect(function(player)
    local data = GroupsData.Get(player)
    GetPlayerGroups:FireClient(player, data.groups)
end)

-- Função para obter informações de um grupo específico
function GetGroupInfo.OnServerInvoke(player, groupName)
    -- Retornar apenas informações seguras para o cliente
    local Groups = require(game.ReplicatedStorage.Shared.groups)
    return Groups[groupName]
end

-- Função para obter todos os grupos disponíveis
local GetAllGroups = Instance.new("RemoteFunction")
GetAllGroups.Name = "GetAllGroups"
GetAllGroups.Parent = ReplicatedStorage

function GetAllGroups.OnServerInvoke(player)
    local Groups = require(game.ReplicatedStorage.Shared.groups)
    return Groups
end

print("GroupManager carregado com sucesso!")
