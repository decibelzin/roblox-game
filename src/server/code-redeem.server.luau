local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Importar módulos necessários
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local CodeRewards = require(game.ServerScriptService.Server.framework.modules["code-rewards"])
local redeemableCodes = require(ReplicatedStorage.Shared["redeemable-codes"])
local STORAGE_DEFINITIONS = require(ReplicatedStorage.Shared.storage)

-- Configurar DataStore para códigos resgatados
local redeemedCodesDataStore = DataStoreService:GetDataStore(STORAGE_DEFINITIONS.redeemedCodes)

-- Criar o RemoteEvent para códigos se não existir
local codeRedeemEvent = ReplicatedStorage:FindFirstChild("CodeRedeemEvent")
if not codeRedeemEvent then
    codeRedeemEvent = Instance.new("RemoteEvent")
    codeRedeemEvent.Name = "CodeRedeemEvent"
    codeRedeemEvent.Parent = ReplicatedStorage
end

-- Cache temporário para melhor performance (será sincronizado com DataStore)
local playerCodesCache = {}

-- Função para carregar códigos resgatados de um jogador do DataStore
local function loadPlayerRedeemedCodes(userId: number): {[string]: boolean}
    local success, data = pcall(function()
        return redeemedCodesDataStore:GetAsync(tostring(userId))
    end)
    
    if success and data and type(data) == "table" then
        return data
    end
    
    return {} -- Retorna tabela vazia se não há dados ou erro
end

-- Função para salvar códigos resgatados de um jogador no DataStore
local function savePlayerRedeemedCodes(userId: number, codes: {[string]: boolean})
    local success = pcall(function()
        redeemedCodesDataStore:SetAsync(tostring(userId), codes)
    end)
    
    if not success then
        warn("Erro ao salvar códigos resgatados para o jogador ID:", userId)
    end
    
    return success
end

-- Função para verificar se um jogador já resgatou um código
local function hasPlayerRedeemedCode(userId: number, code: string): boolean
    -- Verificar primeiro no cache
    if playerCodesCache[userId] then
        return playerCodesCache[userId][code] == true
    end
    
    -- Se não está no cache, carregar do DataStore
    local redeemedCodes = loadPlayerRedeemedCodes(userId)
    playerCodesCache[userId] = redeemedCodes
    
    return redeemedCodes[code] == true
end

-- Função para marcar um código como resgatado
local function markCodeAsRedeemed(userId: number, code: string): boolean
    -- Atualizar cache
    if not playerCodesCache[userId] then
        playerCodesCache[userId] = loadPlayerRedeemedCodes(userId)
    end
    
    playerCodesCache[userId][code] = true
    
    -- Salvar no DataStore
    return savePlayerRedeemedCodes(userId, playerCodesCache[userId])
end

-- Função para processar resgate de código
local function processCodeRedeem(player: Player?, code: string)
    -- Validações básicas
    if not player or not code or type(code) ~= "string" then
        if player then
            ChatMessage.sendError(player, "Erro interno: dados inválidos")
            codeRedeemEvent:FireClient(player, false, "Erro interno: dados inválidos", code or "")
        end
        return
    end
    
    -- Limpar espaços em branco
    code = string.gsub(code, "^%s*(.-)%s*$", "%1")
    
    -- Verificar se o código existe
    if not redeemableCodes[code] then
        ChatMessage.sendError(player, "Código inválido ou não encontrado!")
        codeRedeemEvent:FireClient(player, false, "Código inválido ou não encontrado!", code)
        return
    end
    
    -- Verificar se o jogador já usou este código
    if hasPlayerRedeemedCode(player.UserId, code) then
        ChatMessage.sendWarning(player, "Você já resgatou o código: " .. code)
        codeRedeemEvent:FireClient(player, false, "Você já resgatou o código: " .. code, code)
        return
    end
    
    -- Marcar código como usado pelo jogador no DataStore
    local saveSuccess = markCodeAsRedeemed(player.UserId, code)
    if not saveSuccess then
        ChatMessage.sendError(player, "Erro ao salvar progresso. Tente novamente.")
        codeRedeemEvent:FireClient(player, false, "Erro ao salvar progresso. Tente novamente.", code)
        return
    end
    
    -- Processar recompensa do código
    local rewardSuccess = CodeRewards.giveReward(player, code)
    
    if not rewardSuccess then
        ChatMessage.sendError(player, "Erro ao processar recompensa do código!")
        codeRedeemEvent:FireClient(player, false, "Erro ao processar recompensa do código!", code)
        return
    end
    
    -- Enviar confirmação de sucesso para o cliente
    local rewardInfo = CodeRewards.getRewardInfo(code)
    local successMessage = rewardInfo and rewardInfo.message or "Código resgatado com sucesso!"
    codeRedeemEvent:FireClient(player, true, successMessage, code)
    
    -- Log do resgate
    --print("✅ Jogador " .. player.Name .. " (ID: " .. player.UserId .. ") resgatou o código: " .. code)
end

-- Conectar evento de resgate
codeRedeemEvent.OnServerEvent:Connect(processCodeRedeem)

-- Pré-carregar códigos resgatados quando jogador entrar (melhor performance)
Players.PlayerAdded:Connect(function(player)
    -- Carregar dados em background para cache
    task.spawn(function()
        playerCodesCache[player.UserId] = loadPlayerRedeemedCodes(player.UserId)
        print("Códigos resgatados carregados para:", player.Name)
    end)
end)

-- Limpar cache quando jogador sair (DataStore persiste automaticamente)
Players.PlayerRemoving:Connect(function(player)
    if playerCodesCache[player.UserId] then
        playerCodesCache[player.UserId] = nil
    end
end)

print("Sistema de resgate de códigos inicializado com DataStore persistente!") 