-- ========================================
-- CLASSE: InventorySlot
-- ========================================
-- Representa um slot individual no inventário

local shared = require(script.Parent.shared)

local InventorySlot = {}
InventorySlot.__index = InventorySlot

function InventorySlot.new(gui, slotIndex, itemId, itemData, inventory)
    local self = setmetatable({}, InventorySlot)
    
    self.gui = gui
    self.slotIndex = slotIndex  -- Posição fixa do slot (1 a MAX_SLOTS)
    self.itemId = itemId  -- nil se slot vazio
    self.itemData = itemData  -- nil se slot vazio
    self.inventory = inventory
    self.dragTask = nil
    self.mouseDownPosition = nil
    self.mouseMoveConnection = nil
    self.isEmpty = itemId == nil
    
    self:setup()
    return self
end

function InventorySlot:setup()
    -- Configurar visual
    if not self.isEmpty then
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
    end
    
    -- Conectar AMBOS os tipos de eventos (serão usados dinamicamente)
    -- Touch events (para mobile)
    self.gui.TouchLongPress:Connect(function() self:onLongPress() end)
    self.gui.TouchTap:Connect(function() self:onTap() end)
    
    -- Mouse events (para PC)
    self.gui.MouseButton1Down:Connect(function() self:onMouseDown() end)
    self.gui.MouseButton1Up:Connect(function() self:onMouseUp() end)
    
    -- Eventos comuns (funcionam em ambas plataformas)
    self.gui.MouseEnter:Connect(function() self:onMouseEnter() end)
    self.gui.MouseLeave:Connect(function() self:onMouseLeave() end)
end

-- PC: Drag rápido com mouse
function InventorySlot:onMouseDown()
    if self.isEmpty then return end
    
    -- Se está no modo mobile (usando touch), ignorar eventos de mouse
    if self.inventory.isMobile then return end
    
    local m = shared.getMouse()
    self.mouseDownPosition = Vector2.new(m.X, m.Y)
    
    -- Iniciar timer para drag (100ms)
    self.dragTask = task.delay(shared.DRAG_THRESHOLD, function()
        if not self.inventory.isDragging then
            self.inventory:startDrag(self)
        end
        self.dragTask = nil
    end)
    
    -- Drag instantâneo se mover rapidamente (>15 pixels)
    local startPos = self.mouseDownPosition
    self.mouseMoveConnection = m.Move:Connect(function()
        if startPos and not self.inventory.isDragging then
            local currentPos = Vector2.new(m.X, m.Y)
            local distance = (currentPos - startPos).Magnitude
            
            if distance > 15 then
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

-- Mobile: Long press para drag (sem conflito com scroll!)
function InventorySlot:onLongPress()
    if self.isEmpty then return end
    
    -- Se está no modo PC (usando mouse), ignorar touch events
    if not self.inventory.isMobile then return end
    
    if not self.inventory.isDragging then
        self.inventory:startDrag(self)
    end
end

-- Mobile: Tap simples (para futura interação, se necessário)
function InventorySlot:onTap()
    if self.isEmpty then return end
    
    -- Se está no modo PC (usando mouse), ignorar touch events
    if not self.inventory.isMobile then return end
    
    -- Por enquanto não faz nada, mas pode ser usado para "usar" o item
    -- Futuro: self.inventory:useItem(self)
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
    -- Som de hover
    if not self.isEmpty then
        if shared.hoverSound then shared.hoverSound:Play() end
    end
    
    -- Registrar qual slot está sendo "hovered" durante o drag (não faz swap ainda!)
    if self.inventory.isDragging and self.inventory.draggedSlot and self.inventory.draggedSlot ~= self then
        self.inventory.hoveredSlot = self
    end
end

function InventorySlot:onMouseLeave()
    -- Limpar hoveredSlot quando sair
    if self.inventory.isDragging and self.inventory.hoveredSlot == self then
        self.inventory.hoveredSlot = nil
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

return InventorySlot

