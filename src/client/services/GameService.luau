-- Serviço responsável por gerenciar a lógica do jogo
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameService = {}
GameService.isInMenu = true

-- Função para iniciar o jogo
function GameService.startGame()
    if not GameService.isInMenu then return end
    
    print("Iniciando jogo...")
    GameService.isInMenu = false
    
    -- Sinalizar para o servidor que o jogador está pronto
    local remoteEvent = ReplicatedStorage:WaitForChild("PlayerReady")
    remoteEvent:FireServer()
end

-- Função para verificar se está no menu
function GameService.isInMenuState()
    return GameService.isInMenu
end

return GameService
