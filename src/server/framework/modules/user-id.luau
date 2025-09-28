local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local DataStoreService = game:GetService("DataStoreService")

local userIdDataStore = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.userId)
local counterDataStore = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.userIdCounter)

local COUNTER_KEY = "nextUserId"

-- Cache simples para IDs em uso
local usedIdsCache = {}
local cacheInitialized = false

local UserIdModule = {}

--- Obtém o nome de usuário usando a API REST do Roblox
function UserIdModule.getUsername(robloxUserId: number): string?
    if not robloxUserId or robloxUserId <= 0 then
        return nil
    end
    
    -- Tentativa 1: API REST do Roblox
    local httpSuccess, httpResult = pcall(function()
        local HttpService = game:GetService("HttpService")
        local url = "https://users.roblox.com/v1/users/" .. robloxUserId
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        return data.name
    end)
    
    if httpSuccess and httpResult and httpResult ~= "" then
        return httpResult
    end
    
    -- Tentativa 2: API interna como fallback
    local apiSuccess, apiResult = pcall(function()
        return game:GetService("Players"):GetNameFromUserIdAsync(robloxUserId)
    end)
    
    if apiSuccess and apiResult and apiResult ~= "" then
        return apiResult
    end
    
    return nil
end

--- Inicializa o cache usando o contador como base
local function initializeUsedIdsCache()
    if cacheInitialized then
        return
    end
    
    print("🔄 Inicializando cache de User IDs...")
    
    -- Obter o contador atual para saber quais IDs já foram usados
    local currentCounter = UserIdModule.getCurrentCounter() or 0
    print("📊 Contador atual:", currentCounter, "- IDs 1 a", currentCounter, "estão em uso")
    
    cacheInitialized = true
    print("✅ Cache inicializado baseado no contador")
end

--- Obtém o próximo ID disponível e incrementa o contador de forma atômica
local function getNextUserId()
    local success, nextId = pcall(function()
        return counterDataStore:UpdateAsync(COUNTER_KEY, function(currentValue)
            -- Se não existe contador, começar do ID 1
            local current = currentValue or 0
            return current + 1
        end)
    end)
    
    if not success or not nextId then
        warn("❌ Erro ao obter/atualizar contador de User ID")
        return nil
    end
    
    return nextId
end

--- Obtém ou cria um User ID para um jogador
function UserIdModule.getOrCreateUserId(player: Player): number?
    -- Inicializar cache se necessário
    initializeUsedIdsCache()
    
    -- Validar se o player é válido
    if not player or not player.UserId then
        warn("❌ Player inválido fornecido para getOrCreateUserId")
        return nil
    end
    
    local robloxUserId = player.UserId
    
    -- Primeiro, verificar se o jogador já tem um ID
    local success, existingId = pcall(function()
        return userIdDataStore:GetAsync(tostring(robloxUserId))
    end)
    
    if success and existingId and type(existingId) == "number" and existingId > 0 then
        -- Jogador já tem um ID válido, retornar o existente
        return existingId
    end
    
    -- Jogador não tem ID ou ID é inválido, criar um novo
    local newId = getNextUserId()
    if not newId then
        warn("❌ Falha ao gerar novo User ID para jogador:", player.Name)
        return nil
    end
    
    -- Salvar o novo ID no DataStore
    local saveSuccess = pcall(function()
        userIdDataStore:SetAsync(tostring(robloxUserId), newId)
    end)
    
    if not saveSuccess then
        warn("❌ Erro ao salvar User ID para jogador:", player.Name)
        return nil
    end
    
    -- Atualizar cache
    usedIdsCache[newId] = true
    
    print("✅ Novo User ID criado para", player.Name, "- ID:", newId)
    return newId
end

--- Obtém o User ID de um jogador (sem criar um novo)
function UserIdModule.getUserId(player: Player): number?
    if not player or not player.UserId then
        warn("❌ Player inválido fornecido para getUserId")
        return nil
    end
    
    local robloxUserId = player.UserId
    
    local success, userId = pcall(function()
        return userIdDataStore:GetAsync(tostring(robloxUserId))
    end)
    
    if success and userId and type(userId) == "number" and userId > 0 then
        return userId
    end
    
    return nil
end

--- Obtém o User ID por Roblox User ID (para jogadores offline)
function UserIdModule.getUserIdByRobloxId(robloxUserId: number): number?
    if not robloxUserId or type(robloxUserId) ~= "number" or robloxUserId <= 0 then
        warn("❌ Roblox User ID inválido fornecido:", robloxUserId)
        return nil
    end
    
    local success, userId = pcall(function()
        return userIdDataStore:GetAsync(tostring(robloxUserId))
    end)
    
    if success and userId and type(userId) == "number" and userId > 0 then
        return userId
    end
    
    return nil
end

--- Obtém o contador atual (para debugging/admin)
function UserIdModule.getCurrentCounter(): number?
    local success, counter = pcall(function()
        return counterDataStore:GetAsync(COUNTER_KEY)
    end)
    
    if success then
        return counter or 0
    end
    
    return nil
end

