-- ========================================
-- CLASSE: Inventory
-- ========================================
-- Gerenciador principal do inventário do jogador

local shared = require(script.Parent.shared)
local GhostSlotCache = require(script.Parent["ghost-slot-cache"])
local InventorySlot = require(script.Parent["inventory-slot"])

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
    local self = setmetatable({}, Inventory)
    
    -- Referências de UI (cache)
    self.container = nil
    self.background = nil  -- Background do inventário (é isso que escondemos/mostramos)
    self.scrollingFrame = nil
    self.tooltip = nil
    self.itemSlotTemplate = nil  -- Template para slots com item
    self.emptySlotTemplate = nil  -- Template para slots vazios
    self.parentGui = nil
    
    -- Estado
    self.slots = {}  -- Array de slots fixos [1..MAX_SLOTS]
    self.slotsMap = {} -- {[slotIndex] = InventorySlot} para lookup rápido
    self.playerItems = {}
    self.itemsOrder = {}  -- {[itemId_slotIndex] = slotPosition}
    
    -- Drag state
    self.isDragging = false
    self.draggedSlot = nil
    self.draggedHotbarSlot = nil  -- Slot da hotbar sendo arrastado
    self.hoveredSlot = nil  -- Slot que está sendo "hovered" durante o drag
    self.lastDragPosition = nil  -- Última posição conhecida durante o drag (para mobile)
    self.dragStartOffset = nil  -- Offset do cursor em relação ao canto do slot
    self.ghostSize = nil  -- Tamanho do ghost para detecção precisa
    self.ghostUpdateConnection = nil
    
    -- Input type (detecta automaticamente se está usando touch ou mouse)
    self.isMobile = shared.IS_MOBILE
    
    -- Tooltip state
    self.currentTooltipSlot = nil
    self.tooltipHideTask = nil
    
    -- Save order debounce (evitar spam ao DataStore)
    self.saveOrderTask = nil
    self.saveOrderDelay = 1.0  -- Aguardar 1 segundo antes de salvar
    self.pendingSave = false
    
    -- Pending update (aguardar drag terminar)
    self.pendingUpdate = nil
    
    -- 🔒 Transaction lock (prevenir operações simultâneas e duplicação)
    self.isLocked = false
    self.pendingServerResponse = false
    
    -- Referência para hotbar (será definida após inicialização)
    self.hotbar = nil
    
    -- Conexões
    self.connections = {}
    
    return self
end

