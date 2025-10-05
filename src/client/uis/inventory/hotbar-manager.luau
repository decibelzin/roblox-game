-- ========================================
-- CLASSE: HotbarManager (REESCRITO DO ZERO)
-- ========================================
-- Gerenciador simples e funcional da hotbar

local shared = require(script.Parent.shared)
local GhostSlotCache = require(script.Parent["ghost-slot-cache"])
local HotbarSlot = require(script.Parent["hotbar-slot"])

local HotbarManager = {}
HotbarManager.__index = HotbarManager

function HotbarManager.new(inventory)
    local self = setmetatable({}, HotbarManager)
    
    self.inventory = inventory
    self.container = nil
    self.hotbarSlots = {}  -- Array de HotbarSlots [1..4]
    self.hotbarData = {}  -- {[slotIndex] = {itemId, quantity}}
    self.slotTemplate = nil
    self.emptySlotTemplate = nil
    
    -- Estado de drag
    self.hoveredSlot = nil
    
    -- Locks
    self.isLocked = false
    
    -- Pending update
    self.pendingHotbarUpdate = nil
    
    -- Conexões
    self.connections = {}
    
    return self
end

function HotbarManager:initialize()
    local playerGui = shared.player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:WaitForChild("INVENTARIO_NOVO", 10)
    if not inventoryGui then return warn("INVENTARIO_NOVO não encontrado!") end
    
    local container = inventoryGui:FindFirstChild("container")
    if not container then return warn("Container não encontrado!") end
    
    self.container = container:FindFirstChild("hotbar")
    if not self.container then return warn("Hotbar não encontrado!") end
    
    -- Templates
    self.slotTemplate = self.container:FindFirstChild("ItemSlot")
    self.emptySlotTemplate = self.container:FindFirstChild("emptySlot")
    
    if not self.slotTemplate then return warn("ItemSlot template não encontrado!") end
    if not self.emptySlotTemplate then return warn("emptySlot template não encontrado!") end
    
    self.slotTemplate.Visible = false
    self.emptySlotTemplate.Visible = false
    self.container.Visible = true
    
    -- Carregar dados
    self:loadHotbar()
    
    -- Eventos
    self:connectEvents()
    
    return true
end

function HotbarManager:loadHotbar()
    if not shared.getHotbarFunction then
        warn("⚠️ GetHotbar RemoteFunction não encontrado!")
        return
    end
    
    local success, hotbar = pcall(function()
        return shared.getHotbarFunction:InvokeServer()
    end)
    
    if success and hotbar and type(hotbar) == "table" then
        self:updateHotbar(hotbar)
    else
        warn("⚠️ Erro ao carregar hotbar")
        self:rebuildSlots()
    end
end

function HotbarManager:updateHotbar(hotbar)
    -- 🔒 BUG FIX: Prevenir rebuild durante drag ativo
    if self.inventory.isDragging then
        -- Salvar update pendente para aplicar depois
        self.pendingHotbarUpdate = hotbar
        return
    end
    
    -- Normalizar chaves
    local normalizedHotbar = {}
    if hotbar then
        for slot, data in pairs(hotbar) do
            local slotNum = tonumber(slot)
            if slotNum and type(slotNum) == "number" then
                normalizedHotbar[slotNum] = data
            end
        end
    end
    
    self.hotbarData = normalizedHotbar
    self:rebuildSlots()
end

function HotbarManager:rebuildSlots()
    -- Limpar slots antigos
    for _, child in ipairs(self.container:GetChildren()) do
        if child ~= self.slotTemplate and child ~= self.emptySlotTemplate 
           and not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    self.hotbarSlots = {}
    
    -- Criar 4 slots
    for slotIndex = 1, shared.MAX_HOTBAR_SLOTS do
        local slotData = self.hotbarData[slotIndex]
        local gui, itemId, itemData
        
        if slotData and slotData.itemId then
            -- Slot com item
            gui = self.slotTemplate:Clone()
            gui.Name = "HotbarSlot_" .. slotIndex
            itemId = slotData.itemId
            
            local itemConfig = shared.ITEMS_CONFIG[itemId]
            if itemConfig then
                itemData = {
                    item = itemConfig,
                    quantity = slotData.quantity or 1
                }
            end
        else
            -- Slot vazio
            gui = self.emptySlotTemplate:Clone()
            gui.Name = "HotbarEmptySlot_" .. slotIndex
        end
        
        gui.Visible = true
        gui.LayoutOrder = slotIndex
        gui.Parent = self.container
        
        -- Atributo para detecção
        gui:SetAttribute("HotbarSlotId", slotIndex)
        for _, descendant in ipairs(gui:GetDescendants()) do
            descendant:SetAttribute("HotbarSlotId", slotIndex)
        end
        
        -- Criar slot
        local slot = HotbarSlot.new(gui, slotIndex, itemId, itemData, self)
        self.hotbarSlots[slotIndex] = slot
        
        -- Número do slot
        local textLabel = gui:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = tostring(slotIndex)
        end
    end
