local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local clickSound = StarterGui:WaitForChild("clicksound", 5)
local hoverSound = StarterGui:WaitForChild("hoversound", 5)

local INVENTORY_TOGGLE_KEY = Enum.KeyCode.Backquote

-- Importar config de itens (shared)
local ITEMS_MODULE = require(ReplicatedStorage.Shared.itens)
local ITEMS_CONFIG = ITEMS_MODULE.list

-- RemoteEvents para sistema de itens
local getPlayerItemsFunction = ReplicatedStorage:WaitForChild("GetPlayerItems", 10)
local updatePlayerItemsEvent = ReplicatedStorage:WaitForChild("UpdatePlayerItems", 10)

-- Cache local dos itens do jogador
local playerItems = {} -- {itemId -> {item: itemConfig, quantity: number}}

-- Combina dados do servidor (IDs e quantidades) com config local
local function combineItemsWithConfig(serverItems)
    local combined = {}
    
    for itemId, quantity in pairs(serverItems) do
        local itemConfig = ITEMS_CONFIG[itemId]
        if itemConfig then
            combined[itemId] = {
                item = itemConfig,
                quantity = quantity
            }
        else
            warn("⚠️ Item ID " .. itemId .. " não encontrado na config!")
        end
    end
    
    return combined
end

-- Carrega itens do servidor
local function loadPlayerItems()
    if not getPlayerItemsFunction then
        warn("⚠️ GetPlayerItems RemoteFunction não encontrado!")
        return
    end
    
    local success, serverItems = pcall(function()
        return getPlayerItemsFunction:InvokeServer()
    end)
    
    if success and serverItems and type(serverItems) == "table" then
        -- Combinar dados do servidor com config local
        playerItems = combineItemsWithConfig(serverItems)
    else
        warn("⚠️ Erro ao carregar itens do jogador")
        playerItems = {}
    end
end

local function updateTooltipContent(tooltip, slot)
    -- Buscar elementos dentro da tooltip
    local title = tooltip:FindFirstChild("title")
    local description = tooltip:FindFirstChild("description")
    
    -- Pegar dados do item real
    local itemId = slot:GetAttribute("ItemId")
    if not itemId or not playerItems[itemId] then
        if title and title:IsA("TextLabel") then
            title.Text = "Item Desconhecido"
        end
        if description and description:IsA("TextLabel") then
            description.Text = "Sem descrição disponível"
        end
        return
    end
    
    local itemData = playerItems[itemId]
    local itemName = itemData.item.name or "Item #" .. itemId
    
    if title and title:IsA("TextLabel") then
        title.Text = itemName
    end
    
    if description and description:IsA("TextLabel") then
        -- Você pode adicionar descrição nos itens futuramente
        description.Text = itemData.item.description
    end
end

-- Cria slots visuais para os itens
local function createItemSlots(scrollingFrame)
    -- Limpar slots existentes (exceto o template)
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "Slot" then
            child:Destroy()
        end
    end
    
    -- Buscar template
    local slotTemplate = scrollingFrame:FindFirstChild("Slot")
    if not slotTemplate then
        warn("⚠️ Slot template não encontrado!")
        return
    end
    
    slotTemplate.Visible = false
    
    -- Criar slot para cada item
    for itemId, itemData in pairs(playerItems) do
        local newSlot = slotTemplate:Clone()
        newSlot.Name = "ItemSlot_" .. itemId
        newSlot.Visible = true
        newSlot:SetAttribute("ItemId", itemId)
        
        -- Atualizar visual do slot
        local quantity = itemData.quantity or 0
        
        -- Se o slot tiver um TextLabel para quantidade
        local itemQuantityLabel = newSlot:FindFirstChild("ItemQuantity")
        if itemQuantityLabel and itemQuantityLabel:IsA("TextLabel") then
            itemQuantityLabel.Text = tostring(quantity)..'x'
        end
        
        -- Se o slot tiver cor configurada, aplicar no UIGradient
        if itemData.item.color then
            local uiGradient = newSlot:FindFirstChild("UIGradient")
            if uiGradient and uiGradient:IsA("UIGradient") then
                -- Aplicar cor no gradient (ajuste o ColorSequence conforme necessário)
                uiGradient.Color = ColorSequence.new(itemData.item.color)
            end
        end
        
        newSlot.Parent = scrollingFrame
    end
