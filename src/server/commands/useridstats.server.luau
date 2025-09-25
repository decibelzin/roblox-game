local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

RegisterCommand({
    name = "useridstats",
    description = "Mostra estatísticas e diagnósticos do sistema de User ID",
    aliases = { "idstats", "uidstats", "useriddebug" },
    permissions = { "owner" }
}, function(player, params, message)
    local showDiagnostics = params[1] == "debug" or params[1] == "diag"
    
    if showDiagnostics then
        -- Executar diagnósticos completos
        local diagnostics = UserIdModule.runDiagnostics()
        
        if diagnostics.success then
            ChatMessage.sendSuccess(player, diagnostics.message)
        else
            ChatMessage.sendError(player, diagnostics.message)
        end
    else
        -- Mostrar estatísticas básicas
        local currentCounter = UserIdModule.getCurrentCounter()
        
        if not currentCounter then
            ChatMessage.sendError(player, "❌ Erro ao obter estatísticas do sistema de User ID!")
            return
        end
        
        local statsMessage = "📊 Estatísticas do Sistema de User ID:\n"
        statsMessage = statsMessage .. "🔢 Próximo ID disponível: " .. (currentCounter + 1) .. "\n"
        statsMessage = statsMessage .. "👥 Total de jogadores registrados: " .. currentCounter .. "\n"
        statsMessage = statsMessage .. "💡 Use 'useridstats debug' para diagnósticos detalhados"
        
        ChatMessage.sendInfo(player, statsMessage)
    end
end) 