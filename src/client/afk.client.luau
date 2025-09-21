-- Sistema AFK - Client
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local isWindowFocused = true

-- Aguardar RemoteEvent ser criado pelo servidor
local remoteEvent = ReplicatedStorage:WaitForChild("AFKDetection")

-- Detectar mudanças de foco
UserInputService.WindowFocused:Connect(function()
    -- print("🟢 WindowFocused disparado!")
    if not isWindowFocused then
        isWindowFocused = true
        -- print("📤 Enviando AFK_END para servidor")
        remoteEvent:FireServer("AFK_END")
    end
end)

UserInputService.WindowFocusReleased:Connect(function()
    -- print("🔴 WindowFocusReleased disparado!")
    if isWindowFocused then
        isWindowFocused = false
        -- print("📤 Enviando AFK_START para servidor")
        remoteEvent:FireServer("AFK_START")
    end
end)

-- Limpar ao spawnar
player.CharacterAdded:Connect(function()
    -- print("🔄 CharacterAdded disparado!")
    remoteEvent:FireServer("AFK_END")
end)

print("�� AFK Client iniciado!")