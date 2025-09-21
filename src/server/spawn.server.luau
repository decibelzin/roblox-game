local players = game:GetService("Players")

players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        print("Player spawnou:", player.Name)
    end)
end)