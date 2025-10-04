export type DefPlayerGroups = {[string]: boolean}

-- Itens do jogador: {itemId -> quantidade}
export type DefPlayerItems = {[number]: number}

export type DefPlayerSchema = {
    player: Player,
    groups: DefPlayerGroups,
    userId: number,
    items: DefPlayerItems
}

return nil
