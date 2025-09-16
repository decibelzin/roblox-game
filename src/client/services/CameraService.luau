-- Serviço responsável por gerenciar a câmera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("GameConfig"))

local CameraService = {}
CameraService.originalCamera = workspace.CurrentCamera
CameraService.originalCameraType = nil
CameraService.originalCFrame = nil

-- Função para configurar a câmera do menu
function CameraService.setupMenuCamera()
    if not CameraService.originalCamera then 
        print("Câmera não encontrada!")
        return 
    end
    
    print("Configurando câmera do menu...")
    
    -- Salvar configurações originais
    CameraService.originalCameraType = CameraService.originalCamera.CameraType
    CameraService.originalCFrame = CameraService.originalCamera.CFrame
    
    -- Posicionar a câmera na posição configurada
    CameraService.originalCamera.CameraType = Enum.CameraType.Scriptable
    CameraService.originalCamera.CFrame = CFrame.lookAt(
        GameConfig.CAMERA.POSITION, -- Posição da câmera
        GameConfig.CAMERA.LOOK_AT   -- Para onde a câmera olha
    )
    
    print("Câmera configurada!")
end

-- Função para restaurar a câmera normal
function CameraService.restoreNormalCamera()
    if not CameraService.originalCamera then return end
    
    print("Restaurando câmera normal...")
    
    -- Restaurar tipo original
    if CameraService.originalCameraType then
        CameraService.originalCamera.CameraType = CameraService.originalCameraType
    else
        CameraService.originalCamera.CameraType = Enum.CameraType.Custom
    end
    
    -- Aguardar um pouco para garantir que a câmera se ajuste
    wait(0.1)
    
    -- Forçar a câmera a seguir o jogador
    if CameraService.originalCamera.CameraType == Enum.CameraType.Custom then
        CameraService.originalCamera.CameraSubject = game.Players.LocalPlayer.Character
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            CameraService.originalCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
        end
    end
    
    print("Câmera restaurada!")
end

-- Função para resetar completamente a câmera
function CameraService.resetCamera()
    if not CameraService.originalCamera then return end
    
    print("Resetando câmera...")
    
    -- Restaurar para configurações padrão do Roblox
    CameraService.originalCamera.CameraType = Enum.CameraType.Custom
    CameraService.originalCamera.CameraSubject = game.Players.LocalPlayer.Character
    
    -- Aguardar um pouco
    wait(0.2)
    
    -- Garantir que a câmera está seguindo o jogador
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        CameraService.originalCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
    end
    
    print("Câmera resetada!")
end

return CameraService
