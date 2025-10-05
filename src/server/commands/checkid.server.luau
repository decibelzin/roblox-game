local RegisterCommand = require(game.ReplicatedStorage.Shared["register-command"])
local Players = game:GetService("Players")
local ChatMessage = require(game.ServerScriptService.Server.framework.modules["chat-message"])
local UserIdModule = require(game.ServerScriptService.Server.framework.modules["user-id"])

RegisterCommand({
    name = "checkid",
    description = "Verifica disponibilidade de User ID ou consulta ID por username",
    aliases = { "verificarid", "idstatus" },
    permissions = { "owner", "admin" } -- Owners e admins podem verificar IDs
}, function(player, params, message)
    local input = params[1]

    -- Validar parâmetros
    if not input then
        ChatMessage.sendError(player, "❌ Uso correto: /checkid <id_ou_username>\n📋 Exemplos:\n• /checkid 666 (verifica se ID está disponível)\n• /checkid Nanazsj (mostra o ID do usuário)")
        return
    end

    -- Verificar se é um número (ID) ou texto (username)
    local userId = tonumber(input)
    
    if userId then
        -- Input é um número - verificar disponibilidade do ID
        if userId <= 0 then
            ChatMessage.sendError(player, "❌ O User ID deve ser um número positivo!")
            return
        end

        -- Verificar se o ID está em uso
        local isInUse = UserIdModule.isUserIdInUse(userId)
        
        if not isInUse then
            -- ID está disponível
            local availableMessage = "✅ User ID " .. userId .. " está DISPONÍVEL!\n"
            availableMessage = availableMessage .. "🆔 Status: Livre para uso"
            
            ChatMessage.sendSuccess(player, availableMessage)
        else
            -- ID está em uso, buscar informações do usuário
            local playerName = UserIdModule.getPlayerNameByUserId(userId)
            local robloxId = UserIdModule.findRobloxIdByUserId(userId)
            
            local usedMessage = "❌ User ID " .. userId .. " está EM USO!\n"
            usedMessage = usedMessage .. "🆔 Status: Ocupado\n"
            
            if playerName then
                usedMessage = usedMessage .. "👤 Usuário: " .. playerName
            else
                usedMessage = usedMessage .. "👤 Usuário: [Nome não encontrado]"
            end
            
            if robloxId then
                usedMessage = usedMessage .. "\n🔗 Roblox ID: " .. robloxId
                
                -- Verificar se o jogador está online
                local onlinePlayer = Players:GetPlayerByUserId(robloxId)
                if onlinePlayer then
                    usedMessage = usedMessage .. "\n🟢 Status: Online"
                else
                    usedMessage = usedMessage .. "\n🔴 Status: Offline"
                end
            end
            
            ChatMessage.sendError(player, usedMessage)
        end
        
        -- Log da operação
        -- print("🔍 [CHECKID] " .. player.Name .. " verificou o User ID " .. userId .. " - Status: " .. (isInUse and "EM USO" or "DISPONÍVEL"))
    else
        -- Input é um username - buscar o User ID dessa pessoa
        local username = input
        
        -- Buscar o Roblox ID pelo username
        local success, robloxId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)

        if not success then
            ChatMessage.sendError(player, "❌ Usuário '" .. username .. "' não encontrado!")
            return
        end

        -- Buscar o User ID do jogador
        local userIdFound = UserIdModule.getUserIdByRobloxId(robloxId)
        
        if not userIdFound then
            local noIdMessage = "❌ O usuário '" .. username .. "' não possui um User ID atribuído!\n"
            noIdMessage = noIdMessage .. "🔗 Roblox ID: " .. robloxId .. "\n"
            noIdMessage = noIdMessage .. "💡 O User ID será criado quando o jogador entrar no servidor"
            
            ChatMessage.sendError(player, noIdMessage)
        else
            -- Mostrar informações do usuário
            local userInfoMessage = "✅ Informações do usuário '" .. username .. "':\n"
            userInfoMessage = userInfoMessage .. "🆔 User ID: " .. userIdFound .. "\n"
            userInfoMessage = userInfoMessage .. "🔗 Roblox ID: " .. robloxId
            
            -- Verificar se está online
            local onlinePlayer = Players:GetPlayerByUserId(robloxId)
            if onlinePlayer then
                userInfoMessage = userInfoMessage .. "\n🟢 Status: Online"
            else
                userInfoMessage = userInfoMessage .. "\n🔴 Status: Offline"
            end
            
            ChatMessage.sendSuccess(player, userInfoMessage)
        end
        
        -- Log da operação
        -- print("🔍 [CHECKID] " .. player.Name .. " consultou o User ID de " .. username .. " - ID: " .. (userIdFound or "Não encontrado"))
    end
end) 