-- Serviço responsável por gerenciar jogadores no servidor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameConfig"))

local PlayerService = {}

-- Função para spawnar o jogador na posição inicial
function PlayerService.spawnPlayer(player)
    if not player.Character then
        player:LoadCharacter()
    end
    
    -- Aguardar o personagem carregar
    player.CharacterAdded:Wait()
    
    -- Aguardar o HumanoidRootPart
    local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart")
    
    -- Teleportar para a posição inicial
    humanoidRootPart.CFrame = CFrame.new(GameConfig.SPAWN_POSITION)
    
    print(player.Name .. " foi spawnado na posição: " .. tostring(GameConfig.SPAWN_POSITION))
end

-- Função para lidar com jogador pronto
function PlayerService.onPlayerReady(player)
    print(player.Name .. " está pronto para jogar!")
    PlayerService.spawnPlayer(player)
end

-- Função para lidar com jogador adicionado
function PlayerService.onPlayerAdded(player)
    -- Aguardar um pouco para garantir que o cliente carregou
    wait(2)
    
    -- Se o jogador não tem personagem, spawnar
    if not player.Character then
        PlayerService.spawnPlayer(player)
    end
end

return PlayerService
