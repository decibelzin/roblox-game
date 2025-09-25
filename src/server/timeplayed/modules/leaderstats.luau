local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.timeplayed)

local LeaderstatsModule = {}

function LeaderstatsModule.new(dataStoreModule)
    local self = {
        _dataStoreModule = dataStoreModule,
        _useLeaderstats = Config.USE_LEADERSTATS,
        _nameLeaderstats = Config.NAME_LEADERSTATS,
        _doDebug = Config.DO_DEBUG
    }
    
    setmetatable(self, {__index = LeaderstatsModule})
    
    if self._useLeaderstats then
        self:_initializeLeaderstats()
    end
    
    return self
end

function LeaderstatsModule:_initializeLeaderstats()
    -- Criar leaderstats para jogadores já conectados
    for _, player in pairs(Players:GetPlayers()) do
        self:_createPlayerLeaderstats(player)
    end
    
    -- Criar leaderstats para novos jogadores
    Players.PlayerAdded:Connect(function(player)
        self:_createPlayerLeaderstats(player)
    end)
    
    if self._doDebug then
        print("LeaderstatsModule: Sistema de leaderstats inicializado")
    end
end

function LeaderstatsModule:_createPlayerLeaderstats(player)
    task.spawn(function()
        local stat = Instance.new("NumberValue")
        stat.Name = self._nameLeaderstats
        
        if self._doDebug then
            print("LeaderstatsModule: Procurando pasta leaderstats para", player.Name)
        end
        
        -- Aguardar ou criar pasta leaderstats
        local leaderstatsFolder = player:WaitForChild("leaderstats", 8)
        if not leaderstatsFolder then
            if self._doDebug then
                print("LeaderstatsModule: Criando pasta leaderstats para", player.Name)
            end
            leaderstatsFolder = Instance.new("Configuration")
            leaderstatsFolder.Name = "leaderstats"
            leaderstatsFolder.Parent = player
        end
        
        stat.Parent = leaderstatsFolder
        
        -- Carregar valor do DataStore
        if self._dataStoreModule and self._dataStoreModule:isEnabled() then
            local timeValue = self._dataStoreModule:getPlayerTime(player)
            stat.Value = timeValue
            
            if self._doDebug then
                print("LeaderstatsModule: Leaderstats criadas para", player.Name, "com valor", timeValue)
            end
        else
            stat.Value = 0
            if self._doDebug then
                print("LeaderstatsModule: DataStore não disponível, definindo valor 0 para", player.Name)
            end
        end
    end)
end

function LeaderstatsModule:updatePlayerLeaderstats(userId, minutes)
    if not self._useLeaderstats then
        return
    end
    
    local player = Players:GetPlayerByUserId(userId)
    if not player or not player:FindFirstChild("leaderstats") then
        return
    end
    
    local leaderstat = player.leaderstats:FindFirstChild(self._nameLeaderstats)
    if leaderstat then
        leaderstat.Value = tonumber(minutes) or 0
        
        if self._doDebug then
            print("LeaderstatsModule: Atualizado leaderstats de", player.Name, "para", minutes)
        end
    end
end

function LeaderstatsModule:isEnabled()
    return self._useLeaderstats
end

return LeaderstatsModule 