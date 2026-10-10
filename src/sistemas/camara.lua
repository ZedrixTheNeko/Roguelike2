local constantes = require("src.constantes")

local Camara = {}
Camara.__index = Camara

local OFFSET_MAX = 30   -- pixeles maximos de desplazamiento
local SUAVIZADO = 5     -- mas alto = mas rapido

function Camara.nuevo(anchoMundo, altoMundo)
  local c = setmetatable({}, Camara)
  c.x, c.y = 0, 0
  c.offsetX, c.offsetY = 0, 0
  c.anchoMundo = anchoMundo
  c.altoMundo = altoMundo
  return c
end

-- dirX/dirY: direccion hacia donde apunta el jugador (normalizada, o 0,0)
function Camara:seguir(objetivoX, objetivoY, dirX, dirY, dt)
  -- Offset objetivo (hacia donde apunta el jugador)
  local objetivoOffX = dirX * OFFSET_MAX
  local objetivoOffY = dirY * OFFSET_MAX

  local f = math.min(1, dt * SUAVIZADO)
  self.offsetX = self.offsetX + (objetivoOffX - self.offsetX) * f
  self.offsetY = self.offsetY + (objetivoOffY - self.offsetY) * f

  local centroX = constantes.ANCHO_VIRTUAL / 2 + self.offsetX
  local centroY = constantes.ALTO_VIRTUAL / 2 + self.offsetY

  local desX = objetivoX - centroX
  local desY = objetivoY - centroY

  local factor = math.min(1, dt * 8)
  self.x = self.x + (desX - self.x) * factor
  self.y = self.y + (desY - self.y) * factor

  if self.anchoMundo > constantes.ANCHO_VIRTUAL then
    self.x = math.max(0, math.min(self.x, self.anchoMundo - constantes.ANCHO_VIRTUAL))
  else
    self.x = (self.anchoMundo - constantes.ANCHO_VIRTUAL) / 2
  end
  if self.altoMundo > constantes.ALTO_VIRTUAL then
    self.y = math.max(0, math.min(self.y, self.altoMundo - constantes.ALTO_VIRTUAL))
  else
    self.y = (self.altoMundo - constantes.ALTO_VIRTUAL) / 2
  end
end

function Camara:aplicar()
  love.graphics.push()
  love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camara:quitar()
  love.graphics.pop()
end

return Camara