local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse() -- Cache da referência do mouse (operação cara!)
local clickSound = StarterGui:WaitForChild("clicksound", 5)
local hoverSound = StarterGui:WaitForChild("hoversound", 5)

local INVENTORY_TOGGLE_KEY = Enum.KeyCode.Backquote
local DRAG_THRESHOLD = 0.1  -- Reduzido de 0.1 para 0.05 (50ms = muito mais rápido!)
local SWAP_COOLDOWN = 0.05   -- Reduzido de 0.05 para 0.01 (quase instantâneo!)

-- Importar config de itens
local ITEMS_MODULE = require(ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list

-- RemoteEvents
local getPlayerItemsFunction = ReplicatedStorage:WaitForChild("GetPlayerItems", 10)
local updatePlayerItemsEvent = ReplicatedStorage:WaitForChild("UpdatePlayerItems", 10)
local reorderItemsEvent = ReplicatedStorage:WaitForChild("ReorderItems", 10)

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

-- ========================================
-- GHOST SLOT CACHE (Reutilizável)
-- ========================================
local GhostSlotCache = {
    ghost = nil,
    quantityLabel = nil,  -- Cache das referências dos filhos
    gradient = nil
}

function GhostSlotCache.prepare(slotTemplate, parent)
    if GhostSlotCache.ghost then
        GhostSlotCache.ghost.Visible = false
        return
    end
    
    local ghost = slotTemplate:Clone()
    ghost.Name = "GhostSlot"
    ghost.BackgroundTransparency = 0.3
    ghost.ZIndex = 10000
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)
    ghost.Active = false
    ghost.AutoButtonColor = false
    ghost.Visible = false
    
    -- Configurar descendentes uma única vez
    for _, descendant in ipairs(ghost:GetDescendants()) do
        if descendant:IsA("GuiButton") then
            descendant.Active = false
            descendant.AutoButtonColor = false
        elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            descendant.ImageTransparency = 0.3
            descendant.ZIndex = 10000
        elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            descendant.TextTransparency = 0.3
            descendant.BackgroundTransparency = math.min(1, descendant.BackgroundTransparency + 0.3)
            descendant.ZIndex = 10000
        elseif descendant:IsA("Frame") then
            descendant.BackgroundTransparency = math.min(1, descendant.BackgroundTransparency + 0.3)
            descendant.ZIndex = 10000
        elseif descendant:IsA("UIStroke") then
            descendant.Transparency = 0.3
        end
    end
    
    ghost.Parent = parent
    GhostSlotCache.ghost = ghost
    
    -- Cachear referências dos filhos (FindFirstChild é caro!)
    GhostSlotCache.quantityLabel = ghost:FindFirstChild("ItemQuantity")
    GhostSlotCache.gradient = ghost:FindFirstChild("UIGradient")
end

function GhostSlotCache.show(sourceSlot, position)
    local ghost = GhostSlotCache.ghost
    if not ghost then return end
    
    ghost.Size = UDim2.new(0, sourceSlot.AbsoluteSize.X, 0, sourceSlot.AbsoluteSize.Y)
    ghost.Position = position
    ghost.Visible = true
    
    -- Copiar conteúdo visual do slot original (usando cache!)
    local sourceQuantity = sourceSlot:FindFirstChild("ItemQuantity")
    if sourceQuantity and GhostSlotCache.quantityLabel then
        GhostSlotCache.quantityLabel.Text = sourceQuantity.Text
    end
    
    local sourceGradient = sourceSlot:FindFirstChild("UIGradient")
    if sourceGradient and GhostSlotCache.gradient then
        GhostSlotCache.gradient.Color = sourceGradient.Color
    end
end

function GhostSlotCache.hide()
    if GhostSlotCache.ghost then
        GhostSlotCache.ghost.Visible = false
    end
end

function GhostSlotCache.updatePosition(position)
    if GhostSlotCache.ghost and GhostSlotCache.ghost.Visible then
        GhostSlotCache.ghost.Position = position
    end
end

-- ========================================
-- CLASSE: InventorySlot
-- ========================================
local InventorySlot = {}
InventorySlot.__index = InventorySlot

