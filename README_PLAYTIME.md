# 🎮 Sistema de Playtime com Recompensas e Notificações

## 📋 Funcionalidades

- **Contagem Server-Side**: Sistema 100% server-side, impossível de trapacear
- **Sistema de Recompensas**: Ganhe moedas por tempo jogado
- **Notificações Visuais**: Notificações na tela quando ganhar moedas
- **Efeitos Sonoros**: Som de moeda ao ganhar recompensas
- **Marcos de Tempo**: Bônus extras por alcançar marcos específicos
- **Salvamento Automático**: Salva automaticamente a cada 2 minutos
- **Comandos no Chat**: Mensagens aparecem no chat do jogo

## 🎯 Como Usar

### Comandos (aparecem no chat):
- `/playtime` - Ver tempo de jogo e moedas
- `/playtime [jogador]` - Ver tempo e moedas de outro jogador
- `/coins` - Ver moedas e próximos marcos
- `/coins [jogador]` - Ver moedas de outro jogador
- `/playtimerank` - Ver ranking de jogadores
- `/testcoin [quantidade] [motivo]` - Testar notificações
- `/pt`, `/tempo` - Aliases do playtime
- `/money`, `/dinheiro` - Aliases do coins

## 💰 Sistema de Recompensas

### Moedas por Tempo:
- **1 moeda por minuto** jogado
- **Salvamento automático** a cada 2 minutos
- **Recompensas instantâneas** ao jogar
- **Notificações visuais** na tela
- **Som de moeda** ao ganhar

### Marcos de Tempo:
- **1 hora** (60 min) = +10 moedas extras
- **5 horas** (300 min) = +50 moedas extras
- **10 horas** (600 min) = +100 moedas extras
- **30 horas** (1800 min) = +300 moedas extras
- **60 horas** (3600 min) = +500 moedas extras

## 🔔 Sistema de Notificações

### Notificações Visuais:
- **Posição**: Canto superior direito da tela
- **Design**: Fundo escuro com bordas arredondadas
- **Ícone**: 💰 (moeda dourada)
- **Animação**: Entrada suave, permanece 3 segundos
- **Cores**: Dourado para ícone, verde para quantidade

### Efeitos Sonoros:
- **Som**: Som eletrônico padrão do Roblox
- **Volume**: 50% (configurável)
- **Trigger**: Toda vez que ganhar moedas
- **Duração**: Som curto e agradável

## 🔧 Arquitetura

### Módulos:
- `src/server/framework/modules/playtime.luau` - Lógica principal com recompensas
- `src/server/commands/playtime.server.luau` - Comando de verificação
- `src/server/commands/coins.server.luau` - Comando de moedas
- `src/server/commands/playtimerank.server.luau` - Comando de ranking
- `src/server/commands/testcoin.server.luau` - Comando de teste
- `src/server/playtime.server.luau` - Inicializador do sistema

### Cliente:
- `src/client/coin-notifications.client.luau` - Sistema de notificações

### Integração:
- **Módulo de Coins**: Integrado com sistema existente
- **DataStore**: Salva tempo e moedas automaticamente
- **Player Classes**: Usa classes existentes do jogador
- **Chat System**: Usa sistema de chat existente
- **RemoteEvents**: CoinNotification para notificações

## 📊 Exemplo de Uso

### Comando `/playtime`:
```
 vitormaluc0:
   Tempo total jogado: 01:23:45
   Moedas: 89
   Moedas ganhas nesta sessão: 5
```

### Comando `/coins`:
```
💰 vitormaluc0:
   Tempo total jogado: 01:23:45
   Moedas: 89
   Próximo marco: 300 min (faltam 30.7 min) - +50 moedas
```

### Comando `/testcoin`:
```
/testcoin 50 Teste de notificação
✅ Teste: +50 moedas (Teste de notificação)
```

## ⚙️ Configurações

### Alterar Recompensas:
No arquivo `playtime.luau`:
- `COINS_PER_MINUTE = 1` - Moedas por minuto
- `MILESTONE_BONUS` - Bônus por marcos
- `SAVE_INTERVAL = 120` - Frequência de salvamento

### Alterar Notificações:
No arquivo `coin-notifications.client.luau`:
- `sound.Volume = 0.5` - Volume do som
- `wait(3)` - Tempo de exibição da notificação
- Cores e posições dos elementos

## 🚀 Próximas Funcionalidades

- Sistema de conquistas baseado em tempo
- Recompensas diárias
- Bônus por streak de dias
- Loja com itens desbloqueáveis por tempo
- Estatísticas detalhadas de ganhos
- Diferentes tipos de notificações

## 🎮 Como Funciona

1. **Jogador entra** - Sistema inicia tracking
2. **A cada minuto** - Jogador ganha 1 moeda + notificação
3. **A cada 2 minutos** - Sistema salva progresso
4. **Ao alcançar marcos** - Jogador ganha bônus extras + notificação
5. **Jogador sai** - Sistema salva tempo final
6. **Comandos** - Mensagens aparecem no chat do jogo

---
*Sistema integrado com recompensas automáticas, notificações visuais e efeitos sonoros*

