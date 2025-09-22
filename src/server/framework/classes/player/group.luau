local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).group
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local storage = game:GetService("DataStoreService"):GetDataStore(STORAGE_KEY)
local isOnlinePlayer = require('../../utils/check-player-is-online')

--- isso aqui verifica se um grupo é valido
local function isValidGroup(group: string)
    return GROUPS_CONFIG[group] ~= nil
end

--- isso aqui verifica se o player possui um grupo da mesma organização
local function isAlreadyAffiliated(userGroups: {[string]: boolean}, group: string)
    local detail: GROUPS_CONFIG.DefGroup = GROUPS_CONFIG[group]
    
    for currentGroup in userGroups do
        local currentData: GROUPS_CONFIG.DefGroup = GROUPS_CONFIG[currentGroup]

        if not currentData then
            continue
        end

        if detail and detail.organization and currentData.organization == detail.organization then
            return currentGroup
        end
    end

    return false
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

        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            return false
        end
        
        cache.groups = groups
        return true
    end

    function self.remove(group: string)
        local groups = table.clone(cache.groups)
        groups[group] = nil

        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            return false
        end

        cache.groups = groups
        return true
    end

    function self.checkOne(group: string)
        return cache.groups[group] ~= nil
    end

    function self.checkMany(groups: {string})
        for _, group in groups do
            if self.checkOne(group) then
                return true
            end
        end
        return false
    end

    return self
end