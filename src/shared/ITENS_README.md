# 📦 Sistema de Itens - Documentação

## 🎯 Visão Geral

Sistema completo de gerenciamento de itens para jogadores, com **fast lookup por ID**, persistência em DataStore, cache otimizado e sincronização cliente-servidor em tempo real.

---

## 📁 Arquitetura

### **Arquivos Principais:**

#### **Shared (Compartilhado):**
- `src/shared/itens.luau` - Configuração de todos os itens do jogo
- `src/shared/storage.luau` - Definições de DataStores (incluindo `playerItems`)
- `src/shared/types/player.types.luau` - Tipos TypeScript-like para dados do jogador

#### **Server (Servidor):**
- `src/server/framework/modules/player-items.luau` - Módulo principal de gerenciamento
- `src/server/player-items-init.server.luau` - Script de inicialização
- `src/server/commands/giveitem.server.luau` - Comando: dar item
- `src/server/commands/removeitem.server.luau` - Comando: remover item
- `src/server/commands/listitemsplayer.server.luau` - Comando: listar itens do jogador
- `src/server/commands/listavailableitems.server.luau` - Comando: listar itens disponíveis
- `src/server/commands/testitems.server.luau` - Comando: testar sistema (dev)

#### **Client (Cliente):**
- `src/client/uis/inventory.client.luau` - Interface do inventário (atualizado)

---

## 🔧 Como Adicionar Novos Itens

### **1. Editar o arquivo de configuração:**

```lua
-- src/shared/itens.luau

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
    },
    [3] = {  -- NOVO ITEM
        id = 3,
        name = 'escudo mágico',
        color = Color3.fromRGB(0, 100, 255),
    }
} :: DefItemList
```

### **⚠️ Regras Importantes:**
- ✅ **ID deve ser único e numérico**
- ✅ **Use índice do array igual ao ID** (para fast lookup)
- ✅ **Color é opcional**
- ✅ **Você pode adicionar campos customizados** (descrição, raridade, etc)

---

## 📡 API do Servidor

### **Módulo: `PlayerItemsModule`**

```lua
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])
```

### **Funções Disponíveis:**

#### `addItem(player, itemId, quantity)`
Adiciona item ao inventário do jogador.
```lua
PlayerItemsModule.addItem(player, 1, 5) -- Adiciona 5x espada de fogo
-- Retorna: boolean (success)
```

#### `removeItem(player, itemId, quantity)`
Remove item do inventário do jogador.
```lua
PlayerItemsModule.removeItem(player, 1, 2) -- Remove 2x espada de fogo
-- Retorna: boolean (success)
```

#### `setItem(player, itemId, quantity)`
Define quantidade exata de um item.
```lua
PlayerItemsModule.setItem(player, 1, 10) -- Define exatamente 10x espada de fogo
-- Retorna: boolean (success)
```

#### `hasItem(player, itemId, quantity)`
Verifica se jogador possui item.
```lua
local hasItem = PlayerItemsModule.hasItem(player, 1, 5) -- Possui 5x espada?
-- Retorna: boolean
```

#### `getItemQuantity(player, itemId)`
Obtém quantidade de um item específico.
```lua
local qty = PlayerItemsModule.getItemQuantity(player, 1)
-- Retorna: number
```

#### `getPlayerItems(player)`
Obtém todos os itens do jogador (apenas IDs e quantidades).
```lua
local items = PlayerItemsModule.getPlayerItems(player)
-- Retorna: {[itemId] = quantidade}
-- Exemplo: {[1] = 5, [2] = 3}
```

#### `getPlayerItemsWithInfo(player)`
Obtém itens com informações completas da config.
```lua
local items = PlayerItemsModule.getPlayerItemsWithInfo(player)
-- Retorna: {[itemId] = {item: config, quantity: number}}
```

#### `clearAllItems(player)`
Remove todos os itens do jogador.
```lua
PlayerItemsModule.clearAllItems(player)
-- Retorna: boolean (success)
```

---

## 🎮 Comandos Administrativos

### `/giveitem <username> <itemId> [quantidade]`
**Permissões:** owner, admin, moderator  
**Aliases:** `/gi`, `/item`  
**Exemplo:**
```
/giveitem vitor 1 5
/gi vitor 2
```

### `/removeitem <username> <itemId> [quantidade]`
**Permissões:** owner, admin, moderator  
**Aliases:** `/ri`, `/takeitem`  
**Exemplo:**
```
/removeitem vitor 1 3
```

### `/listitems [username]`
**Permissões:** owner, admin, moderator  
**Aliases:** `/li`, `/inventory`  
**Exemplo:**
```
/listitems vitor
/li
```

### `/itemlist`
**Permissões:** owner, admin, moderator  
**Aliases:** `/items`, `/allitems`  
Lista todos os itens cadastrados no jogo.

