# Sistema de Permissões - Roblox Game

## Visão Geral
Sistema completo de permissões com níveis hierárquicos, comandos administrativos e interface de usuário.

## Estrutura de Arquivos

### Compartilhado (src/shared/permissions/)
- **Permissions.luau** - Definições de níveis e permissões

### Servidor (src/server/permissions/)
- **PermissionManager.luau** - Gerenciamento de permissões dos jogadores
- **CommandSystem.luau** - Sistema de comandos administrativos

### Cliente (src/client/ui/)
- **PermissionUI.luau** - Interface para visualizar permissões

## Níveis de Permissão

### 0 - GUEST (Visitante)
- Chat básico
- Jogar

### 1 - PLAYER (Jogador)
- Chat
- Jogar
- Spawn

### 2 - VIP
- Todas as permissões de PLAYER
- Teleportar

### 3 - MODERATOR (Moderador)
- Todas as permissões de VIP
- Kickar jogadores
- Mutar/Desmutar jogadores

### 4 - ADMIN (Administrador)
- Todas as permissões de MODERATOR
- Banir jogadores
- Dar itens
- Definir permissões
- Chat administrativo

### 5 - OWNER (Dono)
- Todas as permissões
- Comandos de servidor
- Reiniciar servidor

## Comandos Disponíveis

### Comandos Básicos
- **!help** - Mostra comandos disponíveis
- **!who** - Lista jogadores e suas permissões
- **!camera** - Reseta a câmera

### Comandos de Moderação
- **!kick <jogador> [motivo]** - Kickar jogador
- **!mute <jogador> [tempo]** - Mutar jogador
- **!unmute <jogador>** - Desmutar jogador
- **!teleport <jogador1> <jogador2>** - Teleportar jogadores

### Comandos Administrativos
- **!setperm <jogador> <nível>** - Definir nível de permissão
- **!ban <jogador> [motivo]** - Banir jogador
- **!give <jogador> <item>** - Dar item para jogador

## Como Usar

### Para Jogadores
1. Pressione **F2** para abrir a interface de permissões
2. Visualize seu nível e permissões
3. Use comandos baseados em suas permissões

### Para Administradores
1. Configure UserIds de administradores em PermissionManager.ADMIN_USER_IDS
2. Configure UserIds de VIPs em PermissionManager.VIP_USER_IDS
3. Use comandos para gerenciar jogadores

### Configuração de Administradores
`lua
PermissionManager.ADMIN_USER_IDS = {
    123456789,  -- UserId do administrador 1
    987654321   -- UserId do administrador 2
}
`

### Configuração de VIPs
`lua
PermissionManager.VIP_USER_IDS = {
    111222333,  -- UserId do VIP 1
    444555666   -- UserId do VIP 2
}
`

## Funcionalidades

### Sistema de Cache
- Permissões são armazenadas em cache para melhor performance
- Dados persistem usando DataStore

### Verificação de Permissões
- Verificação automática antes de executar comandos
- Prevenção de escalação de privilégios

### Interface de Usuário
- Interface limpa e intuitiva
- Atalho F2 para abrir/fechar
- Lista de permissões em tempo real

### Sistema de Comandos
- Prefixo configurável (!)
- Validação de argumentos
- Mensagens de erro claras

## Segurança

### Prevenção de Abuso
- Jogadores não podem alterar suas próprias permissões
- Verificação de níveis antes de executar ações
- Validação de argumentos de comandos

### Persistência
- Permissões salvas no DataStore
- Cache local para performance
- Recuperação automática de dados

## Extensibilidade

### Adicionar Novos Comandos
1. Adicione a permissão necessária em Permissions.FLAGS
2. Mapeie o comando em CommandSystem.commandPermissions
3. Implemente a função do comando

### Adicionar Novos Níveis
1. Adicione o nível em Permissions.LEVELS
2. Defina as permissões em Permissions.LEVEL_PERMISSIONS
3. Atualize a lógica de verificação

### Personalizar Interface
1. Modifique PermissionUI.luau
2. Adicione novos elementos GUI
3. Conecte eventos personalizados