--- Função de diagnóstico para verificar a integridade do sistema
function UserIdModule.runDiagnostics(): {success: boolean, message: string, details: {[string]: any}?}
    local details = {}
    
    -- Testar acesso ao contador
    local counterSuccess, counter = pcall(function()
        return counterDataStore:GetAsync(COUNTER_KEY)
    end)
    
    details.counterAccess = counterSuccess
    details.currentCounter = counter or 0
    
    -- Testar acesso ao DataStore de User IDs
    local userIdStoreSuccess = pcall(function()
        userIdDataStore:GetAsync("test")
    end)
    
    details.userIdStoreAccess = userIdStoreSuccess
    
    -- Verificar se o sistema está funcional
    local isHealthy = counterSuccess and userIdStoreSuccess
    
    local message = "🔧 Diagnóstico do Sistema de User ID:\n"
    message = message .. "📊 Contador: " .. (counterSuccess and "✅ OK" or "❌ ERRO") .. "\n"
    message = message .. "🗄️ DataStore User IDs: " .. (userIdStoreSuccess and "✅ OK" or "❌ ERRO") .. "\n"
    message = message .. "🔢 Próximo ID: " .. (details.currentCounter + 1) .. "\n"
    message = message .. "🏥 Status Geral: " .. (isHealthy and "✅ SAUDÁVEL" or "❌ PROBLEMAS DETECTADOS")
    
    return {
        success = isHealthy,
        message = message,
        details = details
    }
end

--- Busca o Roblox ID que possui um User ID específico
function UserIdModule.findRobloxIdByUserId(targetUserId: number): number?
    local success, robloxId = pcall(function()
        local pages = userIdDataStore:ListKeysAsync()
        repeat
            local keys = pages:GetCurrentPage()
            for _, keyInfo in pairs(keys) do
                local existingUserId = userIdDataStore:GetAsync(keyInfo.KeyName)
                if existingUserId == targetUserId then
                    return tonumber(keyInfo.KeyName)
                end
            end
            if not pages.IsFinished then
                pages:AdvanceToNextPageAsync()
            end
        until pages.IsFinished
        return nil
    end)
    
    return success and robloxId or nil
end

--- Verifica se um User ID já está em uso
function UserIdModule.isUserIdInUse(userId: number): boolean
    if usedIdsCache[userId] then
        return true
    end
    
    return UserIdModule.findRobloxIdByUserId(userId) ~= nil
end

--- Obtém o nome do jogador que possui um User ID específico
function UserIdModule.getPlayerNameByUserId(userId: number): string?
    local robloxId = UserIdModule.findRobloxIdByUserId(userId)
    if not robloxId then
        return nil
    end
    
    -- Verificar se está online
    local Players = game:GetService("Players")
    local onlinePlayer = Players:GetPlayerByUserId(robloxId)
    if onlinePlayer then
        return onlinePlayer.Name
    end
    
    -- Buscar nome offline
    return UserIdModule.getUsername(robloxId)
end

--- Atualiza o leaderboard de um jogador online
function UserIdModule.updatePlayerLeaderboard(robloxUserId: number, newUserId: number)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(robloxUserId)
    if not player then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local userIdValue = leaderstats:FindFirstChild("ID")
    if userIdValue and userIdValue:IsA("IntValue") then
        userIdValue.Value = newUserId
    end
end

--- Altera o User ID de um jogador específico
function UserIdModule.changeUserId(robloxUserId: number, newUserId: number): boolean
    -- Validações
    if not robloxUserId or robloxUserId <= 0 then
        warn("❌ Roblox User ID inválido:", robloxUserId)
        return false
    end
    
    if not newUserId or newUserId <= 0 then
        warn("❌ Novo User ID inválido:", newUserId)
        return false
    end
    
    -- Verificar se o novo ID já está em uso por outro jogador
    if UserIdModule.isUserIdInUse(newUserId) then
        local currentUserId = UserIdModule.getUserIdByRobloxId(robloxUserId)
        if currentUserId ~= newUserId then
            local conflictingPlayerName = UserIdModule.getPlayerNameByUserId(newUserId)
            local errorMessage = "❌ User ID " .. newUserId .. " já está em uso"
            if conflictingPlayerName then
                errorMessage = errorMessage .. " por " .. conflictingPlayerName
            end
            warn(errorMessage)
            return false
        end
    end
    
    -- Salvar alteração no DataStore
    local success = pcall(function()
        userIdDataStore:SetAsync(tostring(robloxUserId), newUserId)
    end)
    
    if not success then
        warn("❌ Erro ao salvar User ID no DataStore")
        return false
    end
    
    -- Atualizar caches
    local oldUserId = UserIdModule.getUserIdByRobloxId(robloxUserId)
    if oldUserId then
        usedIdsCache[oldUserId] = nil
    end
    usedIdsCache[newUserId] = true
    
    -- Atualizar leaderboard se jogador estiver online
    UserIdModule.updatePlayerLeaderboard(robloxUserId, newUserId)
    
    print("✅ User ID alterado:", robloxUserId, "->", newUserId)
    return true
end



return UserIdModule