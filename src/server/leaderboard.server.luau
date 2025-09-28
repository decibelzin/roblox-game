-- Sistema de Leaderboard
local players = game:GetService("Players")

-- Importar módulos necessários
local PlayerModule = require(game.ServerScriptService.Server.framework.modules.player)()

-- Função para criar/atualizar leaderboard do jogador
local function setupPlayerLeaderboard(player)
    -- Aguardar o PlayerGui carregar
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Criar ou obter leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- Verificar se a coluna User ID já existe
    local userIdValue = leaderstats:FindFirstChild("ID")
    if not userIdValue then
        -- Criar a coluna User ID
        userIdValue = Instance.new("IntValue")
        userIdValue.Name = "ID"
        userIdValue.Value = 0
        userIdValue.Parent = leaderstats
    end
    
    -- Verificar se a coluna Group já existe
    local groupValue = leaderstats:FindFirstChild("Group")
    if not groupValue then
        -- Criar a coluna Group
        groupValue = Instance.new("StringValue")
        groupValue.Name = "Group"
        groupValue.Value = "None"
        groupValue.Parent = leaderstats
    end
    
    -- Verificar se a coluna Time já existe
    local timePlayedValue = leaderstats:FindFirstChild("Time")
    if not timePlayedValue then
        -- Criar a coluna Time
        timePlayedValue = Instance.new("StringValue")
        timePlayedValue.Name = "Time"
        timePlayedValue.Value = "0h 0m"
        timePlayedValue.Parent = leaderstats
    end
    
    -- Função para atualizar os valores
    local function updateLeaderboard()
        -- Obter dados do jogador
        local playerData, playerClass = PlayerModule.get(player, false)
        if not playerData then return end
        
        -- Atualizar User ID (garantir que seja um número válido)
        local userId = playerData.userId
        if type(userId) == "number" and userId > 0 then
            userIdValue.Value = userId
        else
            userIdValue.Value = 0
            if userId ~= 0 then
                warn("⚠️ User ID inválido para jogador:", player.Name, "- Valor:", userId)
            end
        end
        
        -- Atualizar grupo
        local highestGroup = playerClass.group.getHighestGroup()
        groupValue.Value = highestGroup or ''
        
        -- Atualizar tempo jogado
        if _G.GetPlayerTimePlayed then
            local playerTime = _G.GetPlayerTimePlayed(player)
            if playerTime then
                -- Formato para o leaderboard: "2h 30m" ou "45m"
                if playerTime.totalHours >= 1 then
                    timePlayedValue.Value = string.format("%dh %dm", playerTime.hours, playerTime.minutes)
                else
                    timePlayedValue.Value = string.format("%dm", playerTime.totalMinutes)
                end
            else
                timePlayedValue.Value = "0m"
            end
        else
            timePlayedValue.Value = "0m"
        end
    end

    updateLeaderboard()
    
    -- Atualizar tempo jogado periodicamente
    task.spawn(function()
        while player.Parent do
            wait(60) -- Atualizar a cada 1 minuto
            if player.Parent and _G.GetPlayerTimePlayed then
                local playerTime = _G.GetPlayerTimePlayed(player)
                if playerTime and timePlayedValue.Parent then
                    if playerTime.totalHours >= 1 then
                        timePlayedValue.Value = string.format("%dh %dm", playerTime.hours, playerTime.minutes)
                    else
                        timePlayedValue.Value = string.format("%dm", playerTime.totalMinutes)
                    end
                end
            end
        end
    end)
end

-- Eventos
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Aguardar o character carregar completamente
        
        -- Configurar leaderboard com colunas ID e Group
        setupPlayerLeaderboard(player)
    end)
end) 