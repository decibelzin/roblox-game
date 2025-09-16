-- Configurações compartilhadas entre cliente e servidor
local GameConfig = {}

GameConfig.GAME_NAME = "NOME DO JOGO"
GameConfig.SPAWN_POSITION = Vector3.new(0, 10, 0)

-- Configurações de UI
GameConfig.UI = {
    TITLE_SIZE = UDim2.new(0, 400, 0, 80),
    TITLE_POSITION = UDim2.new(0.5, -200, 0.3, 0),
    PLAY_BUTTON_SIZE = UDim2.new(0, 200, 0, 50),
    PLAY_BUTTON_POSITION = UDim2.new(0.5, -100, 0.5, 0),
    CORNER_RADIUS = UDim.new(0, 10)
}

-- Configurações de câmera
GameConfig.CAMERA = {
    POSITION = Vector3.new(50, 20, 50),
    LOOK_AT = Vector3.new(0, 0, 0)
}

return GameConfig
