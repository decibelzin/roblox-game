-- TimePlayedLeaderboard System
-- Este script inicializa o sistema de leaderboard de tempo jogado

print("🎯 Iniciando sistema TimePlayedLeaderboard...")

-- Verificar se o model existe no Workspace
local timePlayedModel = workspace:WaitForChild("TimePlayedLeaderboard", 10)
if not timePlayedModel then
    warn("❌ Model 'TimePlayedLeaderboard' não encontrado no Workspace!")
    return
end

print("✅ Model TimePlayedLeaderboard encontrado no Workspace")

-- Verificar componentes essenciais
local scoreBlock = timePlayedModel:FindFirstChild("ScoreBlock")
if not scoreBlock then
    warn("❌ ScoreBlock não encontrado no TimePlayedLeaderboard!")
    return
end

print("✅ ScoreBlock encontrado")

-- Inicializar o sistema refatorado
local success, err = pcall(function()
    require(script.Parent.timeplayed.init)
end)

if success then
    print("🚀 Sistema TimePlayedLeaderboard refatorado inicializado com sucesso!")
else
    warn("❌ Erro ao inicializar TimePlayedLeaderboard refatorado:", err)
    -- Fallback para o sistema antigo se necessário
    print("🔄 Tentando fallback para sistema antigo...")
    local fallbackSuccess, fallbackErr = pcall(function()
        require(script.Parent.timeplayed.class)
    end)
    
    if fallbackSuccess then
        print("🚀 Sistema TimePlayedLeaderboard (antigo) inicializado como fallback!")
    else
        warn("❌ Erro no fallback:", fallbackErr)
    end
end 