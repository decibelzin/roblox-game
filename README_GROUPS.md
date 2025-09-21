# Sistema de Grupos Seguro - Roblox

Este sistema implementa um gerenciamento de grupos e permissões seguro usando RemoteEvents, garantindo que dados sensíveis nunca sejam expostos ao cliente. Inclui suporte para permissões do Roblox (Owner, Group Admin) além dos grupos personalizados.

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
- /group [username] [grupo] - Adicionar grupo ao player especificado
- /ungroup [username] [grupo] - Remover grupo do player especificado
- /groups - Listar grupos do próprio player
- /groups [username] - Listar grupos de outro player
- /permissions - Listar permissões do próprio player
- /permissions [username] - Listar permissões de outro player

### Comandos do Cliente
- /mygroups - Mostrar grupos do player
- /mypermissions - Mostrar permissões do player
- /groupinfo - Mostrar informações dos grupos

## 🎯 Grupos Disponíveis

### Grupos Especiais do Roblox
- **Owner** - Dono do jogo (sempre tem todas as permissões)
- **GroupAdmin** - Admin do grupo do jogo (sempre tem todas as permissões)

### Grupos Personalizados
- **Admin** - Permissões completas (ban, kick, gerenciar grupos, etc.)
- **Moderator** - Permissões de moderação (kick, mute, etc.)
- **Vip** - Permissões especiais (comandos VIP, itens especiais)

## 🔧 RemoteEvents

### GetPlayerGroups
- **Tipo**: RemoteEvent
- **Uso**: Cliente solicita grupos do player
- **Resposta**: Lista de grupos do player (incluindo grupos do Roblox)

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

## 💡 Exemplos de Comandos

### Gerenciar Grupos
`
/group Vitor Admin          # Dar grupo Admin para Vitor
/ungroup Vitor Admin        # Remover grupo Admin de Vitor
/group Player123 Moderator  # Dar grupo Moderator para Player123
/ungroup Player123 Vip      # Remover grupo Vip de Player123
`

### Verificar Grupos e Permissões
`
/groups                     # Ver seus próprios grupos
/groups Vitor              # Ver grupos do Vitor
/permissions               # Ver suas próprias permissões
/permissions Vitor         # Ver permissões do Vitor
`

## 🔐 Hierarquia de Permissões

### 1. Owner (Dono do Jogo)
- **Prioridade**: 5 (mais alta)
- **Cor**: Dourado
- **Permissões**: TODAS as permissões
- **Como obter**: Ser o dono do jogo

### 2. GroupAdmin (Admin do Grupo)
- **Prioridade**: 4
- **Cor**: Laranja
- **Permissões**: TODAS as permissões
- **Como obter**: Ser admin do grupo do jogo (rank >= 100)

### 3. Admin (Grupo Personalizado)
- **Prioridade**: 3
- **Cor**: Vermelho
- **Permissões**: canBan, canKick, canGiveItems, canTeleport, canManageGroups, canUseAdminCommands, canMute, canUnmute
- **Como obter**: Comando /group [username] Admin

### 4. Moderator (Grupo Personalizado)
- **Prioridade**: 2
- **Cor**: Verde
- **Permissões**: canKick, canMute, canUnmute, canUseModCommands
- **Como obter**: Comando /group [username] Moderator

### 5. Vip (Grupo Personalizado)
- **Prioridade**: 1
- **Cor**: Amarelo
- **Permissões**: canUseVIPCommands, canUseVIPItems
- **Como obter**: Comando /group [username] Vip

## ⚠️ Importante

1. **Nunca** coloque dados sensíveis em src/shared/
2. **Sempre** valide permissões no servidor
3. **Use** RemoteEvents para comunicação segura
4. **Teste** todas as permissões antes de usar em produção
5. **Apenas** players com permissão canManageGroups podem usar comandos de gerenciamento
6. **Owner** e **GroupAdmin** sempre têm todas as permissões, independente dos grupos personalizados

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
- Verifique se o player é Owner ou GroupAdmin

### Dados não salvando
- Verifique se o DataStore está configurado corretamente
- Verifique se o player está sendo salvo ao sair
- Verifique se há erros no console do servidor

### Player não encontrado
- Verifique se o username está correto
- O sistema faz busca parcial (não precisa do nome completo)
- Exemplo: /group Vit Admin encontrará "Vitor"

### Owner/GroupAdmin não funcionando
- Verifique se o game.CreatorId está configurado corretamente
- Verifique se o player está no grupo correto
- Verifique se o rank do player no grupo é >= 100
