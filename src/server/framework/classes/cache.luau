-- Definição genérica
export type Cache<T> = {
    set: (key: any, value: T) -> T,
    remove: (key: any) -> (),
    get: (key: any) -> T?,
}

local Class = {
    spaces = {} :: { [string]: { [string]: any } }
}

function Class.new<T>(namespace: string): Cache<T>
    Class.spaces[namespace] = {}
    return Class.instance(namespace) :: Cache<T>
end

function Class.instance<T>(namespace: string): Cache<T>
    local self = {} :: Cache<T>

    function self.set(key, value)
        Class.spaces[namespace][key] = value
        return Class.spaces[namespace][key]
    end

    function self.remove(key)
        Class.spaces[namespace][key] = nil
    end

    function self.get(key): T?
        return Class.spaces[namespace][key]
    end

    return self
end

return Class