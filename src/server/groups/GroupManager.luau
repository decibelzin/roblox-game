local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupsData = require(script.Parent.GroupsDataStore)
local GroupPermissions = require(script.Parent.GroupPermissions)

-- Função para verificar permissões do Roblox
local function hasRobloxPermission(player, permission)
    -- Owner sempre tem permissão
    if player.UserId == game.CreatorId then
        return true
    end
    
    -- Verificar se é admin do grupo do jogo
    local success, rank = pcall(function()
        return player:GetRankInGroup(game.CreatorId)
    end)
    
    if success and rank >= 100 then
        return true
    end
    
    return false
end

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
    -- Verificar permissões do Roblox primeiro
    if hasRobloxPermission(player, permission) then
        return true
    end
    
    -- Verificar grupos personalizados
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
    local groups = {}
    
    -- Adicionar grupos do Roblox se aplicável
    if player.UserId == game.CreatorId then
        groups["Owner"] = true
    else
        local success, rank = pcall(function()
            return player:GetRankInGroup(game.CreatorId)
        end)
        
        if success and rank >= 100 then
            groups["GroupAdmin"] = true
        end
    end
    
    -- Adicionar grupos personalizados
    for groupName, _ in pairs(data.groups) do
        groups[groupName] = true
    end
    
    GetPlayerGroups:FireClient(player, groups)
end)

-- Função para obter informações de um grupo específico
function GetGroupInfo.OnServerInvoke(player, groupName)
    -- Retornar apenas informações seguras para o cliente
    local Groups = require(game.ReplicatedStorage.Shared.groups)
    
    -- Adicionar grupos especiais do Roblox
    if groupName == "Owner" then
        return {
            displayName = "Owner",
            color = Color3.fromRGB(255, 215, 0), -- Dourado
            priority = 5
        }
    elseif groupName == "GroupAdmin" then
        return {
            displayName = "Admin do Grupo",
            color = Color3.fromRGB(255, 165, 0), -- Laranja
            priority = 4
        }
    end
    
    return Groups[groupName]
end

-- Função para obter todos os grupos disponíveis
local GetAllGroups = Instance.new("RemoteFunction")
GetAllGroups.Name = "GetAllGroups"
GetAllGroups.Parent = ReplicatedStorage

function GetAllGroups.OnServerInvoke(player)
    local Groups = require(game.ReplicatedStorage.Shared.groups)
    local allGroups = {}
    
    -- Adicionar grupos especiais do Roblox
    allGroups["Owner"] = {
        displayName = "Owner",
        color = Color3.fromRGB(255, 215, 0),
        priority = 5
    }
    
    allGroups["GroupAdmin"] = {
        displayName = "Admin do Grupo",
        color = Color3.fromRGB(255, 165, 0),
        priority = 4
    }
    
    -- Adicionar grupos personalizados
    for groupName, info in pairs(Groups) do
        allGroups[groupName] = info
    end
    
    return allGroups
end

print("GroupManager carregado com sucesso!")