function Inventory:initialize()
    pcall(function() shared.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
    
    -- Buscar elementos de UI
    local playerGui = shared.player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:WaitForChild("INVENTARIO_NOVO", 10)
    if not inventoryGui then return warn("INVENTARIO_NOVO não encontrado!") end
    
    self.parentGui = inventoryGui
    self.container = inventoryGui:FindFirstChild("container")
    if not self.container then return warn("Container não encontrado!") end
    
    self.background = self.container:FindFirstChild("background")
    if not self.background then return warn("Background não encontrado!") end
    
    self.scrollingFrame = self.background:FindFirstChild("ScrollingFrame")
    self.tooltip = self.background:FindFirstChild("ItemInfoTooltip")
    local closeButton = self.background:FindFirstChild("Close")
    
    if not self.scrollingFrame then return warn("ScrollingFrame não encontrado!") end
    if not self.tooltip then return warn("ItemInfoTooltip não encontrado!") end
    if not closeButton then return warn("Close button não encontrado!") end
    
    self.itemSlotTemplate = self.scrollingFrame:FindFirstChild("itemSlot")
    self.emptySlotTemplate = self.scrollingFrame:FindFirstChild("emptySlot")
    
    if not self.itemSlotTemplate then return warn("itemSlot template não encontrado!") end
    if not self.emptySlotTemplate then return warn("emptySlot template não encontrado!") end
    
    self.itemSlotTemplate.Visible = false
    self.emptySlotTemplate.Visible = false
    
    -- Esconder apenas o background, não o container (hotbar fica visível)
    self.background.Visible = false
    self.tooltip.Visible = false
    
    -- Preparar ghost cache (usa itemSlot como base)
    GhostSlotCache.prepare(self.itemSlotTemplate, self.parentGui)
    
    -- Carregar itens do servidor
    self:loadItems()
    
    -- Detectar mudanças de tipo de input (para dispositivos híbridos)
    self:setupInputTypeDetection()
    
    -- Conectar eventos
    self:connectEvents(closeButton)
    
    return true
end

function Inventory:setupInputTypeDetection()
    -- Detectar mudanças entre touch/mouse/gamepad em tempo real
    table.insert(self.connections, shared.UserInputService.LastInputTypeChanged:Connect(function(inputType)
        local wasMobile = self.isMobile
        
        -- Atualizar estado baseado no tipo de input
        if inputType == Enum.UserInputType.Touch then
            self.isMobile = true
        elseif inputType == Enum.UserInputType.MouseButton1 or 
               inputType == Enum.UserInputType.MouseButton2 or
               inputType == Enum.UserInputType.MouseMovement then
            self.isMobile = false
        end
        
        -- Se mudou, atualizar silenciosamente
        if wasMobile ~= self.isMobile then
            -- Input type changed
        end
    end))
end

function Inventory:loadItems()
    if not shared.getPlayerItemsFunction then
        return warn("⚠️ GetPlayerItems RemoteFunction não encontrado!")
    end
    
    local success, serverData = pcall(function()
        return shared.getPlayerItemsFunction:InvokeServer()
    end)
    
    if success and serverData and type(serverData) == "table" then
        local serverItems = serverData.items or serverData
        local serverOrder = serverData.order or {}
        self:updateItems(serverItems, serverOrder)
    else
        warn("❌ Erro ao carregar itens do jogador")
    end
    
    return
end

function Inventory:updateItems(serverItems, serverOrder)
    -- 🔒 BUG FIX #1: Prevenir rebuild durante drag ativo
    if self.isDragging then
        -- Salvar update pendente para aplicar depois
        self.pendingUpdate = {
            items = serverItems,
            order = serverOrder
        }
        return
    end
    
    -- 🔧 serverItems agora já vem com formato completo: {[itemId] = {item, quantity}}
    self.playerItems = serverItems
    
    -- Carregar ordem salva dos itens
    if serverOrder and type(serverOrder) == "table" then
        self.itemsOrder = serverOrder
    end
    
    self:rebuildSlots()
end

function Inventory:rebuildSlots()
    -- Limpar slots antigos
    for _, slot in pairs(self.slotsMap) do
        slot:destroy()
    end
    self.slotsMap = {}
    self.slots = {}
    
    -- Criar mapa de itens expandidos (considerando stackable)
    local itemsToPlace = {}  -- {[uniqueId] = {id, data}}
    local needsAutoSave = false  -- Flag para saber se precisa salvar a ordem
    
    for itemId, itemData in pairs(self.playerItems) do
        local isStackable = itemData.item.stackable == true
        local quantity = itemData.quantity or 1
        
        if isStackable then
            -- Item stackável: criar apenas 1 entrada com toda a quantidade
            local uniqueId = tostring(itemId)
            itemsToPlace[uniqueId] = {
                id = itemId,
                data = itemData
            }
        else
            -- Item NÃO stackável: criar 1 entrada para cada unidade
            for unitIndex = 1, quantity do
                local uniqueId = tostring(itemId) .. "_" .. tostring(unitIndex)
                itemsToPlace[uniqueId] = {
                    id = itemId,
                    data = {
                        item = itemData.item,
                        quantity = 1  -- Cada slot mostra apenas 1 item
                    }
                }
            end
        end
    end
    
    -- Criar MAX_SLOTS slots fixos
    for slotIndex = 1, shared.MAX_SLOTS do
        local itemInSlot = nil
        local itemId = nil
        local itemData = nil
        
        -- Verificar se há um item salvo para esta posição (compara com LayoutOrder que será criado)
        for uniqueId, savedLayoutOrder in pairs(self.itemsOrder) do
            if savedLayoutOrder == slotIndex and itemsToPlace[uniqueId] then
                itemInSlot = itemsToPlace[uniqueId]
                itemId = itemInSlot.id
                itemData = itemInSlot.data
                itemsToPlace[uniqueId] = nil  -- Marcar como usado
                break
            end
        end
        
        -- Criar slot (vazio ou com item)
        local gui
        if itemInSlot then
            gui = self.itemSlotTemplate:Clone()
            gui.Name = "ItemSlot_" .. slotIndex
        else
            gui = self.emptySlotTemplate:Clone()
            gui.Name = "EmptySlot_" .. slotIndex
        end
        
        gui.Visible = true
        gui.LayoutOrder = slotIndex  -- LayoutOrder = posição visual (1 a MAX_SLOTS)
        gui.Parent = self.scrollingFrame
        
        -- Marcar GUI e descendentes com SlotId (atributo nativo - armazenado em C!)
        gui:SetAttribute("SlotId", slotIndex)
        for _, descendant in ipairs(gui:GetDescendants()) do
            descendant:SetAttribute("SlotId", slotIndex)
        end
        
        local slot = InventorySlot.new(gui, slotIndex, itemId, itemData, self)
        self.slotsMap[slotIndex] = slot
        self.slots[slotIndex] = slot
    end
    
    -- DEPOIS de criar todos os slots, verificar se sobrou algum item sem posição
    for uniqueId, item in pairs(itemsToPlace) do
        -- Encontrar o primeiro slot vazio disponível
        for slotIndex = 1, shared.MAX_SLOTS do
            local slot = self.slotsMap[slotIndex]
            if slot.isEmpty then
                local layoutOrder = slot.gui.LayoutOrder
                -- Destruir slot vazio e criar slot com item
                slot:destroy()
                
                local gui = self.itemSlotTemplate:Clone()
                gui.Name = "ItemSlot_" .. slotIndex
                gui.Visible = true
                gui.LayoutOrder = layoutOrder
                gui.Parent = self.scrollingFrame
                
                -- Marcar GUI e descendentes com SlotId (atributo nativo - armazenado em C!)
                gui:SetAttribute("SlotId", slotIndex)
                for _, descendant in ipairs(gui:GetDescendants()) do
                    descendant:SetAttribute("SlotId", slotIndex)
                end
                
                local newSlot = InventorySlot.new(gui, slotIndex, item.id, item.data, self)
                self.slotsMap[slotIndex] = newSlot
                self.slots[slotIndex] = newSlot
                
                -- Salvar a posição visual (LayoutOrder)
                self.itemsOrder[uniqueId] = layoutOrder
                needsAutoSave = true
                break
            end
        end
    end
    
    -- Se algum item novo foi colocado, salvar a ordem automaticamente
    if needsAutoSave then
        self:saveOrder()
    end
end

function Inventory:startDrag(slot)
    self.isDragging = true
    self.draggedSlot = slot
    
    -- Desabilitar scroll durante o drag (importante para mobile!)
    if self.scrollingFrame then
        self.scrollingFrame.ScrollingEnabled = false
    end
    
    -- Posição inicial do cursor/touch (usar GetMouseLocation() que funciona em ambas plataformas)
    local startPos = shared.UserInputService:GetMouseLocation()
    
    -- Calcular offset entre cursor e canto superior esquerdo do slot (para manter posição relativa)
    local slotTopLeft = slot.gui.AbsolutePosition
    self.dragStartOffset = startPos - slotTopLeft
    self.ghostSize = slot.gui.AbsoluteSize  -- Salvar tamanho para detecção precisa
    
    -- Posição do ghost (canto superior esquerdo)
    local ghostTopLeft = startPos - self.dragStartOffset
    self.lastDragPosition = ghostTopLeft  -- Salvar posição do canto do ghost
    GhostSlotCache.show(slot.gui, UDim2.new(0, ghostTopLeft.X, 0, ghostTopLeft.Y))
    
    
    -- Atualização de posição do ghost (RenderStepped ou TouchMoved)
    if self.isMobile then
        -- Mobile: seguir o toque atual em tempo real
        self.ghostUpdateConnection = shared.UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
            -- Usar GetMouseLocation() para consistência (já inclui GUI Inset)
            local currentPos = shared.UserInputService:GetMouseLocation()
            
            -- Aplicar offset para manter posição relativa do ghost
            local ghostPos = currentPos - self.dragStartOffset
            GhostSlotCache.updatePosition(UDim2.new(0, ghostPos.X, 0, ghostPos.Y))
            
            -- Salvar a posição do GHOST (não do cursor) para detecção de slot
            self.lastDragPosition = ghostPos
            
            -- 🔥 DETECTAR HOTBAR PRIMEIRO, depois inventory
            local hotbarSlotAtPosition = self.hotbar and self.hotbar:getHotbarSlotAtPosition(ghostPos, self.ghostSize)
            if hotbarSlotAtPosition then
                self.hotbar.hoveredSlot = hotbarSlotAtPosition
                self.hoveredSlot = nil
            else
                self.hotbar.hoveredSlot = nil
                -- Atualizar hoveredSlot baseado na posição do GHOST (não do cursor)
                local slotAtPosition = self:getSlotAtPosition(ghostPos, self.ghostSize)
                if slotAtPosition and slotAtPosition ~= self.draggedSlot then
                    self.hoveredSlot = slotAtPosition
                else
                    self.hoveredSlot = nil
                end
            end
        end)
    else
        -- PC: seguir o mouse (RenderStepped para atualização suave a cada frame)
        self.ghostUpdateConnection = shared.RunService.RenderStepped:Connect(function()
            local currentPos = shared.UserInputService:GetMouseLocation()
            
            -- Aplicar offset para manter posição relativa do ghost
            local ghostPos = currentPos - self.dragStartOffset
            GhostSlotCache.updatePosition(UDim2.new(0, ghostPos.X, 0, ghostPos.Y))
            
            -- Salvar a posição do GHOST (não do cursor) para detecção de slot
            self.lastDragPosition = ghostPos
            
            -- 🔥 DETECTAR HOTBAR PRIMEIRO, depois inventory
            local hotbarSlotAtPosition = self.hotbar and self.hotbar:getHotbarSlotAtPosition(ghostPos, self.ghostSize)
            if hotbarSlotAtPosition then
                self.hotbar.hoveredSlot = hotbarSlotAtPosition
                self.hoveredSlot = nil
            else
                if self.hotbar then
                    self.hotbar.hoveredSlot = nil
                end
                -- Atualizar hoveredSlot baseado na posição do GHOST (não do cursor)
                local slotAtPosition = self:getSlotAtPosition(ghostPos, self.ghostSize)
                if slotAtPosition and slotAtPosition ~= self.draggedSlot then
                    self.hoveredSlot = slotAtPosition
                else
                    self.hoveredSlot = nil
                end
            end
        end)
    end