function InventorySlot.new(gui, itemId, itemData, inventory)
    local self = setmetatable({}, InventorySlot)
    
    self.gui = gui
    self.itemId = itemId
    self.itemData = itemData
    self.inventory = inventory
    self.dragTask = nil
    self.mouseDownPosition = nil
    self.mouseMoveConnection = nil
    
    self:setup()
    return self
end

function InventorySlot:setup()
    -- Configurar visual
    self.gui:SetAttribute("ItemId", self.itemId)
    
    local quantityLabel = self.gui:FindFirstChild("ItemQuantity")
    if quantityLabel then
        quantityLabel.Text = tostring(self.itemData.quantity or 0)..'x'
    end
    
    if self.itemData.item.color then
        local uiGradient = self.gui:FindFirstChild("UIGradient")
        if uiGradient then
            uiGradient.Color = ColorSequence.new(self.itemData.item.color)
        end
    end
    
    -- Conectar eventos
    self.gui.MouseButton1Down:Connect(function() self:onMouseDown() end)
    self.gui.MouseButton1Up:Connect(function() self:onMouseUp() end)
    self.gui.MouseEnter:Connect(function() self:onMouseEnter() end)
    self.gui.MouseLeave:Connect(function() self:onMouseLeave() end)
end

function InventorySlot:onMouseDown()
    self.mouseDownPosition = Vector2.new(mouse.X, mouse.Y)
    
    -- Iniciar timer para drag
    self.dragTask = task.delay(DRAG_THRESHOLD, function()
        if not self.inventory.isDragging then
            self.inventory:startDrag(self)
        end
        self.dragTask = nil
    end)
    
    -- Drag instantâneo se mover o mouse rapidamente (>10 pixels)
    self.mouseMoveConnection = mouse.Move:Connect(function()
        if self.mouseDownPosition and not self.inventory.isDragging then
            local currentPos = Vector2.new(mouse.X, mouse.Y)
            local distance = (currentPos - self.mouseDownPosition).Magnitude
            
            -- Se mover mais de 10 pixels, inicia drag imediatamente!
            if distance > 10 then
                if self.dragTask then
                    task.cancel(self.dragTask)
                    self.dragTask = nil
                end
                self.inventory:startDrag(self)
                if self.mouseMoveConnection then
                    self.mouseMoveConnection:Disconnect()
                    self.mouseMoveConnection = nil
                end
            end
        end
    end)
end

function InventorySlot:onMouseUp()
    -- Limpar conexão de movimento
    if self.mouseMoveConnection then
        self.mouseMoveConnection:Disconnect()
        self.mouseMoveConnection = nil
    end
    
    self.mouseDownPosition = nil
    
    -- Cancelar drag se ainda não iniciou
    if self.dragTask then
        task.cancel(self.dragTask)
        self.dragTask = nil
    end
end

function InventorySlot:onMouseEnter()
    -- Tooltip
    if not self.inventory.isDragging then
        if hoverSound then hoverSound:Play() end
        self.inventory:showTooltip(self)
    end
    
    -- Swap durante drag
    if self.inventory.isDragging and self.inventory.draggedSlot and self.inventory.draggedSlot ~= self then
        self.inventory:swapSlots(self)
    end
end

function InventorySlot:onMouseLeave()
    if not self.inventory.isDragging then
        self.inventory:hideTooltip(self)
    end
end

function InventorySlot:cancelDrag()
    if self.mouseMoveConnection then
        self.mouseMoveConnection:Disconnect()
        self.mouseMoveConnection = nil
    end
    
    self.mouseDownPosition = nil
    
    if self.dragTask then
        task.cancel(self.dragTask)
        self.dragTask = nil
    end
end

function InventorySlot:destroy()
    self:cancelDrag()
    if self.gui then
        self.gui:Destroy()
    end
end

-- ========================================
-- CLASSE: Inventory
-- ========================================
local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
    local self = setmetatable({}, Inventory)
    
    -- Referências de UI (cache)
    self.container = nil
    self.scrollingFrame = nil
    self.tooltip = nil
    self.slotTemplate = nil
    self.parentGui = nil
    
    -- Estado
    self.slotsMap = {} -- {[itemId] = InventorySlot} para lookup rápido
    self.playerItems = {}
    self.itemsOrder = {}
    
    -- Drag state
    self.isDragging = false
    self.draggedSlot = nil
    self.lastSwapTime = 0
    self.ghostUpdateConnection = nil
    
    -- Tooltip state
    self.currentTooltipSlot = nil
    self.tooltipHideTask = nil
    
    -- Conexões
    self.connections = {}
    
    return self
