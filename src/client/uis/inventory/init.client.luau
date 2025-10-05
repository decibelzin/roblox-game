-- ========================================
-- INVENTORY SYSTEM - INICIALIZAÇÃO
-- ========================================
-- Ponto de entrada para o sistema de inventário modularizado

local shared = require(script.shared)
local Inventory = require(script.inventory)
local HotbarManager = require(script["hotbar-manager"])

-- Instâncias globais
local inventoryInstance = Inventory.new()
local hotbarInstance = nil

local function setupInventory()
    inventoryInstance:initialize()
    
    -- Inicializar hotbar DEPOIS do inventário
    hotbarInstance = HotbarManager.new(inventoryInstance)
    hotbarInstance:initialize()
    
    -- Conectar inventário à hotbar
    inventoryInstance.hotbar = hotbarInstance
end

-- Conectar ao evento CharacterAdded
shared.player.CharacterAdded:Connect(setupInventory)

-- Inicializar se o personagem já existir
if shared.player.Character then
    setupInventory()
end

