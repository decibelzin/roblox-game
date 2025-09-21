# Exemplos de Comandos do Sistema de Grupos

## 🎯 Comandos Principais

### Gerenciar Grupos
`
/group [username] [grupo]     # Adicionar grupo ao player
/ungroup [username] [grupo]   # Remover grupo do player
`

### Verificar Grupos e Permissões
`
/groups                       # Ver seus próprios grupos
/groups [username]           # Ver grupos de outro player
/permissions                 # Ver suas próprias permissões
/permissions [username]      # Ver permissões de outro player
`

## �� Exemplos Práticos

### 1. Dar permissões para um player
`
/group Vitor Admin           # Dar grupo Admin para Vitor
/group Player123 Moderator   # Dar grupo Moderator para Player123
/group NewPlayer Vip         # Dar grupo Vip para NewPlayer
`

### 2. Remover permissões de um player
`
/ungroup Vitor Admin         # Remover grupo Admin de Vitor
/ungroup Player123 Vip       # Remover grupo Vip de Player123
`

### 3. Verificar permissões
`
/groups                      # Ver seus grupos
/groups Vitor               # Ver grupos do Vitor
/permissions                # Ver suas permissões
/permissions Vitor          # Ver permissões do Vitor
`

## 🔍 Busca de Players

O sistema faz busca parcial por username, então você pode usar:
- /group Vit Admin (encontrará "Vitor")
- /group Play Moderator (encontrará "Player123")
- /group New Vip (encontrará "NewPlayer")

## ⚠️ Requisitos

- Apenas players com permissão canManageGroups podem usar comandos de gerenciamento
- O player alvo deve estar online no servidor
- Grupos disponíveis: Admin, Moderator, Vip

## 🎮 Grupos e Permissões

### Admin
- Pode gerenciar grupos
- Pode banir players
- Pode kickar players
- Pode dar itens
- Pode teleportar
- Pode usar comandos de admin
- Pode mutar/desmutar

### Moderator
- Pode kickar players
- Pode mutar/desmutar
- Pode usar comandos de moderação

### Vip
- Pode usar comandos VIP
- Pode usar itens VIP