end

function Inventory:endDrag()
    if not self.isDragging then return end
    
    -- 🔒 REFACTOR: Limpar TODOS os locks ANTES de processar operações
    self.isLocked = false
    self.pendingServerResponse = false
    if self.hotbar then
        self.hotbar.isLocked = false
    end
    
    -- Reabilitar scroll
    if self.scrollingFrame then
        self.scrollingFrame.ScrollingEnabled = true
    end
    
    -- Parar atualização de ghost
    if self.ghostUpdateConnection then
        self.ghostUpdateConnection:Disconnect()
        self.ghostUpdateConnection = nil
    end
    
    GhostSlotCache.hide()
    
    -- 🔒 BUG FIX #11: Validar se draggedSlot ainda é válido
    if self.draggedSlot and self.draggedSlot.gui and self.draggedSlot.gui.Parent then
        -- Verificar se soltou em cima de um slot da hotbar
        local hotbarSlot = self.hotbar and self.hotbar.hoveredSlot
        
        -- Se não detectou pelo evento MouseEnter, tentar detectar pela posição
        if not hotbarSlot and self.hotbar and self.lastDragPosition then
            hotbarSlot = self.hotbar:getHotbarSlotAtPosition(self.lastDragPosition, self.ghostSize)
        end
        
        if hotbarSlot then
            -- Mover item do inventário para a hotbar
            self:moveToHotbar(self.draggedSlot, hotbarSlot.slotIndex)
            if self.hotbar then
                self.hotbar.hoveredSlot = nil
            end
        else
            
            -- Verificar swap normal entre slots do inventário
            local targetSlot = self.hoveredSlot
            
            -- Se não tem hoveredSlot, usar a última posição conhecida do drag
            if not targetSlot and self.lastDragPosition then
                targetSlot = self:getSlotAtPosition(self.lastDragPosition, self.ghostSize)
            end
            
            -- Se encontrou um slot válido e diferente do arrastado, fazer swap
            if targetSlot and targetSlot ~= self.draggedSlot then
                self:swapSlots(targetSlot)
            end
            
            self:saveOrder()
        end
        
        if shared.clickSound then shared.clickSound:Play() end
    end
    
    -- 🔒 REFACTOR: Setar isDragging = false APENAS NO FINAL (após processar tudo)
    self.isDragging = false
    
    -- Limpar referências
    self.draggedSlot = nil
    self.hoveredSlot = nil
    self.lastDragPosition = nil
    self.dragStartOffset = nil
    self.ghostSize = nil
    
    -- 🔒 BUG FIX #1: Aplicar update pendente se houver
    if self.pendingUpdate then
        local update = self.pendingUpdate
        self.pendingUpdate = nil
        self:updateItems(update.items, update.order)
    end
    
    -- 🔒 BUG FIX: Aplicar update pendente da hotbar se houver
    if self.hotbar and self.hotbar.pendingHotbarUpdate then
        local hotbarUpdate = self.hotbar.pendingHotbarUpdate
        self.hotbar.pendingHotbarUpdate = nil
        self.hotbar:updateHotbar(hotbarUpdate)
    end