end

function HotbarManager:getHotbarSlotAtPosition(ghostTopLeft, ghostSize)
    local playerGui = shared.player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local size = ghostSize or Vector2.new(37, 40)
    local ghostCenter = ghostTopLeft + (size / 2)
    
    local guiObjects = playerGui:GetGuiObjectsAtPosition(ghostCenter.X, ghostCenter.Y)
    
    for _, guiObject in ipairs(guiObjects) do
        if guiObject.Name == "GhostSlot" then continue end
        
        local hotbarSlotId = guiObject:GetAttribute("HotbarSlotId")
        if hotbarSlotId then
            return self.hotbarSlots[hotbarSlotId]
        end
    end
    
    return nil
end

function HotbarManager:canReceiveItem(itemId)
    -- 🐛 BUG FIX: Converter itemId para número se necessário
    if type(itemId) == "string" then
        itemId = tonumber(itemId)
    end
    
    local itemConfig = shared.ITEMS_CONFIG[itemId]
    if not itemConfig then return false end
    return itemConfig.canHotbar ~= false
end

-- ========================================
-- DRAG & DROP - DA HOTBAR PARA INVENTORY
-- ========================================

function HotbarManager:startDrag(hotbarSlot)
    self.inventory.isDragging = true
    self.inventory.draggedHotbarSlot = hotbarSlot
    
    if self.inventory.scrollingFrame then
        self.inventory.scrollingFrame.ScrollingEnabled = false
    end
    
    local startPos = shared.UserInputService:GetMouseLocation()
    local slotTopLeft = hotbarSlot.gui.AbsolutePosition
    self.inventory.dragStartOffset = startPos - slotTopLeft
    self.inventory.ghostSize = hotbarSlot.gui.AbsoluteSize
    
    local ghostTopLeft = startPos - self.inventory.dragStartOffset
    self.inventory.lastDragPosition = ghostTopLeft
    GhostSlotCache.show(hotbarSlot.gui, UDim2.new(0, ghostTopLeft.X, 0, ghostTopLeft.Y))
    
    -- Atualização do ghost
    if self.inventory.isMobile then
        self.inventory.ghostUpdateConnection = shared.UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
            local currentPos = shared.UserInputService:GetMouseLocation()
            local ghostPos = currentPos - self.inventory.dragStartOffset
            GhostSlotCache.updatePosition(UDim2.new(0, ghostPos.X, 0, ghostPos.Y))
            self.inventory.lastDragPosition = ghostPos
            
            -- Detectar hover
            local hotbarSlotAtPosition = self:getHotbarSlotAtPosition(ghostPos, self.inventory.ghostSize)
            if hotbarSlotAtPosition then
                self.hoveredSlot = hotbarSlotAtPosition
                self.inventory.hoveredSlot = nil
            else
                self.hoveredSlot = nil
                local invSlotAtPosition = self.inventory:getSlotAtPosition(ghostPos, self.inventory.ghostSize)
                self.inventory.hoveredSlot = invSlotAtPosition
            end
        end)
    else
        self.inventory.ghostUpdateConnection = shared.RunService.RenderStepped:Connect(function()
            local currentPos = shared.UserInputService:GetMouseLocation()
            local ghostPos = currentPos - self.inventory.dragStartOffset
            GhostSlotCache.updatePosition(UDim2.new(0, ghostPos.X, 0, ghostPos.Y))
            self.inventory.lastDragPosition = ghostPos
            
            -- Detectar hover
            local hotbarSlotAtPosition = self:getHotbarSlotAtPosition(ghostPos, self.inventory.ghostSize)
            if hotbarSlotAtPosition then
                self.hoveredSlot = hotbarSlotAtPosition
                self.inventory.hoveredSlot = nil
            else
                self.hoveredSlot = nil
                local invSlotAtPosition = self.inventory:getSlotAtPosition(ghostPos, self.inventory.ghostSize)
                self.inventory.hoveredSlot = invSlotAtPosition
            end
        end)
    end
end

