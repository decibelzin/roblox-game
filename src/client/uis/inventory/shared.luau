-- Constantes e utilitários compartilhados para o sistema de inventário
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Sons
local clickSound = StarterGui:WaitForChild("clicksound", 5)
local hoverSound = StarterGui:WaitForChild("hoversound", 5)

-- Safe mouse initialization
local mouse
local function getMouse()
    if not mouse then
        mouse = player:GetMouse()
    end
    return mouse
end

-- Constantes
local INVENTORY_TOGGLE_KEY = Enum.KeyCode.Backquote
local HOTBAR_TOGGLE_KEY = Enum.KeyCode.LeftAlt
local DRAG_THRESHOLD = 0.1  -- Tempo antes de iniciar o drag no PC (100ms)

-- Detectar plataforma inicial
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Importar config de itens
local ITEMS_MODULE = require(ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list
local MAX_SLOTS = ITEMS_MODULE.maxSlots or 20
local MAX_HOTBAR_SLOTS = ITEMS_MODULE.maxHotbarSlots or 4

-- Logs de debug removidos após correção do bug

-- RemoteEvents/Functions
local getPlayerItemsFunction = ReplicatedStorage:WaitForChild("GetPlayerItems", 10)
local updatePlayerItemsEvent = ReplicatedStorage:WaitForChild("UpdatePlayerItems", 10)
local reorderItemsEvent = ReplicatedStorage:WaitForChild("ReorderItems", 10)
local getHotbarFunction = ReplicatedStorage:WaitForChild("GetHotbar", 10)
local updateHotbarEvent = ReplicatedStorage:WaitForChild("UpdateHotbar", 10)
local setHotbarSlotEvent = ReplicatedStorage:WaitForChild("SetHotbarSlot", 10)
local swapHotbarSlotsEvent = ReplicatedStorage:WaitForChild("SwapHotbarSlots", 10)
local moveHotbarToInventorySlotEvent = ReplicatedStorage:WaitForChild("MoveHotbarToInventorySlot", 10)

-- Funções utilitárias
local function disableNativeUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)
end

local function enableNativeUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
    end)
end

-- Exportar
return {
    -- Serviços
    Players = Players,
    UserInputService = UserInputService,
    StarterGui = StarterGui,
    ReplicatedStorage = ReplicatedStorage,
    RunService = game:GetService("RunService"),
    
    -- Player e utilitários
    player = player,
    getMouse = getMouse,
    
    -- Sons
    clickSound = clickSound,
    hoverSound = hoverSound,
    
    -- Constantes
    INVENTORY_TOGGLE_KEY = INVENTORY_TOGGLE_KEY,
    HOTBAR_TOGGLE_KEY = HOTBAR_TOGGLE_KEY,
    DRAG_THRESHOLD = DRAG_THRESHOLD,
    IS_MOBILE = IS_MOBILE,
    
    -- Itens
    ITEMS_CONFIG = ITEMS_CONFIG,
    MAX_SLOTS = MAX_SLOTS,
    MAX_HOTBAR_SLOTS = MAX_HOTBAR_SLOTS,
    
    -- Remote Events/Functions
    getPlayerItemsFunction = getPlayerItemsFunction,
    updatePlayerItemsEvent = updatePlayerItemsEvent,
    reorderItemsEvent = reorderItemsEvent,
    getHotbarFunction = getHotbarFunction,
    updateHotbarEvent = updateHotbarEvent,
    setHotbarSlotEvent = setHotbarSlotEvent,
    swapHotbarSlotsEvent = swapHotbarSlotsEvent,
    moveHotbarToInventorySlotEvent = moveHotbarToInventorySlotEvent,
    
    -- Funções utilitárias
    disableNativeUI = disableNativeUI,
    enableNativeUI = enableNativeUI,
}

