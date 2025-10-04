export type DefPlayerGroups = {[string]: boolean}

-- Itens do jogador: {itemId -> quantidade}
export type DefPlayerItems = {[number]: number}

-- Ordem dos itens no inventário: {itemId -> posição}
export type DefItemsOrder = {[number]: number}

export type DefPlayerSchema = {
    player: Player,
    groups: DefPlayerGroups,
    userId: number,
    items: DefPlayerItems,
    itemsOrder: DefItemsOrder
}

return nil