end

local function setupSlotTooltips(scrollingFrame, tooltip)
    local currentSlot = nil
    local currentHideTask = nil
    
    local function connectSlot(slot)
        slot.MouseEnter:Connect(function()
            if hoverSound then
                hoverSound:Play()
            end
            
            currentSlot = slot
            
            if currentHideTask then
                task.cancel(currentHideTask)
                currentHideTask = nil
            end
            
            updateTooltipContent(tooltip, slot)
            tooltip.Visible = true
        end)
        
        slot.MouseLeave:Connect(function()
            if currentSlot == slot then
                currentSlot = nil
            end
            
            if currentHideTask then
                task.cancel(currentHideTask)
            end
            
            currentHideTask = task.delay(0.1, function()
                if not currentSlot then
                    tooltip.Visible = false
                end
                currentHideTask = nil
            end)
        end)
    end
    
    -- Conectar slots existentes
    for _, slot in ipairs(scrollingFrame:GetChildren()) do
        if slot:IsA("TextButton") and slot.Name ~= "Slot" then
            connectSlot(slot)
        end
    end
    
    -- Conectar novos slots adicionados dinamicamente
    scrollingFrame.ChildAdded:Connect(function(child)
        if child:IsA("TextButton") and child.Name ~= "Slot" then
            connectSlot(child)
        end
    end)
end

-- Atualiza o inventário quando recebe update do servidor
local function onItemsUpdated(serverItems)
    if not serverItems or type(serverItems) ~= "table" then
        return
    end
    
    -- Combinar dados do servidor com config local e atualizar cache
    playerItems = combineItemsWithConfig(serverItems)
    
    -- Recriar slots visuais
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local inventoryGui = playerGui:FindFirstChild("INVENTARIO_NOVO")
    if not inventoryGui then return end
    
    local container = inventoryGui:FindFirstChild("container")
    if not container then return end
    
    local background = container:FindFirstChild("background")
    if not background then return end
    
    local scrollingFrame = background:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return end
    
    createItemSlots(scrollingFrame)
end

local function setupInventory()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
    
    -- Carregar itens do servidor
    loadPlayerItems()
    
    local playerGui = player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:WaitForChild("INVENTARIO_NOVO", 10)
    
    if not inventoryGui then
        warn("INVENTARIO_NOVO não encontrado!")
        return
    end
    
    local container = inventoryGui:FindFirstChild("container")
    
    if not container then
        warn("Container não encontrado!")
        return
    end
    
    local background = container:FindFirstChild("background")
    if not background then
        warn("Background não encontrado!")
        return
    end
    
    local scrollingFrame = background:FindFirstChild("ScrollingFrame")
    local tooltip = background:FindFirstChild("ItemInfoTooltip")
    local closeButton = background:FindFirstChild("Close")
    
    if not scrollingFrame then
        warn("ScrollingFrame não encontrado!")
        return
    end
    
    if not tooltip then
        warn("ItemInfoTooltip não encontrado!")
        return
    end
    
    if not closeButton then
        warn("Close button não encontrado!")
        return
    end
    
    container.Visible = false
    tooltip.Visible = false
    
    -- Criar slots para os itens
    createItemSlots(scrollingFrame)
    
    -- Configurar tooltips
    setupSlotTooltips(scrollingFrame, tooltip)
    
    closeButton.MouseButton1Click:Connect(function()
        if clickSound then
            clickSound:Play()
        end
        container.Visible = false
    end)
    
    closeButton.MouseEnter:Connect(function()
        if hoverSound then
            hoverSound:Play()
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= INVENTORY_TOGGLE_KEY then
            return
        end
        
        if clickSound then
            clickSound:Play()
        end
        
        container.Visible = not container.Visible
    end)
end

-- Listener para atualizações de itens do servidor
if updatePlayerItemsEvent then
    updatePlayerItemsEvent.OnClientEvent:Connect(onItemsUpdated)
end

player.CharacterAdded:Connect(setupInventory)

if player.Character then
    setupInventory()
end
