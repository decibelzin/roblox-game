-- ========================================
-- CLASSE: HotbarSlot
-- ========================================
-- Representa um slot individual na hotbar

local shared = require(script.Parent.shared)

local HotbarSlot = {}
HotbarSlot.__index = HotbarSlot

function HotbarSlot.new(gui, slotIndex, itemId, itemData, hotbarManager)
    local self = setmetatable({}, HotbarSlot)
    
    self.gui = gui
    self.slotIndex = slotIndex  -- 1 a 4
    self.itemId = itemId
    self.itemData = itemData
    self.hotbarManager = hotbarManager
    self.isEmpty = itemId == nil
    
    self:setup()
    return self
end

function HotbarSlot:setup()
    -- Configurar visual
    if not self.isEmpty then
        self.gui:SetAttribute("ItemId", self.itemId)
        self.gui:SetAttribute("HotbarSlot", self.slotIndex)
        
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
    else
        self.gui:SetAttribute("HotbarSlot", self.slotIndex)
    end
    
    -- Eventos de drag (apenas para slots com item)
    if not self.isEmpty then
        self.gui.MouseButton1Down:Connect(function() self:onMouseDown() end)
        self.gui.MouseButton1Up:Connect(function() self:onMouseUp() end)
    end
    
    -- Eventos de hover (SEMPRE conectar, mesmo para slots vazios - importante para receber drops!)
    self.gui.MouseEnter:Connect(function() self:onMouseEnter() end)
    self.gui.MouseLeave:Connect(function() self:onMouseLeave() end)
end

function HotbarSlot:onMouseDown()
    if self.isEmpty then return end
    if self.hotbarManager.inventory.isMobile then return end
    
    local m = shared.getMouse()
    self.mouseDownPosition = Vector2.new(m.X, m.Y)
    
    -- Iniciar timer para drag
    self.dragTask = task.delay(shared.DRAG_THRESHOLD, function()
        if not self.hotbarManager.inventory.isDragging then
            self.hotbarManager:startDrag(self)
        end
        self.dragTask = nil
    end)
    
    -- Drag instantâneo se mover rapidamente
    local startPos = self.mouseDownPosition
    self.mouseMoveConnection = m.Move:Connect(function()
        if startPos and not self.hotbarManager.inventory.isDragging then
            local currentPos = Vector2.new(m.X, m.Y)
            local distance = (currentPos - startPos).Magnitude
            
            if distance > 15 then
                if self.dragTask then
                    task.cancel(self.dragTask)
                    self.dragTask = nil
                end
                self.hotbarManager:startDrag(self)
                if self.mouseMoveConnection then
                    self.mouseMoveConnection:Disconnect()
                    self.mouseMoveConnection = nil
                end
            end
        end
    end)
end

function HotbarSlot:onMouseUp()
    if self.mouseMoveConnection then
        self.mouseMoveConnection:Disconnect()
        self.mouseMoveConnection = nil
    end
    
    self.mouseDownPosition = nil
    
    if self.dragTask then
        task.cancel(self.dragTask)
        self.dragTask = nil
        -- Se não iniciou drag, é um clique normal (usar item)
        self:onClick()
    end
end

function HotbarSlot:cancelDrag()
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

function HotbarSlot:onClick()
    if self.isEmpty then return end
    self.hotbarManager:useItem(self.slotIndex)
end

function HotbarSlot:onMouseEnter()
    -- Mostrar tooltip apenas se tiver item e não estiver arrastando
    if not self.isEmpty and not self.hotbarManager.inventory.isDragging then
        if shared.hoverSound then shared.hoverSound:Play() end
        self.hotbarManager.inventory:showTooltip(self)
    end
    
    -- Detectar hover durante drag (SEMPRE, mesmo para slots vazios)
    if self.hotbarManager.inventory.isDragging then
        self.hotbarManager.hoveredSlot = self
    end
end

function HotbarSlot:onMouseLeave()
    if not self.isEmpty and not self.hotbarManager.inventory.isDragging then
        self.hotbarManager.inventory:hideTooltip(self)
    end
    
    if self.hotbarManager.inventory.isDragging and self.hotbarManager.hoveredSlot == self then
        self.hotbarManager.hoveredSlot = nil
    end
end

function HotbarSlot:destroy()
    self:cancelDrag()
    if self.gui then
        self.gui:Destroy()
    end
end

return HotbarSlot

