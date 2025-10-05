-- ========================================
-- GHOST SLOT CACHE (Reutilizável)
-- ========================================
-- Cache de slot fantasma usado durante operações de drag & drop

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
    ghost.AnchorPoint = Vector2.new(0, 0)  -- Canto superior esquerdo
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

function GhostSlotCache.cleanup()
    if GhostSlotCache.ghost then
        GhostSlotCache.ghost:Destroy()
        GhostSlotCache.ghost = nil
        GhostSlotCache.quantityLabel = nil
        GhostSlotCache.gradient = nil
    end
end

return GhostSlotCache

