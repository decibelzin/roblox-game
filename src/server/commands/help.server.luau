local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])

RegisterCommand({
    name = "help",
    description = "Lista todos os comandos disponíveis",
    aliases = { "h", "ajuda" },
    permissions = {}
}, function(player, params, message)
    print("📋 === COMANDOS DISPONÍVEIS ===")
    print("")
    
    print("🔧 COMANDOS DE GRUPOS:")
    print("  /group <username> <group>     - Adiciona um grupo a um jogador")
    print("  /ungroup <username> <group>   - Remove um grupo de um jogador")
    print("  /listgroups [username]        - Lista grupos de um jogador")
    print("  /cleargroups <username>       - Remove todos os grupos de um jogador")
    print("  /mygroups                     - Mostra seus próprios grupos")
    print("")
    
    print("🛠️ COMANDOS DE DEBUG:")
    print("  /debuggroups                  - Debug completo dos grupos")
    print("  /syncgroups                   - Força sincronização de grupos")
    print("")
    
    print("🎮 COMANDOS DE JOGO:")
    print("  /fly [username]               - Ativa/desativa voo")
    print("  /invisi [username]            - Ativa/desativa invisibilidade")
    print("  /headless [username]          - Remove cabeça do jogador")
    print("  /korblox [username]           - Transforma em Korblox")
    print("  /copyskin <username>          - Copia skin de um jogador")
    print("  /resetskin [username]         - Reseta skin do jogador")
    print("")
    
    print("📊 GRUPOS DISPONÍVEIS:")
    print("  🥇 owner      - Owner (prioridade 4)")
    print("  🔴 admin      - Administrador (prioridade 3)")
    print("  🟢 moderator  - Moderador (prioridade 2)")
    print("  🟡 vip-gold   - VIP Gold (prioridade 1)")
    print("")
    
    print("💡 DICAS:")
    print("  - Use /mygroups para ver seus grupos")
    print("  - Use /listgroups <username> para ver grupos de outros")
    print("  - Use /debuggroups para debug completo")
    print("  - Use /syncgroups para forçar atualização das tags")
    print("")
    
    print("================================")
end)
