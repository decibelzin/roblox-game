local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Aguardar RemoteEvents carregarem
local GetPlayerGroups = ReplicatedStorage:WaitForChild("GetPlayerGroups")
local CheckPermission = ReplicatedStorage:WaitForChild("CheckPermission")
local GetGroupInfo = ReplicatedStorage:WaitForChild("GetGroupInfo")
local GetAllGroups = ReplicatedStorage:WaitForChild("GetAllGroups")

-- Variáveis para armazenar dados
local playerGroups = {}
local allGroups = {}

-- Função para obter grupos do player
local function loadPlayerGroups()
    GetPlayerGroups:FireServer()
end

-- Função para verificar permissão específica
local function hasPermission(permission)
    return CheckPermission:InvokeServer(permission)
end

-- Função para obter informações de um grupo
local function getGroupInfo(groupName)
    return GetGroupInfo:InvokeServer(groupName)
end

-- Função para obter todos os grupos disponíveis
local function loadAllGroups()
    allGroups = GetAllGroups:InvokeServer()
    return allGroups
end

-- Função para obter grupos do player
local function getPlayerGroups()
    return playerGroups
end

-- Função para verificar se player tem um grupo específico
local function hasGroup(groupName)
    return playerGroups[groupName] == true
end

-- Função para obter grupos com informações completas
local function getPlayerGroupsWithInfo()
    local groupsWithInfo = {}
    for groupName, _ in pairs(playerGroups) do
        groupsWithInfo[groupName] = getGroupInfo(groupName)
    end
    return groupsWithInfo
end

-- Eventos
GetPlayerGroups.OnClientEvent:Connect(function(groups)
    playerGroups = groups
    print("Grupos atualizados:", groups)
    
    -- Aqui você pode atualizar a UI baseada nos grupos
    updateUI()
end)

-- Função para atualizar UI (implementar conforme necessário)
function updateUI()
    -- Exemplo: mostrar/esconder botões baseado nas permissões
    if hasPermission("canKick") then
        print("Mostrar botão de kick")
    end
    
    if hasPermission("canBan") then
        print("Mostrar botão de ban")
    end
    
    if hasPermission("canUseVIPCommands") then
        print("Mostrar comandos VIP")
    end
end

-- Carregar dados quando o player spawna
player.CharacterAdded:Connect(function()
    loadPlayerGroups()
    loadAllGroups()
end)

-- Carregar dados imediatamente se já estiver no jogo
if player.Character then
    loadPlayerGroups()
    loadAllGroups()
end

-- Exportar funções para uso em outros scripts
local GroupClient = {
    hasPermission = hasPermission,
    getPlayerGroups = getPlayerGroups,
    hasGroup = hasGroup,
    getGroupInfo = getGroupInfo,
    getPlayerGroupsWithInfo = getPlayerGroupsWithInfo,
    loadPlayerGroups = loadPlayerGroups
}

-- Tornar disponível globalmente
_G.GroupClient = GroupClient

print("GroupClient carregado com sucesso!")
