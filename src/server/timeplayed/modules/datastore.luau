local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.timeplayed)

local DataStoreModule = {}

function DataStoreModule.new()
    local self = {
        _datastore = nil,
        _apiServicesEnabled = false,
        _doDebug = Config.DO_DEBUG
    }
    
    setmetatable(self, {__index = DataStoreModule})
    
    self:_checkDataStoreAccess()
    if self._apiServicesEnabled then
        self:_initializeDataStore()
    end
    
    return self
end

function DataStoreModule:_checkDataStoreAccess()
    local status, message = pcall(function()
        DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
    end)
    
    if status == false and
        (string.find(message, "404", 1, true) ~= nil or 
         string.find(message, "403", 1, true) ~= nil or
         string.find(message, "must publish", 1, true) ~= nil) then
        
        local boolValue = Instance.new("BoolValue", ServerStorage)
        boolValue.Value = false
        boolValue.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
        self._apiServicesEnabled = false
        
        if self._doDebug then
            warn("TimePlayedDataStore: API Services não disponíveis")
        end
        return
    end
    
    self._apiServicesEnabled = true
    local boolValue = Instance.new("BoolValue", ServerStorage)
    boolValue.Value = true
    boolValue.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
    
    if self._doDebug then
        print("TimePlayedDataStore: API Services disponíveis")
    end
end

function DataStoreModule:_initializeDataStore()
    local success, result = pcall(function()
        return DataStoreService:GetOrderedDataStore(Config.DATA_STORE)
    end)
    
    if success and result then
        self._datastore = result
        if self._doDebug then
            print("TimePlayedDataStore: OrderedDataStore inicializado")
        end
    else
        warn("TimePlayedDataStore: Falha ao carregar OrderedDataStore. Erro:", result)
    end
end

function DataStoreModule:isEnabled()
    return self._apiServicesEnabled and self._datastore ~= nil
end

function DataStoreModule:incrementPlayerTime(player, minutes)
    if not self:isEnabled() then
        return false, "DataStore não disponível"
    end
    
    local stat = Config.NAME_OF_STAT .. player.UserId
    local success, newValue = pcall(function()
        return self._datastore:IncrementAsync(stat, minutes)
    end)
    
    if success then
        if self._doDebug then
            print("TimePlayedDataStore: Incrementado tempo de", player.Name, "para", newValue, "minutos")
        end
        return true, newValue
    else
        warn("TimePlayedDataStore: Erro ao incrementar tempo de", player.Name, ":", newValue)
        return false, newValue
    end
end

function DataStoreModule:getPlayerTime(player)
    if not self:isEnabled() then
        return 0
    end
    
    local stat = Config.NAME_OF_STAT .. player.UserId
    local success, result = pcall(function()
        return self._datastore:GetAsync(stat)
    end)
    
    return success and result or 0
end

function DataStoreModule:getTopPlayers(count)
    if not self:isEnabled() then
        return {}
    end
    
    local success, results = pcall(function()
        return self._datastore:GetSortedAsync(false, count or 10, 1):GetCurrentPage()
    end)
    
    if success and results then
        return results
    else
        if self._doDebug then
            warn("TimePlayedDataStore: Erro ao obter top players:", results)
        end
        return {}
    end
end

return DataStoreModule 