function HotbarManager:endDrag()
    if not self.inventory.isDragging or not self.inventory.draggedHotbarSlot then return end
    
    -- Limpar locks
    self.isLocked = false
    self.inventory.isLocked = false
    self.inventory.pendingServerResponse = false
    
    -- Reabilitar scroll
    if self.inventory.scrollingFrame then
        self.inventory.scrollingFrame.ScrollingEnabled = true
    end
    
    -- Parar ghost
    if self.inventory.ghostUpdateConnection then
        self.inventory.ghostUpdateConnection:Disconnect()
        self.inventory.ghostUpdateConnection = nil
    end
    GhostSlotCache.hide()
    
    local hotbarSlot = self.inventory.draggedHotbarSlot
    
    if hotbarSlot and hotbarSlot.gui and hotbarSlot.gui.Parent then
        print("🔍 [HOTBAR endDrag] Verificando onde soltou...")
        
        -- Verificar onde soltou
        local targetHotbarSlot = self.hoveredSlot
        if not targetHotbarSlot and self.inventory.lastDragPosition then
            targetHotbarSlot = self:getHotbarSlotAtPosition(self.inventory.lastDragPosition, self.inventory.ghostSize)
        end
        
        print("  - targetHotbarSlot:", targetHotbarSlot and targetHotbarSlot.slotIndex or "nil")
        print("  - inventory.hoveredSlot:", self.inventory.hoveredSlot and self.inventory.hoveredSlot.slotIndex or "nil")
        
        if targetHotbarSlot and targetHotbarSlot ~= hotbarSlot then
            print("  ➡️ Fazendo SWAP dentro da hotbar:", hotbarSlot.slotIndex, "↔", targetHotbarSlot.slotIndex)
            -- Swap dentro da hotbar
            self:swapHotbarSlots(hotbarSlot.slotIndex, targetHotbarSlot.slotIndex)
        else
            -- Verificar se soltou no inventory
            local targetInventorySlot = self.inventory.hoveredSlot
            if not targetInventorySlot and self.inventory.lastDragPosition then
                targetInventorySlot = self.inventory:getSlotAtPosition(self.inventory.lastDragPosition, self.inventory.ghostSize)
            end
            
            print("  - targetInventorySlot:", targetInventorySlot and targetInventorySlot.slotIndex or "nil")
            
            if targetInventorySlot then
                print("  ➡️ Movendo para inventory:")
                print("    - slotIndex:", targetInventorySlot.slotIndex)
                print("    - LayoutOrder:", targetInventorySlot.gui.LayoutOrder)
                print("    - isEmpty:", targetInventorySlot.isEmpty)
                print("    - itemId:", targetInventorySlot.itemId)
                print("    - gui.Name:", targetInventorySlot.gui.Name)
                
                -- Passar LayoutOrder (posição visual) do slot do inventory, não slotIndex
                local targetLayoutOrder = targetInventorySlot.gui.LayoutOrder
                self:moveToInventory(hotbarSlot.slotIndex, targetLayoutOrder)
            else
                print("  ⚠️ Não detectou nem hotbar nem inventory!")
            end
        end
        
        if shared.clickSound then shared.clickSound:Play() end
    end
    
    -- Setar isDragging = false NO FINAL
    self.inventory.isDragging = false
    
    -- Limpar referências
    self.hoveredSlot = nil
    self.inventory.draggedHotbarSlot = nil
    self.inventory.hoveredSlot = nil
    self.inventory.lastDragPosition = nil
    self.inventory.dragStartOffset = nil
    self.inventory.ghostSize = nil
    
    -- 🔒 BUG FIX: Aplicar update pendente se houver
    if self.pendingHotbarUpdate then
        local update = self.pendingHotbarUpdate
        self.pendingHotbarUpdate = nil
        self:updateHotbar(update)
    end
end

-- ========================================
-- OPERAÇÕES DE MOVIMENTAÇÃO
-- ========================================

function HotbarManager:swapHotbarSlots(fromIndex, toIndex)
    if self.isLocked then
        return
    end
    
    if not fromIndex or not toIndex or fromIndex == toIndex then
        return
    end
    
    if fromIndex < 1 or fromIndex > shared.MAX_HOTBAR_SLOTS or toIndex < 1 or toIndex > shared.MAX_HOTBAR_SLOTS then
        return
    end
    
    local fromSlot = self.hotbarSlots[fromIndex]
    local toSlot = self.hotbarSlots[toIndex]
    
    if not fromSlot or not toSlot or not fromSlot.gui or not toSlot.gui then
        return
    end
    
    self.isLocked = true
    
    -- 🔥 SWAP VISUAL (como o inventory faz) - APENAS troca LayoutOrder
    local tempLayoutOrder = fromSlot.gui.LayoutOrder
    fromSlot.gui.LayoutOrder = toSlot.gui.LayoutOrder
    toSlot.gui.LayoutOrder = tempLayoutOrder
    
    -- Atualizar slotIndex internos
    fromSlot.slotIndex = toIndex
    toSlot.slotIndex = fromIndex
    
    -- Atualizar atributos HotbarSlotId (para detecção de hover)
    fromSlot.gui:SetAttribute("HotbarSlotId", toIndex)
    toSlot.gui:SetAttribute("HotbarSlotId", fromIndex)
    
    for _, descendant in ipairs(fromSlot.gui:GetDescendants()) do
        descendant:SetAttribute("HotbarSlotId", toIndex)
    end
    for _, descendant in ipairs(toSlot.gui:GetDescendants()) do
        descendant:SetAttribute("HotbarSlotId", fromIndex)
    end
    
    -- Atualizar mapa hotbarSlots
    self.hotbarSlots[fromIndex] = toSlot
    self.hotbarSlots[toIndex] = fromSlot
    
    -- Atualizar números dos slots (TextLabel) para refletir a nova posição visual
    local fromTextLabel = fromSlot.gui:FindFirstChild("TextLabel")
    local toTextLabel = toSlot.gui:FindFirstChild("TextLabel")
    if fromTextLabel then
        fromTextLabel.Text = tostring(toIndex)
    end
    if toTextLabel then
        toTextLabel.Text = tostring(fromIndex)
    end
    
    -- Trocar dados internos
    local temp = self.hotbarData[fromIndex]
    self.hotbarData[fromIndex] = self.hotbarData[toIndex]
    self.hotbarData[toIndex] = temp
    
    -- Enviar ao servidor
    if shared.swapHotbarSlotsEvent then
        pcall(function()
            shared.swapHotbarSlotsEvent:FireServer(fromIndex, toIndex)
        end)
    end
    
    -- Destravar imediatamente (swap visual já foi feito)
    self.isLocked = false
