--[[
  Inicializador do Sistema TimePlayed Refatorado
  
  Este script substitui o sistema antigo por uma versão modular e mais limpa.
]]

local TimePlayedClass = require(script.Parent["refactored-class"])

-- Inicializar o sistema
local timePlayedSystem = TimePlayedClass.new()

-- Exportar para uso em outros scripts se necessário
return timePlayedSystem 