local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).group
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local storage = game:GetService("DataStoreService"):GetDataStore(STORAGE_KEY)
local isOnlinePlayer = require("../../utils/check-player-is-online")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Evento para atualização individual de grupos
local event = Instance.new("RemoteEvent")
event.Name = "framework:update.player.groups"
event.Parent = ReplicatedStorage

--- Valida se uma string é segura para o DataStore
local function isValidString(str: string): boolean
    if type(str) ~= "string" or #str == 0 or #str > 50 then
        return false
    end
    
    -- Verificar UTF-8 válido
    if utf8.len(str) == nil then
        return false
    end
    
    return true
end

--- Valida se os dados dos grupos são seguros
local function validateGroupsData(groups: {[string]: boolean}): boolean
    if type(groups) ~= "table" then
        return false
    end
    
    for groupName, hasGroup in pairs(groups) do
        if not isValidString(groupName) or type(hasGroup) ~= "boolean" or not GROUPS_CONFIG[groupName] then
            return false
        end
    end
    
    return true
end

--- Verifica se um grupo é válido
local function isValidGroup(group: string): boolean
    return isValidString(group) and GROUPS_CONFIG[group] ~= nil
end

--- Verifica se o player possui um grupo da mesma organização
local function isAlreadyAffiliated(userGroups: {[string]: boolean}, group: string): string | false
    local detail: GROUPS_CONFIG.DefGroup = GROUPS_CONFIG[group]
    
    if not detail or not detail.organization then
        return false
    end
    
    for currentGroup, _ in pairs(userGroups) do
        local currentData: GROUPS_CONFIG.DefGroup = GROUPS_CONFIG[currentGroup]
        if currentData and currentData.organization and currentData.organization == detail.organization then
            return currentGroup
        end
    end

    return false
end

--- Função para obter o grupo mais alto de um jogador baseado na prioridade
local function getHighestGroup(playerGroups: {[string]: boolean})
    if not playerGroups or type(playerGroups) ~= "table" then
        return nil
    end
    
    local highestGroup = nil
    local highestPriority = 0
    
    for groupName, hasGroup in pairs(playerGroups) do
        if hasGroup then
            local groupData = GROUPS_CONFIG[groupName]
            if groupData and groupData.priority and groupData.priority > highestPriority then
                highestPriority = groupData.priority
                highestGroup = groupName
            end
        end
    end
    
    return highestGroup
end

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

return function(cache: PLAYER_DEFINITION.DefPlayerSchema)
    local self = {}

    function self.add(group: string)
        if not isValidGroup(group) then
            return false
        end

        local isAffiliated = isAlreadyAffiliated(cache.groups, group)

        if isAffiliated then
            if not self.remove(isAffiliated) then
                return false
            end
        end

        local groups = table.clone(cache.groups)
        groups[group] = true
        
        -- Validar antes de salvar
        if not validateGroupsData(groups) then
            return false
        end
        
        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            return false
        end
        
        cache.groups = groups

        if isOnlinePlayer(cache.player) then
            event:FireClient(cache.player, cache.groups)
        end

        return true
    end

    function self.remove(group: string)
        if not isValidString(group) then
            return false
        end
        
        local groups = table.clone(cache.groups)
        groups[group] = nil

        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            return false
        end

        cache.groups = groups
        
        if isOnlinePlayer(cache.player) then
            event:FireClient(cache.player, cache.groups)
        end

        return true
    end

    function self.checkOne(group: string): boolean
        if not isValidString(group) then
            return false
        end
        
        return cache.groups[group] == true
    end

    function self.checkMany(groups: {string}): boolean
        if type(groups) ~= "table" then
            return false
        end
        
        for _, group in groups do
            if self.checkOne(group) then
                return true
            end
        end
        return false
    end

    function self.getHighestGroup(): string?
        return getHighestGroup(cache.groups)
    end

    function self.list(): {string}
        return listPlayerGroups(cache.groups)
    end

    return self
end