end

function HotbarManager:moveToInventory(hotbarIndex, inventoryLayoutOrder)
    if self.isLocked or self.inventory.isLocked then
        return
    end
    
    local slotData = self.hotbarData[hotbarIndex]
    if not slotData then
        return
    end
    
    self.isLocked = true
    self.inventory.isLocked = true
    
    -- 📊 DEBUG: Log de movimentação
    local itemConfig = shared.ITEMS_CONFIG[slotData.itemId]
    local itemName = itemConfig and itemConfig.name or "Item #"..slotData.itemId
    print("⬅️ [MOVE] Hotbar slot "..hotbarIndex.." → Inventory LayoutOrder "..inventoryLayoutOrder.." ("..itemName.." x"..slotData.quantity..")")
    
    -- ⚠️ NÃO fazer update otimista para evitar bugs de posicionamento
    -- Items não-stackable criam uniqueIds complexos que podem causar inconsistências
    -- Melhor aguardar resposta do servidor (pequeno delay visual é aceitável)
    
    -- Enviar ao servidor
    if shared.moveHotbarToInventorySlotEvent then
        pcall(function()
            shared.moveHotbarToInventorySlotEvent:FireServer(hotbarIndex, inventoryLayoutOrder)
        end)
    end
    
    -- Timeout
    task.delay(5, function()
        if self.isLocked then
            self.isLocked = false
            self.inventory.isLocked = false
        end
    end)
end

function HotbarManager:useItem(slotIndex)
    local slotData = self.hotbarData[slotIndex]
    if not slotData then return end
    
    local itemConfig = shared.ITEMS_CONFIG[slotData.itemId]
    if not itemConfig then return end
    
    if shared.clickSound then shared.clickSound:Play() end
    
    -- TODO: Implementar uso do item
end

-- ========================================
-- EVENTOS
-- ========================================

function HotbarManager:connectEvents()
    -- Toggle hotbar (Left Alt)
    table.insert(self.connections, shared.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= shared.HOTBAR_TOGGLE_KEY then return end
        
        if shared.clickSound then shared.clickSound:Play() end
        self.container.Visible = not self.container.Visible
    end))
    
    -- Teclas numéricas (1-4)
    table.insert(self.connections, shared.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local slotIndex
        if input.KeyCode == Enum.KeyCode.One then slotIndex = 1
        elseif input.KeyCode == Enum.KeyCode.Two then slotIndex = 2
        elseif input.KeyCode == Enum.KeyCode.Three then slotIndex = 3
        elseif input.KeyCode == Enum.KeyCode.Four then slotIndex = 4
        end
        
        if slotIndex then
            self:useItem(slotIndex)
        end
    end))
    
    -- Update do servidor
    if shared.updateHotbarEvent then
        table.insert(self.connections, shared.updateHotbarEvent.OnClientEvent:Connect(function(hotbar)
            if hotbar and type(hotbar) == "table" then
                self:updateHotbar(hotbar)
                
                -- Destravar locks
                if self.isLocked then
                    self.isLocked = false
                end
                if self.inventory and self.inventory.pendingServerResponse then
                    self.inventory.isLocked = false
                    self.inventory.pendingServerResponse = false
                end
            end
        end))
    end
end

function HotbarManager:destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    
    for _, slot in pairs(self.hotbarSlots) do
        slot:destroy()
    end
    
    self.hotbarSlots = {}
    self.connections = {}
end

return HotbarManager
