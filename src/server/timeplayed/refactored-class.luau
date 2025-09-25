--[[
  TimePlayedClass Refatorada - Sistema modular
  
  Sistema refatorado para melhor organização e manutenibilidade.
  Dividido em módulos especializados para cada responsabilidade.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.timeplayed)

-- Importar módulos especializados
local DataStoreModule = require(script.Parent.modules.datastore)
local LeaderboardModule = require(script.Parent.modules.leaderboard)
local LeaderstatsModule = require(script.Parent.modules.leaderstats)

local TimePlayedClass = {}
TimePlayedClass.__index = TimePlayedClass

function TimePlayedClass.new()
    local self = {
        _isMainScript = false,
        _dataStoreModule = nil,
        _leaderboardModule = nil,
        _leaderstatsModule = nil,
        _doDebug = Config.DO_DEBUG,
        _scoreUpdateDelay = Config.SCORE_UPDATE * 60,
        _boardUpdateDelay = Config.LEADERBOARD_UPDATE * 60
    }
    
    setmetatable(self, TimePlayedClass)
    
    self:_checkIsMainScript()
    self:_initialize()
    
    return self
end

function TimePlayedClass:_checkIsMainScript()
    local runningFlag = ServerStorage:FindFirstChild("TopTimePlayedLeaderboard_Running_Flag")
    
    if runningFlag then
        self._isMainScript = false
        if self._doDebug then
            print("TimePlayedClass: Executando como script secundário")
        end
    else
        self._isMainScript = true
        local boolValue = Instance.new("BoolValue", ServerStorage)
        boolValue.Name = "TopTimePlayedLeaderboard_Running_Flag"
        boolValue.Value = true
        
        if self._doDebug then
            print("TimePlayedClass: Executando como script principal")
        end
    end
end

function TimePlayedClass:_initialize()
    -- Inicializar módulo de DataStore
    self._dataStoreModule = DataStoreModule.new()
    
    -- Inicializar módulo de Leaderboard
    self._leaderboardModule = LeaderboardModule.new()
    
    -- Se DataStore não estiver disponível, mostrar aviso e parar
    if not self._dataStoreModule:isEnabled() then
        self._leaderboardModule:showNoAPIWarning()
        if self._doDebug then
            warn("TimePlayedClass: DataStore não disponível, sistema desabilitado")
        end
        return
    end
    
    -- Inicializar módulo de Leaderstats
    self._leaderstatsModule = LeaderstatsModule.new(self._dataStoreModule)
    
    -- Iniciar loops de atualização apenas no script principal
    if self._isMainScript then
        self:_startUpdateLoops()
    end
    
    if self._doDebug then
        print("TimePlayedClass: Sistema inicializado com sucesso")
    end
end

function TimePlayedClass:_startUpdateLoops()
    -- Loop de atualização de pontuação (incrementar tempo dos jogadores)
    task.spawn(function()
        while true do
            task.wait(self._scoreUpdateDelay)
            self:_updatePlayerScores()
        end
    end)
    
    -- Loop de atualização do leaderboard
    task.spawn(function()
        self:_updateLeaderboard() -- Atualizar uma vez imediatamente
        
        local countdown = self._boardUpdateDelay
        while true do
            task.wait(1)
            countdown = countdown - 1
            
            if countdown <= 0 then
                self:_updateLeaderboard()
                countdown = self._boardUpdateDelay
            end
        end
    end)
    
    if self._doDebug then
        print("TimePlayedClass: Loops de atualização iniciados")
    end
end

function TimePlayedClass:_updatePlayerScores()
    local players = Players:GetPlayers()
    
    for _, player in pairs(players) do
        local success, newValue = self._dataStoreModule:incrementPlayerTime(
            player, 
            self._scoreUpdateDelay / 60
        )
        
        if success and self._leaderstatsModule:isEnabled() then
            self._leaderstatsModule:updatePlayerLeaderstats(player.UserId, newValue)
        end
    end
    
    if self._doDebug then
        print("TimePlayedClass: Pontuações atualizadas para", #players, "jogadores")
    end
end

function TimePlayedClass:_updateLeaderboard()
    local topPlayers = self._dataStoreModule:getTopPlayers(10)
    
    self._leaderboardModule:updateBoard(topPlayers)
    
    -- Atualizar leaderstats para jogadores no top 10
    if self._leaderstatsModule:isEnabled() then
        for _, playerData in pairs(topPlayers) do
            local userId = tonumber(string.split(playerData.key, Config.NAME_OF_STAT)[2])
            if userId and userId > 0 then
                self._leaderstatsModule:updatePlayerLeaderstats(userId, playerData.value)
            end
        end
    end
    
    if self._doDebug then
        print("TimePlayedClass: Leaderboard atualizado com", #topPlayers, "jogadores")
    end
end

-- Função para obter estatísticas do sistema (útil para debugging/admin)
function TimePlayedClass:getSystemStats()
    return {
        isMainScript = self._isMainScript,
        dataStoreEnabled = self._dataStoreModule and self._dataStoreModule:isEnabled() or false,
        leaderstatsEnabled = self._leaderstatsModule and self._leaderstatsModule:isEnabled() or false,
        scoreUpdateDelay = self._scoreUpdateDelay,
        boardUpdateDelay = self._boardUpdateDelay,
        debugEnabled = self._doDebug
    }
end

-- Função para forçar atualização manual (útil para testes)
function TimePlayedClass:forceUpdate()
    if self._isMainScript then
        self:_updatePlayerScores()
        self:_updateLeaderboard()
        
        if self._doDebug then
            print("TimePlayedClass: Atualização manual executada")
        end
    else
        warn("TimePlayedClass: Apenas o script principal pode forçar atualizações")
    end
end

return TimePlayedClass 