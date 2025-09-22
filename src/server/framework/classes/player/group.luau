local STORAGE_KEY = require(game.ReplicatedStorage.Shared.storage).group
local GROUPS_CONFIG = require(game.ReplicatedStorage.Shared.groups)
local PLAYER_DEFINITION = require(game.ReplicatedStorage.Shared.types["player.types"])
local storage = game:GetService("DataStoreService"):GetDataStore(STORAGE_KEY)
local isOnlinePlayer = require("../../utils/check-player-is-online")

local event = Instance.new("RemoteEvent")
event.Name = "framework:update.player.groups"
event.Parent = game.ReplicatedStorage


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
        print("➕ Tentando adicionar grupo:", group, "para", cache.player.Name)
        
        if not isValidGroup(group) then
            print("❌ Grupo inválido:", group)
            return false
        end

        local isAffiliated = isAlreadyAffiliated(cache.groups, group)

        if isAffiliated then
            print("🔄 Removendo grupo anterior:", isAffiliated)
            if not self.remove(isAffiliated) then
                print("❌ Erro ao remover grupo anterior")
                return false
            end
        end

        local groups = table.clone(cache.groups)
        groups[group] = true
        
        print("💾 Salvando grupos no DataStore:", game:GetService("HttpService"):JSONEncode(groups))

        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            print("❌ Erro ao salvar no DataStore")
            return false
        end
        
        print("✅ Dados salvos com sucesso no DataStore")
        cache.groups = groups

        if isOnlinePlayer(cache.player) then
            event:FireClient(cache.player, cache.groups)
        end

        return true
    end

    function self.remove(group: string)
        print("➖ Removendo grupo:", group, "de", cache.player.Name)
        
        local groups = table.clone(cache.groups)
        groups[group] = nil

        local success = pcall(function()
            return storage:SetAsync(cache.player.UserId, groups)
        end)

        if not success then
            print("❌ Erro ao remover do DataStore")
            return false
        end

        print("✅ Grupo removido com sucesso do DataStore")
        cache.groups = groups
        
        if isOnlinePlayer(cache.player) then
            event:FireClient(cache.player, cache.groups)
        end

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