end

function Inventory:initialize()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
    
    -- Buscar elementos de UI
    local playerGui = player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:WaitForChild("INVENTARIO_NOVO", 10)
    if not inventoryGui then return warn("INVENTARIO_NOVO não encontrado!") end
    
    self.parentGui = inventoryGui
    self.container = inventoryGui:FindFirstChild("container")
    if not self.container then return warn("Container não encontrado!") end
    
    local background = self.container:FindFirstChild("background")
    if not background then return warn("Background não encontrado!") end
    
    self.scrollingFrame = background:FindFirstChild("ScrollingFrame")
    self.tooltip = background:FindFirstChild("ItemInfoTooltip")
    local closeButton = background:FindFirstChild("Close")
    
    if not self.scrollingFrame then return warn("ScrollingFrame não encontrado!") end
    if not self.tooltip then return warn("ItemInfoTooltip não encontrado!") end
    if not closeButton then return warn("Close button não encontrado!") end
    
    self.slotTemplate = self.scrollingFrame:FindFirstChild("Slot")
    if not self.slotTemplate then return warn("Slot template não encontrado!") end
    self.slotTemplate.Visible = false
    
    self.container.Visible = false
    self.tooltip.Visible = false
    
    -- Preparar ghost cache
    GhostSlotCache.prepare(self.slotTemplate, self.parentGui)
    
    -- Carregar itens do servidor
    self:loadItems()
    
    -- Conectar eventos
    self:connectEvents(closeButton)
    
    return true
end

function Inventory:loadItems()
    if not getPlayerItemsFunction then
        return warn("⚠️ GetPlayerItems RemoteFunction não encontrado!")
    end
    
    local success, serverItems = pcall(function()
        return getPlayerItemsFunction:InvokeServer()
    end)
    
    if success and serverItems and type(serverItems) == "table" then
        self:updateItems(serverItems)
    else
        warn("⚠️ Erro ao carregar itens do jogador")
    end
    
    return
end

function Inventory:updateItems(serverItems)
    -- Combinar dados (único loop necessário aqui)
    self.playerItems = {}
    for itemId, quantity in pairs(serverItems) do
        local itemConfig = ITEMS_CONFIG[itemId]
        if itemConfig then
            self.playerItems[itemId] = {
                item = itemConfig,
                quantity = quantity
            }
        end
    end
    
    self:rebuildSlots()
end

function Inventory:rebuildSlots()
    -- Limpar slots antigos
    for _, slot in pairs(self.slotsMap) do
        slot:destroy()
    end
    self.slotsMap = {}
    
    -- Criar array ordenado (único loop necessário aqui)
    local itemsArray = {}
    for itemId, itemData in pairs(self.playerItems) do
        itemsArray[#itemsArray + 1] = {
            id = itemId,
            data = itemData,
            order = self.itemsOrder[itemId] or 999999
        }
    end
    
    table.sort(itemsArray, function(a, b)
        return a.order == b.order and a.id < b.id or a.order < b.order
    end)
    
    -- Criar slots (único loop necessário aqui)
    for index, itemEntry in ipairs(itemsArray) do
        local gui = self.slotTemplate:Clone()
        gui.Name = "ItemSlot_" .. itemEntry.id
        gui.Visible = true
        gui.LayoutOrder = index
        gui.Parent = self.scrollingFrame
        
        local slot = InventorySlot.new(gui, itemEntry.id, itemEntry.data, self)
        self.slotsMap[itemEntry.id] = slot
    end
end

function Inventory:startDrag(slot)
    self.isDragging = true
    self.draggedSlot = slot
    
    -- Mostrar ghost
    GhostSlotCache.show(slot.gui, UDim2.new(0, mouse.X, 0, mouse.Y))
    
    -- Iniciar atualização de posição (apenas quando arrastando!)
    self.ghostUpdateConnection = RunService.RenderStepped:Connect(function()
        GhostSlotCache.updatePosition(UDim2.new(0, mouse.X, 0, mouse.Y))
    end)
