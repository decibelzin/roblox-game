export type DefItem = {
    id: number,
    name: string,
    color: Color3?,
}

export type DefItemList = {[number]: DefItem}

return {
    [1] = {
        id = 1,
        name = 'espada de fogo',
        color = Color3.fromRGB(255, 0, 0),
    },
    [2] = {
        id = 2,
        name = 'poção de vida',
        color = Color3.fromRGB(0, 255, 0),
    }
} :: DefItemList
