local players = game:GetService("Players")
local player = players.LocalPlayer

player.CharacterAdded:Connect(function(character)
    print("Meu character spawnou!")
end)