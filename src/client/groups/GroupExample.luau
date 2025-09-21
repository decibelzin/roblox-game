--[[
-- Exemplo de como usar o sistema de grupos no cliente
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Aguardar o GroupClient carregar
local function waitForGroupClient()
    while not _G.GroupClient do
        wait(0.1)
    end
    return _G.GroupClient
end

local GroupClient = waitForGroupClient()

-- Exemplo 1: Verificar permissões
local function checkPermissions()
    if GroupClient.hasPermission("canKick") then
        print("Você pode kickar players!")
    end
    
    if GroupClient.hasPermission("canBan") then
        print("Você pode banir players!")
    end
    
    if GroupClient.hasPermission("canUseVIPCommands") then
        print("Você pode usar comandos VIP!")
    end
end

-- Exemplo 2: Obter grupos do player
local function showPlayerGroups()
    local groups = GroupClient.getPlayerGroups()
    print("Seus grupos:", groups)
    
    -- Verificar grupos específicos
    if GroupClient.hasGroup("Admin") then
        print("Você é um administrador!")
    end
    
    if GroupClient.hasGroup("Vip") then
        print("Você é VIP!")
    end
end

-- Exemplo 3: Obter informações completas dos grupos
local function showGroupInfo()
    local groupsWithInfo = GroupClient.getPlayerGroupsWithInfo()
    
    for groupName, info in pairs(groupsWithInfo) do
        print(string.format("Grupo: %s | Nome: %s | Cor: %s", 
            groupName, info.displayName, tostring(info.color)))
    end
end

-- Exemplo 4: Atualizar UI baseada em permissões
local function updateUI()
    -- Simular criação de botões baseado em permissões
    if GroupClient.hasPermission("canKick") then
        print("Criando botão de kick...")
    end
    
    if GroupClient.hasPermission("canBan") then
        print("Criando botão de ban...")
    end
    
    if GroupClient.hasPermission("canUseVIPCommands") then
        print("Criando seção VIP...")
    end
end

-- Exemplo 5: Sistema de comandos baseado em permissões
local function setupCommands()
    player.Chatted:Connect(function(message)
        if message == "/mygroups" then
            showPlayerGroups()
        elseif message == "/mypermissions" then
            checkPermissions()
        elseif message == "/groupinfo" then
            showGroupInfo()
        end
    end)
end

-- Executar quando o character spawnar
player.CharacterAdded:Connect(function()
    wait(1) -- Aguardar GroupClient carregar
    checkPermissions()
    showPlayerGroups()
    updateUI()
    setupCommands()
end)

-- Executar imediatamente se já estiver no jogo
if player.Character then
    wait(1)
    checkPermissions()
    showPlayerGroups()
    updateUI()
    setupCommands()
end

print("Exemplo de uso do sistema de grupos carregado!")



]]