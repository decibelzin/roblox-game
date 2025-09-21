local RegisterCommand = require(game.ReplicatedStorage.Shared['register-command'])
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local flyingPlayers = {}
local flyStateEvent = Instance.new("RemoteEvent")
flyStateEvent.Name = "FlyStateEvent"
flyStateEvent.Parent = ReplicatedStorage

local DEFAULT_SPEED = 50

local function setFlyingState(player, flying, speed)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if flying then
        humanoid:ChangeState(Enum.HumanoidStateType.Flying)
        flyingPlayers[player] = speed or DEFAULT_SPEED
    else
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        flyingPlayers[player] = nil
    end
    
    flyStateEvent:FireClient(player, flying, speed or DEFAULT_SPEED)
    print(player.Name .. (flying and " iniciou" or " parou") .. " o voo" .. (flying and " com velocidade " .. (speed or DEFAULT_SPEED) or ""))
end

local function setAllFlying(flying, speed)
    for _, player in pairs(Players:GetPlayers()) do
        setFlyingState(player, flying, speed)
    end
end

local function parseCommand(player, params)
    local targetPlayer = player
    local speed = DEFAULT_SPEED
    
    if #params > 0 then
        local firstParam = params[1]
        
        if firstParam:lower() == "all" then
            speed = tonumber(params[2]) or DEFAULT_SPEED
            setAllFlying(true, speed)
            print("Voo ativado para todos os jogadores com velocidade " .. speed)
            return
        end
        
        local targetPlayerName = Players:FindFirstChild(firstParam)
        
        if targetPlayerName then
            targetPlayer = targetPlayerName
            speed = tonumber(params[2]) or DEFAULT_SPEED
        else
            speed = tonumber(firstParam) or DEFAULT_SPEED
        end
    end
    
    local isFlying = flyingPlayers[targetPlayer]
    setFlyingState(targetPlayer, not isFlying, speed)
end

Players.PlayerRemoving:Connect(function(player)
    if flyingPlayers[player] then
        setFlyingState(player, false)
    end
end)

RegisterCommand({
    name = "fly",
    description = "Ativa/desativa o modo de voo [jogador/all] [velocidade]",
    aliases = {"f", "noclip", "nc"}
}, parseCommand)
