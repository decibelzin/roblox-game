local Players = game:GetService("Players")
local Groups = require(game.ReplicatedStorage.Shared.groups)
local GroupsData = require(script.Parent.GroupsDataStore)
local GroupPermissions = require(script.Parent.GroupPermissions)

-- Função para verificar se player pode usar comando
local function canUseCommand(player, command)
    local data = GroupsData.Get(player)
    
    -- Verificar se o player tem algum grupo que permite esse comando
    for groupName, _ in pairs(data.groups) do
        if GroupPermissions[groupName] and GroupPermissions[groupName][command] then
            return true
        end
    end
    
    return false
end

-- Função para verificar se player pode gerenciar grupos
local function canManageGroups(player)
    return canUseCommand(player, "canManageGroups")
end

Players.PlayerAdded:Connect(function(player)
    local data = GroupsData.Load(player)
    print(player.Name .. " entrou com grupos:", data.groups)
end)

Players.PlayerRemoving:Connect(function(player)
    GroupsData.Save(player)
end)

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:sub(1, 7) == "/group " then
            if not canManageGroups(player) then
                print("Você não tem permissão para gerenciar grupos!")
                return
            end
            
            local group = message:sub(8)
            if Groups[group] then
                GroupsData.AddGroup(player, group)
                print("Grupo "..group.." adicionado para " .. player.Name)
            else
                print("Grupo '"..group.."' não existe para " .. player.Name)
            end
        elseif message:sub(1, 9) == "/ungroup " then
            if not canManageGroups(player) then
                print("Você não tem permissão para gerenciar grupos!")
                return
            end
            
            local group = message:sub(10)
            GroupsData.RemoveGroup(player, group)
            print("Grupo "..group.." removido de " .. player.Name)
        elseif message == "/groups" then
            local data = GroupsData.Load(player)
            local groupsList = table.concat(data.groups, ", ")
            print(player.Name .. " tem os grupos: " .. groupsList)
        elseif message == "/permissions" then
            local data = GroupsData.Load(player)
            local permissions = {}
            
            for groupName, _ in pairs(data.groups) do
                if GroupPermissions[groupName] then
                    for permission, _ in pairs(GroupPermissions[groupName]) do
                        table.insert(permissions, permission)
                    end
                end
            end
            
            local permissionsList = table.concat(permissions, ", ")
            print(player.Name .. " tem as permissões: " .. permissionsList)
        end
    end)
end)

print("Sistema de grupos carregado com validação de permissões!")
