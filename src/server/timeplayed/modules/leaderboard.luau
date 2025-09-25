local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.timeplayed)

local LeaderboardModule = {}

function LeaderboardModule.new()
    local self = {
        _scoreBlock = workspace.TimePlayedLeaderboard.ScoreBlock,
        _doDebug = Config.DO_DEBUG,
        _show1stPlaceAvatar = Config.SHOW_1ST_PLACE_AVATAR,
        _dancingRigModule = nil,
        _usernameCache = {},
        _thumbnailCache = {}
    }
    
    setmetatable(self, {__index = LeaderboardModule})
    
    self:_initializeDancingRig()
    
    return self
end

function LeaderboardModule:_initializeDancingRig()
    if not self._show1stPlaceAvatar then
        local rigFolder = workspace.TimePlayedLeaderboard:FindFirstChild("First Place Avatar")
        if rigFolder then
            rigFolder:Destroy()
        end
        return
    end
    
    local rigFolder = workspace.TimePlayedLeaderboard:FindFirstChild("First Place Avatar")
    if not rigFolder then return end
    
    local rig = rigFolder:FindFirstChild("Rig")
    local rigModule = game.ServerScriptService.Server.timeplayed.animation
    
    if rig and rigModule then
        local success, module = pcall(function()
            return require(rigModule)
        end)
        
        if success then
            self._dancingRigModule = module
            if self._doDebug then
                print("LeaderboardModule: Dancing rig inicializado")
            end
        end
    end
end

function LeaderboardModule:clearBoard()
    local folders = {
        self._scoreBlock.Leaderboard.Names,
        self._scoreBlock.Leaderboard.Photos,
        self._scoreBlock.Leaderboard.Score
    }
    
    for _, folder in pairs(folders) do
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("GuiObject") then
                item.Visible = false
            end
        end
    end
end

function LeaderboardModule:updateBoard(topPlayers)
    if self._doDebug then
        print("LeaderboardModule: Atualizando leaderboard")
    end
    
    local sufgui = self._scoreBlock.Leaderboard
    self._scoreBlock.Credits.Enabled = true
    self._scoreBlock.Leaderboard.Enabled = #topPlayers > 0
    self._scoreBlock.NoDataFound.Enabled = #topPlayers == 0
    
    self:clearBoard()
    
    for position, playerData in pairs(topPlayers) do
        self:_updatePlayerEntry(position, playerData)
    end
    
    -- Criar backside do leaderboard
    if self._scoreBlock:FindFirstChild("_backside") then
        self._scoreBlock["_backside"]:Destroy()
    end
    
    local backside = self._scoreBlock.Leaderboard:Clone()
    backside.Parent = self._scoreBlock
    backside.Name = "_backside"
    backside.Face = Enum.NormalId.Back
    
    if self._doDebug then
        print("LeaderboardModule: Leaderboard atualizado com sucesso")
    end
end

function LeaderboardModule:_updatePlayerEntry(position, playerData)
    local userId = tonumber(string.split(playerData.key, Config.NAME_OF_STAT)[2])
    local name, thumbnail
    
    if not userId or userId <= 0 then
        name = "Studio Test Profile"
        thumbnail = "rbxassetid://11569282129"
    else
        name = self:_getUsernameAsync(userId)
        thumbnail = self:_getThumbnailAsync(userId)
    end
    
    local timeString = self:_formatTime(playerData.value)
    
    local sufgui = self._scoreBlock.Leaderboard
    sufgui.Names["Name"..position].Visible = true
    sufgui.Score["Score"..position].Visible = true
    sufgui.Photos["Photo"..position].Visible = true
    sufgui.Names["Name"..position].Text = name
    sufgui.Score["Score"..position].Text = timeString
    sufgui.Photos["Photo"..position].Image = thumbnail
    
    -- Atualizar avatar do primeiro lugar
    if position == 1 and self._dancingRigModule then
        self:_updateFirstPlaceAvatar(userId)
    end
end

function LeaderboardModule:_updateFirstPlaceAvatar(userId)
    task.spawn(function()
        local rigFolder = workspace.TimePlayedLeaderboard:FindFirstChild("First Place Avatar")
        if not rigFolder then return end
        
        local rig = rigFolder:FindFirstChild("Rig")
        if not rig then return end
        
        local humanoid = rig:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Salvar escalas atuais
        local savedScales = {}
        local scaleNames = {"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}
        
        for _, scaleName in pairs(scaleNames) do
            local scaleObject = humanoid:FindFirstChild(scaleName)
            if scaleObject and scaleObject:IsA("NumberValue") then
                savedScales[scaleName] = scaleObject.Value
            end
        end
        
        -- Aplicar aparência do jogador
        self._dancingRigModule.SetRigHumanoidDescription(userId > 0 and userId or 1)
        
        -- Aguardar e reaplicar escalas
        task.wait(1)
        
        for scaleName, scaleValue in pairs(savedScales) do
            local scaleObject = humanoid:FindFirstChild(scaleName)
            if scaleObject and scaleObject:IsA("NumberValue") then
                scaleObject.Value = scaleValue
            else
                local newScale = Instance.new("NumberValue")
                newScale.Name = scaleName
                newScale.Value = scaleValue
                newScale.Parent = humanoid
            end
        end
        
        humanoid:BuildRigFromAttachments()
        
        if self._doDebug then
            print("LeaderboardModule: Avatar do primeiro lugar atualizado")
        end
    end)
end

function LeaderboardModule:_getUsernameAsync(userId)
    if self._usernameCache[userId] then
        return self._usernameCache[userId]
    end
    
    local success, result = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)
    
    if success then
        self._usernameCache[userId] = result
        return result
    else
        if self._doDebug then
            warn("LeaderboardModule: Erro ao obter username para", userId, ":", result)
        end
        return "Name not found"
    end
end

function LeaderboardModule:_getThumbnailAsync(userId)
    if self._thumbnailCache[userId] then
        return self._thumbnailCache[userId]
    end
    
    local success, result = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId, 
            Enum.ThumbnailType.HeadShot, 
            Enum.ThumbnailSize.Size150x150
        )
    end)
    
    if success then
        self._thumbnailCache[userId] = result
        return result
    else
        if self._doDebug then
            warn("LeaderboardModule: Erro ao obter thumbnail para", userId, ":", result)
        end
        return "rbxassetid://5107154082"
    end
end

function LeaderboardModule:_formatTime(minutes)
    local totalSeconds = minutes * 60
    local days = math.floor(totalSeconds / 86400)
    local hours = math.floor(math.fmod(totalSeconds, 86400) / 3600)
    local mins = math.floor(math.fmod(totalSeconds, 3600) / 60)
    
    return string.format("%02dd : %02dh : %02dm", days, hours, mins)
end

function LeaderboardModule:showNoAPIWarning()
    self:clearBoard()
    self._scoreBlock.NoAPIServices.Warning.Visible = true
end

return LeaderboardModule 