# Estrutura do Projeto Roblox Refatorado

## Organizacao de Arquivos

### Cliente (src/client/)
- init.client.luau - Arquivo principal que orquestra todos os servicos
- services/ - Servicos especificos do cliente
  - UIService.luau - Gerencia interface do usuario e elementos GUI
  - CameraService.luau - Controla configuracoes da camera
  - GameService.luau - Logica principal do jogo no cliente

### Servidor (src/server/)
- init.server.luau - Arquivo principal que orquestra todos os servicos
- services/ - Servicos especificos do servidor
  - PlayerService.luau - Gerencia jogadores, spawn e eventos

### Compartilhado (src/shared/)
- config/ - Configuracoes compartilhadas
  - GameConfig.luau - Todas as configuracoes do jogo (UI, camera, spawn, etc.)
- utils/ - Utilitarios compartilhados
  - Utils.luau - Funcoes auxiliares para criacao de elementos GUI

## Arquitetura

### Separacao de Responsabilidades:
- Configuracoes -> Centralizadas em GameConfig.luau
- Interface -> UIService.luau (criacao, gerenciamento, eventos)
- Camera -> CameraService.luau (posicionamento, transicoes)
- Jogadores -> PlayerService.luau (spawn, eventos de jogador)
- Logica do Jogo -> GameService.luau (estado do jogo, transicoes)
- Utilitarios -> Utils.luau (funcoes auxiliares reutilizaveis)

### Vantagens da Refatoracao:
- Codigo mais limpo e organizado
- Facil manutencao - cada arquivo tem uma responsabilidade especifica
- Reutilizacao - utilitarios e configuracoes compartilhadas
- Escalabilidade - facil adicionar novos servicos
- Debugging - problemas isolados em arquivos especificos
- Colaboracao - diferentes desenvolvedores podem trabalhar em arquivos diferentes

## Como Usar

1. Configuracoes: Edite src/shared/config/GameConfig.luau
2. Interface: Modifique src/client/services/UIService.luau
3. Camera: Ajuste src/client/services/CameraService.luau
4. Logica do Jogo: Implemente em src/client/services/GameService.luau
5. Jogadores: Gerencie em src/server/services/PlayerService.luau