### `/testitems [username]`
**Permissões:** owner, admin  
**Aliases:** `/testinv`  
Adiciona todos os itens cadastrados (quantidade aleatória) para testes.

---

## 💾 Persistência

### **DataStore:**
- **Key:** `"player.items"`
- **Formato:** `{[itemId]: quantidade}`
- **Exemplo:** `{[1] = 5, [2] = 3, [3] = 1}`

### **Características:**
- ✅ Salvamento automático ao adicionar/remover itens
- ✅ Carregamento automático ao entrar no jogo
- ✅ Salvamento forçado ao sair do jogo
- ✅ Validação de dados antes de salvar
- ✅ Cache em memória para performance

---

## 🔄 Sincronização Cliente-Servidor

### **RemoteEvents:**

#### `GetPlayerItems` (RemoteFunction)
Cliente chama para obter itens ao abrir inventário.
```lua
-- Cliente
local items = ReplicatedStorage.GetPlayerItems:InvokeServer()
```

#### `UpdatePlayerItems` (RemoteEvent)
Servidor envia para cliente quando itens são atualizados.
```lua
-- Servidor (automático)
updatePlayerItemsEvent:FireClient(player, items)

-- Cliente (listener)
updatePlayerItemsEvent.OnClientEvent:Connect(function(items)
    -- Atualizar UI
end)
```

---

## 🚀 Performance

### **Fast Lookup:**
- Itens são indexados por **ID numérico** (não string)
- Acesso O(1) usando tabela hash: `items[itemId]`
- Cache local para evitar chamadas repetidas ao DataStore

### **Otimizações:**
- Cache em memória no servidor
- Validação antes de operações no DataStore
- Atualização visual reativa no cliente
- Batch operations quando possível

---

## 🎨 Integração com Inventário UI

O inventário cliente foi atualizado para:
- ✅ Carregar itens reais do servidor
- ✅ Criar slots dinamicamente baseado nos itens
- ✅ Atualizar em tempo real quando itens mudam
- ✅ Mostrar quantidade de cada item
- ✅ Aplicar cor configurada no item
- ✅ Tooltip com informações do item

---

## 📝 Exemplo de Uso Completo

### **Script de Loja (Exemplo):**
```lua
local PlayerItemsModule = require(game.ServerScriptService.Server.framework.modules["player-items"])

-- Jogador compra espada de fogo
local function buyItem(player, itemId, price)
    -- Verificar se tem dinheiro (seu sistema de economia)
    local hasMoney = checkPlayerMoney(player, price)
    if not hasMoney then
        return false, "Dinheiro insuficiente"
    end
    
    -- Remover dinheiro
    removePlayerMoney(player, price)
    
    -- Dar item
    local success = PlayerItemsModule.addItem(player, itemId, 1)
    if success then
        return true, "Item comprado com sucesso!"
    else
        -- Reembolsar em caso de erro
        addPlayerMoney(player, price)
        return false, "Erro ao adicionar item"
    end
end
```

---

## ✅ Checklist de Implementação

- [x] Configuração de itens (itens.luau)
- [x] Tipos do sistema (player.types.luau)
- [x] DataStore definitions (storage.luau)
- [x] Módulo servidor de itens
- [x] Comandos administrativos (5 comandos)
- [x] RemoteEvents para sincronização
- [x] Integração com inventário cliente
- [x] Cache otimizado
- [x] Salvamento automático
- [x] Validação de dados
- [x] Documentação completa

---

## 🔮 Próximos Passos (Sugestões)

1. **Adicionar descrição aos itens** na config
2. **Sistema de raridade** (comum, raro, épico, lendário)
3. **Itens equipáveis** (armas, armaduras)
4. **Sistema de crafting** (combinar itens)
5. **Limite de stack** por item
6. **Itens não-stackáveis** (únicos)
7. **Cooldown** para uso de itens
8. **Efeitos de itens** (consumíveis)
9. **Trading** entre jogadores
10. **Ícones customizados** para cada item

---

## 🐛 Troubleshooting

### **Itens não aparecem no inventário:**
- Verifique se o RemoteFunction está criado no servidor
- Confirme que o player tem itens no DataStore
- Cheque console do cliente para erros

### **Itens não salvam:**
- Verifique se o DataStore está habilitado no Roblox Studio
- Confirme que o jogo está publicado
- Cheque se há erros de validação nos dados

### **Performance ruim:**
- Limite a criação de slots visuais (max 50-100 itens diferentes)
- Use UIGridLayout no ScrollingFrame
- Considere paginação para inventários grandes

---

**Criado por:** Sistema de Itens v1.0  
**Data:** 2025  
**Compatível com:** Roblox Luau

