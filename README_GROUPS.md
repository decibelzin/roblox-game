# Sistema de Grupos Seguro - Roblox

Este sistema implementa um gerenciamento de grupos e permissões seguro usando RemoteEvents, garantindo que dados sensíveis nunca sejam expostos ao cliente.

## 📁 Estrutura de Arquivos

### Servidor
- src/server/groups/groups.server.luau - Lógica principal com validação de permissões
- src/server/groups/GroupsDataStore.luau - Gerenciamento de dados persistentes
- src/server/groups/GroupPermissions.luau - Definições de permissões (SENSÍVEL)
- src/server/groups/GroupManager.luau - RemoteEvents para comunicação com cliente

### Cliente
- src/client/GroupClient.luau - Interface para acessar grupos no cliente
- src/client/GroupExample.luau - Exemplos de uso do sistema

### Shared
- src/shared/groups.luau - Informações de display dos grupos (SEGURO)

## 🔒 Segurança

### ✅ O que é SEGURO para o cliente:
- Informações de display dos grupos (nome, cor, prioridade)
- Verificação de permissões via RemoteFunction
- Lista de grupos do player

### ❌ O que NUNCA é enviado ao cliente:
- Definições reais de permissões
- Lógica de validação
- Dados sensíveis do servidor

## 🚀 Como Usar

### No Servidor

`lua
-- Verificar se player pode usar comando
if canUseCommand(player, "canKick") then
    -- Permitir ação
end

-- Verificar se player pode gerenciar grupos
if canManageGroups(player) then
    -- Permitir gerenciamento
end
`

### No Cliente

`lua
-- Aguardar GroupClient carregar
local GroupClient = _G.GroupClient

-- Verificar permissões
if GroupClient.hasPermission("canKick") then
    -- Mostrar botão de kick
end

-- Obter grupos do player
local groups = GroupClient.getPlayerGroups()

-- Verificar grupo específico
if GroupClient.hasGroup("Admin") then
    -- Player é admin
end

-- Obter informações completas dos grupos
local groupsWithInfo = GroupClient.getPlayerGroupsWithInfo()
`

## 📋 Comandos Disponíveis

### Comandos de Chat (apenas para quem tem permissão)
- /group [nome] - Adicionar grupo ao player
- /ungroup [nome] - Remover grupo do player
- /groups - Listar grupos do player
- /permissions - Listar permissões do player

### Comandos do Cliente
- /mygroups - Mostrar grupos do player
- /mypermissions - Mostrar permissões do player
- /groupinfo - Mostrar informações dos grupos

## 🎯 Grupos Disponíveis

### Admin
- **Permissões**: canBan, canKick, canGiveItems, canTeleport, canManageGroups, canUseAdminCommands, canMute, canUnmute
- **Cor**: Vermelho
- **Prioridade**: 3

### Moderator
- **Permissões**: canKick, canMute, canUnmute, canUseModCommands
- **Cor**: Verde
- **Prioridade**: 2

### Vip
- **Permissões**: canUseVIPCommands, canUseVIPItems
- **Cor**: Amarelo
- **Prioridade**: 1

## 🔧 RemoteEvents

### GetPlayerGroups
- **Tipo**: RemoteEvent
- **Uso**: Cliente solicita grupos do player
- **Resposta**: Lista de grupos do player

### CheckPermission
- **Tipo**: RemoteFunction
- **Uso**: Cliente verifica permissão específica
- **Parâmetros**: permission (string)
- **Resposta**: boolean

### GetGroupInfo
- **Tipo**: RemoteFunction
- **Uso**: Cliente obtém informações de um grupo
- **Parâmetros**: groupName (string)
- **Resposta**: Informações do grupo (displayName, color, priority)

### GetAllGroups
- **Tipo**: RemoteFunction
- **Uso**: Cliente obtém todos os grupos disponíveis
- **Resposta**: Lista de todos os grupos

## 📝 Exemplos de Uso

### 1. Sistema de UI Dinâmica
`lua
local function updateUI()
    if GroupClient.hasPermission("canKick") then
        -- Mostrar botão de kick
    end
    
    if GroupClient.hasPermission("canBan") then
        -- Mostrar botão de ban
    end
end
`

### 2. Sistema de Comandos
`lua
local function setupCommands()
    player.Chatted:Connect(function(message)
        if message == "/kick" and GroupClient.hasPermission("canKick") then
            -- Executar comando de kick
        end
    end)
end
`

### 3. Sistema de Itens VIP
`lua
local function giveVIPItems()
    if GroupClient.hasPermission("canUseVIPItems") then
        -- Dar itens especiais
    end
end
`

## ⚠️ Importante

1. **Nunca** coloque dados sensíveis em src/shared/
2. **Sempre** valide permissões no servidor
3. **Use** RemoteEvents para comunicação segura
4. **Teste** todas as permissões antes de usar em produção

## 🐛 Troubleshooting

### GroupClient não carregou
`lua
local function waitForGroupClient()
    while not _G.GroupClient do
        wait(0.1)
    end
    return _G.GroupClient
end
`

### Permissões não funcionando
- Verifique se o player tem o grupo correto
- Verifique se a permissão está definida em GroupPermissions.luau
- Verifique se o RemoteEvent está funcionando

### Dados não salvando
- Verifique se o DataStore está configurado corretamente
- Verifique se o player está sendo salvo ao sair
- Verifique se há erros no console do servidor
