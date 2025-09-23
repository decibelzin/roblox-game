-- Sistema AFK - Client
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local isWindowFocused = true
local isInitialized = false

local remoteEvent = ReplicatedStorage:WaitForChild("AFKDetection")

local function checkInitialFocus()
    RunService.Heartbeat:Wait()
    isWindowFocused = UserInputService:GetFocusedTextBox() ~= nil or true 
    isInitialized = true
end

-- Detectar mudanças de foco
UserInputService.WindowFocused:Connect(function()
    if not isInitialized then return end
    if not isWindowFocused then
        isWindowFocused = true
        remoteEvent:FireServer("AFK_END")
    end
end)

UserInputService.WindowFocusReleased:Connect(function()
    if not isInitialized then return end
    if isWindowFocused then
        isWindowFocused = false
        remoteEvent:FireServer("AFK_START")
    end
end)

player.CharacterAdded:Connect(function()
    wait(1)
    checkInitialFocus()
    if isWindowFocused then
        remoteEvent:FireServer("AFK_END")
    end
end)

checkInitialFocus()