end

function Inventory:getSlotAtPosition(ghostTopLeft, ghostSize)
    -- OTIMIZADO: Verifica apenas o centro do ghost (mais rápido e já funciona bem)
    local playerGui = shared.player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    -- Calcular centro do ghost para detecção
    local size = ghostSize or Vector2.new(37, 40)
    local ghostCenter = ghostTopLeft + (size / 2)
    
    -- Obter objetos na posição do centro
    local guiObjects = playerGui:GetGuiObjectsAtPosition(ghostCenter.X, ghostCenter.Y)
    
    for _, guiObject in ipairs(guiObjects) do
        -- Pular ghost diretamente (mais rápido que verificar hierarquia)
        if guiObject.Name == "GhostSlot" then continue end
        
        -- Verificar atributo SlotId diretamente
        local slotId = guiObject:GetAttribute("SlotId")
        if slotId then
            return self.slotsMap[slotId]
        end
    end
    
    return nil
end

function Inventory:moveToHotbar(inventorySlot, hotbarSlotIndex)
    if not inventorySlot or inventorySlot.isEmpty or not self.hotbar then return end
    
    -- 🐛 BUG FIX: itemId pode vir como string do servidor
    -- playerItems usa string, ITEMS_CONFIG usa número
    local itemIdOriginal = inventorySlot.itemId  -- Manter original (string) para playerItems
    local itemIdNum = type(itemIdOriginal) == "string" and tonumber(itemIdOriginal) or itemIdOriginal
    
    local itemConfig = shared.ITEMS_CONFIG[itemIdNum]
    
    -- Verificar se item pode ir para hotbar (usa itemIdNum para ITEMS_CONFIG)
    if not self.hotbar:canReceiveItem(itemIdNum) then
        return
    end
    
    -- Quantidade a mover (quantidade total do slot)
    local quantity = inventorySlot.itemData.quantity or 1
    
    -- 🔒 REFACTOR: Verificação simplificada de locks
    if self.isLocked or self.pendingServerResponse then
        return
    end
    
    -- ✅ VALIDAR quantidade ANTES de modificar (usa itemIdOriginal - string)
    local itemData = self.playerItems[itemIdOriginal]
    if not itemData or itemData.quantity < quantity then
        return
    end
    
    -- 🚨 BUG FIX DUPLICAÇÃO #1: Verificar se slot da hotbar já está ocupado
    -- Se estiver, avisar que o servidor fará swap automático e NÃO fazer update otimista
    local hotbarSlotData = self.hotbar.hotbarData[hotbarSlotIndex]
    local willDoSwap = hotbarSlotData ~= nil
    
    -- 🔒 Travar operações
    self.isLocked = true
    self.pendingServerResponse = true
    
    -- Logs de debug removidos
    
    -- ✨ UPDATE OTIMISTA: Apenas se NÃO houver swap (swap é complexo, deixar servidor lidar)
    if not willDoSwap then
        -- 1. Atualizar hotbar localmente (slot vazio) - usar itemIdNum para consistência
        self.hotbar.hotbarData[hotbarSlotIndex] = {
            itemId = itemIdNum,
            quantity = quantity
        }
        self.hotbar:rebuildSlots()
        
        -- 2. Remover do inventário localmente (usar itemIdOriginal - string)
        local newQuantity = itemData.quantity - quantity
        if newQuantity <= 0 then
            -- Remover completamente
            self.playerItems[itemIdOriginal] = nil
        else
            -- Apenas diminuir quantidade
            itemData.quantity = newQuantity
        end
        
        -- Rebuild do inventário
        self:rebuildSlots()
    end
    
    -- 3. Enviar ao servidor (servidor é a fonte da verdade, vai corrigir se houver erro)
    -- Usar itemIdNum (número) para o servidor
    if shared.setHotbarSlotEvent then
        local success, err = pcall(function()
            shared.setHotbarSlotEvent:FireServer(hotbarSlotIndex, itemIdNum, quantity)
        end)
        
        if not success then
            -- 🚨 BUG FIX #3: Em caso de erro, destravar imediatamente
            self.isLocked = false
            self.pendingServerResponse = false
        end
    else
        self.isLocked = false
        self.pendingServerResponse = false
    end
    
    -- 🚨 BUG FIX #3: Destravar APENAS quando servidor responder (não mais após delay fixo)
    -- O servidor enviará UpdateHotbar e UpdatePlayerItems, que destravará automaticamente
    -- Mas colocar um timeout de segurança de 5s
    task.delay(5.0, function()
        if self.pendingServerResponse then
            self.isLocked = false
            self.pendingServerResponse = false
        end
    end)
