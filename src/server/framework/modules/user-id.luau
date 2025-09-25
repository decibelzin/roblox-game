local STORAGE_DEFINITIONS = require(game.ReplicatedStorage.Shared.storage)
local DataStoreService = game:GetService("DataStoreService")

local userIdDataStore = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.userId)
local counterDataStore = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.userIdCounter)

local COUNTER_KEY = "nextUserId"

local UserIdModule = {}

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

return UserIdModule 