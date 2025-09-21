local Players = game:GetService("Players")
local Groups = require(game.ReplicatedStorage.Shared.groups)
local GroupsData = require(script.Parent.GroupsDataStore)
local GroupPermissions = require(script.Parent.GroupPermissions)

-- Função para verificar se player pode usar comando
local function canUseCommand(player, command)
    -- Verificar permissões do Roblox primeiro
    if player.UserId == game.CreatorId then
        return true -- Owner do jogo sempre tem permissão
    end
    
    -- Verificar se é admin do grupo do jogo
    local success, isAdmin = pcall(function()
        return player:GetRankInGroup(game.CreatorId) >= 100
    end)
    
    if success and isAdmin then
        return true -- Admin do grupo sempre tem permissão
    end
    
    -- Verificar grupos personalizados
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

-- Função para encontrar player por username
local function findPlayer(username)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(username:lower(), 1, true) then
            return player
        end
    end
    return nil
end

-- Função para obter informações de permissão do player
local function getPlayerPermissionInfo(player)
    local info = {
        isOwner = false,
        isGroupAdmin = false,
        customGroups = {},
        allPermissions = {}
    }
    
    -- Verificar se é owner
    if player.UserId == game.CreatorId then
        info.isOwner = true
        return info
    end
    
    -- Verificar se é admin do grupo
    local success, rank = pcall(function()
        return player:GetRankInGroup(game.CreatorId)
    end)
    
    if success and rank >= 100 then
        info.isGroupAdmin = true
        return info
    end
    
    -- Verificar grupos personalizados
    local data = GroupsData.Get(player)
    for groupName, _ in pairs(data.groups) do
        table.insert(info.customGroups, groupName)
        if GroupPermissions[groupName] then
            for permission, _ in pairs(GroupPermissions[groupName]) do
                table.insert(info.allPermissions, permission)
            end
        end
    end
    
    return info
end

Players.PlayerAdded:Connect(function(player)
    local data = GroupsData.Load(player)
    local permInfo = getPlayerPermissionInfo(player)
    
    if permInfo.isOwner then
        print(player.Name .. " entrou como OWNER do jogo!")
    elseif permInfo.isGroupAdmin then
        print(player.Name .. " entrou como ADMIN do grupo!")
    else
        print(player.Name .. " entrou com grupos:", data.groups)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    GroupsData.Save(player)
end)

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local args = {}
        for word in message:gmatch("%S+") do
            table.insert(args, word)
        end
        
        if args[1] == "/group" then
            if not canManageGroups(player) then
                print("Você não tem permissão para gerenciar grupos!")
                return
            end
            
            if not args[2] or not args[3] then
                print("Uso: /group [username] [grupo]")
                print("Exemplo: /group Vitor Admin")
                return
            end
            
            local targetPlayer = findPlayer(args[2])
            if not targetPlayer then
                print("Player '" .. args[2] .. "' não encontrado!")
                return
            end
            
            local group = args[3]
            if Groups[group] then
                GroupsData.AddGroup(targetPlayer, group)
                print("Grupo " .. group .. " adicionado para " .. targetPlayer.Name)
                print(targetPlayer.Name .. " agora tem o grupo: " .. group)
            else
                print("Grupo '" .. group .. "' não existe!")
                print("Grupos disponíveis: Admin, Moderator, Vip")
            end
            
        elseif args[1] == "/ungroup" then
            if not canManageGroups(player) then
                print("Você não tem permissão para gerenciar grupos!")
                return
            end
            
            if not args[2] or not args[3] then
                print("Uso: /ungroup [username] [grupo]")
                print("Exemplo: /ungroup Vitor Admin")
                return
            end
            
            local targetPlayer = findPlayer(args[2])
            if not targetPlayer then
                print("Player '" .. args[2] .. "' não encontrado!")
                return
            end
            
            local group = args[3]
            GroupsData.RemoveGroup(targetPlayer, group)
            print("Grupo " .. group .. " removido de " .. targetPlayer.Name)
            
        elseif message == "/groups" then
            local data = GroupsData.Load(player)
            local permInfo = getPlayerPermissionInfo(player)
            
            if permInfo.isOwner then
                print(player.Name .. " é OWNER do jogo - tem todas as permissões!")
            elseif permInfo.isGroupAdmin then
                print(player.Name .. " é ADMIN do grupo - tem todas as permissões!")
            else
                local groupsList = table.concat(data.groups, ", ")
                print(player.Name .. " tem os grupos: " .. groupsList)
            end
            
        elseif args[1] == "/groups" and args[2] then
            -- Ver grupos de outro player
            if not canManageGroups(player) then
                print("Você não tem permissão para ver grupos de outros players!")
                return
            end
            
            local targetPlayer = findPlayer(args[2])
            if not targetPlayer then
                print("Player '" .. args[2] .. "' não encontrado!")
                return
            end
            
            local data = GroupsData.Load(targetPlayer)
            local permInfo = getPlayerPermissionInfo(targetPlayer)
            
            if permInfo.isOwner then
                print(targetPlayer.Name .. " é OWNER do jogo - tem todas as permissões!")
            elseif permInfo.isGroupAdmin then
                print(targetPlayer.Name .. " é ADMIN do grupo - tem todas as permissões!")
            else
                local groupsList = table.concat(data.groups, ", ")
                print(targetPlayer.Name .. " tem os grupos: " .. groupsList)
            end
            
        elseif message == "/permissions" then
            local permInfo = getPlayerPermissionInfo(player)
            
            if permInfo.isOwner then
                print(player.Name .. " é OWNER - tem TODAS as permissões!")
            elseif permInfo.isGroupAdmin then
                print(player.Name .. " é ADMIN do grupo - tem TODAS as permissões!")
            else
                local permissions = {}
                for groupName, _ in pairs(permInfo.customGroups) do
                    if GroupPermissions[groupName] then
                        for permission, _ in pairs(GroupPermissions[groupName]) do
                            table.insert(permissions, permission)
                        end
                    end
                end
                
                local permissionsList = table.concat(permissions, ", ")
                print(player.Name .. " tem as permissões: " .. permissionsList)
            end
            
        elseif args[1] == "/permissions" and args[2] then
            -- Ver permissões de outro player
            if not canManageGroups(player) then
                print("Você não tem permissão para ver permissões de outros players!")
                return
            end
            
            local targetPlayer = findPlayer(args[2])
            if not targetPlayer then
                print("Player '" .. args[2] .. "' não encontrado!")
                return
            end
            
            local permInfo = getPlayerPermissionInfo(targetPlayer)
            
            if permInfo.isOwner then
                print(targetPlayer.Name .. " é OWNER - tem TODAS as permissões!")
            elseif permInfo.isGroupAdmin then
                print(targetPlayer.Name .. " é ADMIN do grupo - tem TODAS as permissões!")
            else
                local permissions = {}
                for groupName, _ in pairs(permInfo.customGroups) do
                    if GroupPermissions[groupName] then
                        for permission, _ in pairs(GroupPermissions[groupName]) do
                            table.insert(permissions, permission)
                        end
                    end
                end
                
                local permissionsList = table.concat(permissions, ", ")
                print(targetPlayer.Name .. " tem as permissões: " .. permissionsList)
            end
        end
    end)
end)

print("Sistema de grupos carregado com validação de permissões do Roblox!")