end

function Inventory:swapSlots(targetSlot)
    if not self.draggedSlot or not targetSlot.gui.Visible then return end
    
    -- 🔒 REFACTOR: Verificação simplificada de locks
    if self.isLocked then
        return
    end
    
    self.isLocked = true
    
    -- Trocar os slots de posição (swap visual)
    local draggedSlotIndex = self.draggedSlot.slotIndex
    local targetSlotIndex = targetSlot.slotIndex
    
    -- Trocar LayoutOrder visualmente
    local tempLayoutOrder = self.draggedSlot.gui.LayoutOrder
    self.draggedSlot.gui.LayoutOrder = targetSlot.gui.LayoutOrder
    targetSlot.gui.LayoutOrder = tempLayoutOrder
    
    -- Trocar slotIndex internamente
    self.draggedSlot.slotIndex = targetSlotIndex
    targetSlot.slotIndex = draggedSlotIndex
    
    -- OTIMIZADO: Atualizar apenas o SlotId do GUI principal (não dos descendentes)
    -- GetSlotAtPosition verifica o atributo no objeto detectado, que pode ser qualquer descendente
    -- Por isso precisamos atualizar nos GUIs principais E descendentes
    self.draggedSlot.gui:SetAttribute("SlotId", targetSlotIndex)
    targetSlot.gui:SetAttribute("SlotId", draggedSlotIndex)
    
    for _, descendant in ipairs(self.draggedSlot.gui:GetDescendants()) do
        descendant:SetAttribute("SlotId", targetSlotIndex)
    end
    for _, descendant in ipairs(targetSlot.gui:GetDescendants()) do
        descendant:SetAttribute("SlotId", draggedSlotIndex)
    end
    
    -- Atualizar mapa
    self.slotsMap[draggedSlotIndex] = targetSlot
    self.slotsMap[targetSlotIndex] = self.draggedSlot
    self.slots[draggedSlotIndex] = targetSlot
    self.slots[targetSlotIndex] = self.draggedSlot
    
    -- 🔓 Destravar
    self.isLocked = false
