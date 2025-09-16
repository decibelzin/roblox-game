-- Arquivo principal do cliente - orquestra todos os serviços
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Aguardar os módulos compartilhados carregarem
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameConfig"))

-- Importar serviços
local UIService = require(script.services.UIService)
local CameraService = require(script.services.CameraService)
local GameService = require(script.services.GameService)
local PermissionUI = require(script.ui.PermissionUI)
local PrivateMessageUI = require(script.ui.PrivateMessageUI)

-- Função para carregar informações de permissão
local function loadPlayerPermissions()
    local permissionRemote = ReplicatedStorage:WaitForChild("GetPlayerPermissions")
    local success, playerInfo = pcall(function()
        return permissionRemote:InvokeServer()
    end)
    
    if success and playerInfo then
        print("Informações de permissão carregadas:")
        print("Nível: " .. playerInfo.levelName)
        print("Permissões: " .. table.concat(playerInfo.permissions, ", "))
        
        -- Mostrar informações na interface
        PermissionUI.showPlayerInfo(playerInfo)
    else
        print("Erro ao carregar permissões do jogador")
    end
end

-- Função para inicializar o menu
local function initializeMenu()
    print("Inicializando menu...")
    
    -- Ocultar elementos padrão do Roblox
    UIService.hideDefaultGui()
    
    -- Aguardar um pouco para garantir que tudo carregou
    wait(1)
    
    -- Criar o menu
    UIService.createMainMenu()
    print("Menu criado!")
    
    -- Configurar a câmera do menu
    CameraService.setupMenuCamera()
    
    -- Conectar eventos do menu
    UIService.connectMenuEvents(function()
        -- Callback para quando o botão PLAY é clicado
        GameService.startGame()
        UIService.removeMainMenu()
        UIService.restoreDefaultGui()
        
        -- Resetar câmera completamente
        CameraService.resetCamera()
        
        -- Carregar permissões após iniciar o jogo
        wait(1)
        loadPlayerPermissions()
    end)
    
    print("Menu inicializado com sucesso!")
end

-- Função para configurar eventos de câmera
local function setupCameraEvents()
    -- Verificar se o RemoteEvent existe, se não, criar
    local cameraResetEvent = ReplicatedStorage:FindFirstChild("CameraReset")
    if not cameraResetEvent then
        print("Criando RemoteEvent CameraReset...")
        cameraResetEvent = Instance.new("RemoteEvent")
        cameraResetEvent.Name = "CameraReset"
        cameraResetEvent.Parent = ReplicatedStorage
    end
    
    -- Conectar evento de reset da câmera
    cameraResetEvent.OnClientEvent:Connect(function()
        print("Resetando câmera via comando...")
        CameraService.resetCamera()
    end)
    
    print("Eventos de câmera configurados!")
end

-- Função principal
local function main()
    print("Cliente iniciado!")
    
    -- Inicializar interfaces
    PermissionUI.initialize()
    PrivateMessageUI.initialize()
    
    -- Configurar eventos de câmera
    setupCameraEvents()
    
    -- Aguardar um pouco e então inicializar
    wait(2)
    initializeMenu()
end

-- Inicializar
main()