end

function Inventory:endDrag()
    if not self.isDragging then return end
    
    self.isDragging = false
    
    -- Parar atualização de ghost
    if self.ghostUpdateConnection then
        self.ghostUpdateConnection:Disconnect()
        self.ghostUpdateConnection = nil
    end
    
    GhostSlotCache.hide()
    
    if self.draggedSlot then
        self:saveOrder()
        self.draggedSlot = nil
        if clickSound then clickSound:Play() end
    end
end

function Inventory:swapSlots(targetSlot)
    if not self.draggedSlot or not targetSlot.gui.Visible then return end
    
    local currentTime = tick()
    if currentTime - self.lastSwapTime < SWAP_COOLDOWN then return end
    
    local draggedOrder = self.draggedSlot.gui.LayoutOrder
    local targetOrder = targetSlot.gui.LayoutOrder
    
    self.draggedSlot.gui.LayoutOrder = targetOrder
    targetSlot.gui.LayoutOrder = draggedOrder
    
    self.lastSwapTime = currentTime
end

function Inventory:saveOrder()
    -- Único loop necessário para serializar
    local newOrder = {}
    
    for itemId, slot in pairs(self.slotsMap) do
        if slot.gui.Visible then
            newOrder[itemId] = slot.gui.LayoutOrder
        end
    end
    
    self.itemsOrder = newOrder
    if reorderItemsEvent then
        pcall(function() reorderItemsEvent:FireServer(newOrder) end)
    end
end

function Inventory:showTooltip(slot)
    self.currentTooltipSlot = slot
    
    if self.tooltipHideTask then
        task.cancel(self.tooltipHideTask)
        self.tooltipHideTask = nil
    end
    
    local title = self.tooltip:FindFirstChild("title")
    local description = self.tooltip:FindFirstChild("description")
    
    if title then title.Text = slot.itemData.item.name or "Item #" .. slot.itemId end
    if description then description.Text = slot.itemData.item.description or "" end
    
    self.tooltip.Visible = true
end

function Inventory:hideTooltip(slot)
    if self.currentTooltipSlot ~= slot then return end
    
    self.currentTooltipSlot = nil
    
    if self.tooltipHideTask then task.cancel(self.tooltipHideTask) end
    self.tooltipHideTask = task.delay(0.1, function()
        if not self.currentTooltipSlot then
            self.tooltip.Visible = false
        end
        self.tooltipHideTask = nil
    end)
end

function Inventory:connectEvents(closeButton)
    -- Close button
    closeButton.MouseButton1Click:Connect(function()
        if clickSound then clickSound:Play() end
        self.container.Visible = false
        enableNativeUI()
    end)
    
    closeButton.MouseEnter:Connect(function()
        if hoverSound then hoverSound:Play() end
    end)
    
    -- Toggle key
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= INVENTORY_TOGGLE_KEY then return end
        
        if clickSound then clickSound:Play() end
        self.container.Visible = not self.container.Visible
        
        if self.container.Visible then
            disableNativeUI()
        else
            enableNativeUI()
        end
    end))
    
    -- Mouse release (event-driven, não polling!)
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        
        -- Cancelar drags pendentes de TODOS os slots
        for _, slot in pairs(self.slotsMap) do
            slot:cancelDrag()
        end
        
        self:endDrag()
    end))
    
    -- Server updates
    if updatePlayerItemsEvent then
        table.insert(self.connections, updatePlayerItemsEvent.OnClientEvent:Connect(function(serverItems)
            if serverItems and type(serverItems) == "table" then
                self:updateItems(serverItems)
            end
        end))
    end
end

function Inventory:destroy()
    -- Cleanup
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    
    if self.ghostUpdateConnection then
        self.ghostUpdateConnection:Disconnect()
    end
    
    for _, slot in pairs(self.slotsMap) do
        slot:destroy()
    end
    
    GhostSlotCache.hide()
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
local inventoryInstance = Inventory.new()

local function setupInventory()
    inventoryInstance:initialize()
end

player.CharacterAdded:Connect(setupInventory)

if player.Character then
    setupInventory()
end
