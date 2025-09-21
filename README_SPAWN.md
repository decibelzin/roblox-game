# Sistema de Listeners para Spawn no Roblox

Este projeto demonstra diferentes formas de detectar quando um player spawna no Roblox.

## Arquivos Criados

### Servidor (src/server/init.server.luau)
- Detecta quando players se conectam ao servidor
- Detecta quando o character de cada player spawna
- Detecta respawn e morte de players
- Usa funções utilitárias do SpawnUtils

### Cliente (src/client/init.client.luau)
- Detecta quando o próprio player spawna
- Detecta respawn e morte do próprio player

### Shared (src/shared/SpawnUtils.luau)
- Funções utilitárias reutilizáveis para detectar spawn
- onPlayerSpawn() - detecta quando um player spawna
- onPlayerRespawn() - detecta quando um player respawna
- onPlayerDeath() - detecta quando um player morre

## Como Usar

### Método 1: Listeners Básicos
`lua
local Players = game:GetService("Players")

-- Quando um player se conecta
Players.PlayerAdded:Connect(function(player)
    -- Quando o character spawna
    player.CharacterAdded:Connect(function(character)
        print("Character spawnou!")
    end)
end)
`

### Método 2: Usando SpawnUtils
`lua
local SpawnUtils = require(game.ReplicatedStorage.SpawnUtils)

-- Para detectar spawn
SpawnUtils.onPlayerSpawn(player, function(player, character, humanoid)
    print("Player spawnou!")
end)

-- Para detectar respawn
SpawnUtils.onPlayerRespawn(player, function(player, character, humanoid)
    print("Player respawnou!")
end)

-- Para detectar morte
SpawnUtils.onPlayerDeath(player, function(player, character, humanoid)
    print("Player morreu!")
end)
`

## Eventos Disponíveis

1. **PlayerAdded** - quando um player se conecta ao servidor
2. **CharacterAdded** - quando o character de um player spawna
3. **Humanoid.Died** - quando um player morre
4. **Humanoid.HealthChanged** - quando a vida do player muda (útil para detectar respawn)

## Exemplos de Uso

- Dar itens quando o player spawna
- Teleportar para uma posição específica
- Aplicar efeitos visuais
- Registrar estatísticas
- Configurar UI específica

## Notas Importantes

- Sempre use WaitForChild() para aguardar o Humanoid carregar
- Verifique se o character já existe antes de conectar listeners
- Use Players:GetPlayers() para players que já estão no servidor
- No cliente, use Players.LocalPlayer para o próprio player