end

function Inventory:saveOrder()
    -- OTIMIZADO: Debounce para evitar spam ao DataStore
    -- Marca que há uma salvamento pendente
    self.pendingSave = true
    
    -- Cancela o timer anterior se existir
    if self.saveOrderTask then
        task.cancel(self.saveOrderTask)
    end
    
    -- Agenda um novo salvamento após o delay
    self.saveOrderTask = task.delay(self.saveOrderDelay, function()
        if not self.pendingSave then return end
        
        self.pendingSave = false
        self.saveOrderTask = nil
        
        -- Calcular ordem atual
        local newOrder = {}
        
        -- Percorrer slots ordenados por LayoutOrder (posição visual)
        local sortedSlots = {}
        for slotIndex, slot in pairs(self.slotsMap) do
            sortedSlots[#sortedSlots + 1] = slot
        end
        table.sort(sortedSlots, function(a, b) return a.gui.LayoutOrder < b.gui.LayoutOrder end)
        
        -- Rastrear quantas unidades de cada item não-stackável já foram processadas
        local nonStackableCounters = {}
        
        for _, slot in ipairs(sortedSlots) do
            if not slot.isEmpty and slot.itemId then
                local itemConfig = shared.ITEMS_CONFIG[slot.itemId]
                local layoutOrder = slot.gui.LayoutOrder  -- Posição visual
                
                if itemConfig and itemConfig.stackable then
                    -- Item stackável: usar apenas o itemId
                    local uniqueId = tostring(slot.itemId)
                    newOrder[uniqueId] = layoutOrder
                else
                    -- Item não-stackável: incrementar contador e criar uniqueId
                    if not nonStackableCounters[slot.itemId] then
                        nonStackableCounters[slot.itemId] = 0
                    end
                    nonStackableCounters[slot.itemId] = nonStackableCounters[slot.itemId] + 1
                    local uniqueId = tostring(slot.itemId) .. "_" .. tostring(nonStackableCounters[slot.itemId])
                    newOrder[uniqueId] = layoutOrder
                end
            end
        end
        
        self.itemsOrder = newOrder
        
        -- Enviar ao servidor apenas 1 vez após o delay
        if shared.reorderItemsEvent then
            pcall(function() shared.reorderItemsEvent:FireServer(newOrder) end)
        end
    end)
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
        if shared.clickSound then shared.clickSound:Play() end
        self.background.Visible = false
        shared.enableNativeUI()
    end)
    
    closeButton.MouseEnter:Connect(function()
        if shared.hoverSound then shared.hoverSound:Play() end
    end)
    
    -- Toggle key
    table.insert(self.connections, shared.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= shared.INVENTORY_TOGGLE_KEY then return end
        
        if shared.clickSound then shared.clickSound:Play() end
        self.background.Visible = not self.background.Visible
        
        if self.background.Visible then
            shared.disableNativeUI()
        else
            shared.enableNativeUI()
        end
    end))
    
    -- Mouse release (event-driven, não polling!)
    table.insert(self.connections, shared.UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        
        -- Cancelar drags pendentes de TODOS os slots do inventário
        for _, slot in pairs(self.slotsMap) do
            slot:cancelDrag()
        end
        
        -- Cancelar drags pendentes da hotbar
        if self.hotbar then
            for _, hotbarSlot in pairs(self.hotbar.hotbarSlots) do
                hotbarSlot:cancelDrag()
            end
        end
        
        -- Finalizar drag (inventário ou hotbar)
        if self.draggedHotbarSlot then
            self.hotbar:endDrag()
        else
            self:endDrag()
        end
        
        -- Garantir que o scroll está reabilitado (fallback de segurança)
        if self.scrollingFrame then
            self.scrollingFrame.ScrollingEnabled = true
        end
    end))
    
    -- Server updates
    if shared.updatePlayerItemsEvent then
        table.insert(self.connections, shared.updatePlayerItemsEvent.OnClientEvent:Connect(function(serverData)
            if serverData and type(serverData) == "table" then
                -- Servidor pode enviar {items = {...}, order = {...}} ou apenas {...}
                local serverItems = serverData.items or serverData
                local serverOrder = serverData.order or self.itemsOrder  -- Manter ordem atual se não vier nova
                self:updateItems(serverItems, serverOrder)
                
                -- 🚨 BUG FIX #3: Destravar locks quando servidor responder
                if self.pendingServerResponse then
                    self.isLocked = false
                    self.pendingServerResponse = false
                end
            end
        end))
    end
end

function Inventory:destroy()
    -- Cleanup completo para evitar memory leaks
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    
    if self.ghostUpdateConnection then
        self.ghostUpdateConnection:Disconnect()
        self.ghostUpdateConnection = nil
    end
    
    if self.tooltipHideTask then
        task.cancel(self.tooltipHideTask)
        self.tooltipHideTask = nil
    end
    
    if self.saveOrderTask then
        task.cancel(self.saveOrderTask)
        self.saveOrderTask = nil
    end
    
    for _, slot in pairs(self.slotsMap) do
        slot:destroy()
    end
    
    -- Limpar ghost cache completamente
    GhostSlotCache.cleanup()
    
    -- Limpar referências
    self.slotsMap = {}
    self.slots = {}
    self.connections = {}
end

return Inventory



