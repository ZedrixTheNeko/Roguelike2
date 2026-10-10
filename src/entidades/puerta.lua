local Puerta = {}
Puerta.__index = Puerta

function Puerta.nueva(x, y)
  local p = setmetatable({}, Puerta)
  p.x, p.y = x, y
  p.ancho = 20
  p.alto = 28
  p.abierta = false
  p.tiempoApertura = 0
  p.tiempoAnim = 0
  return p
end

function Puerta:abrir()
  self.abierta = true
  self.tiempoApertura = 0
end

function Puerta:actualizar(dt)
  self.tiempoAnim = self.tiempoAnim + dt
  if self.abierta then
    self.tiempoApertura = self.tiempoApertura + dt
  end
end

function Puerta:contiene(x, y)
  return x >= self.x - self.ancho / 2 and x <= self.x + self.ancho / 2
     and y >= self.y - self.alto / 2 and y <= self.y + self.alto / 2
end

function Puerta:dibujar()
  local w, h = self.ancho, self.alto

  if not self.abierta then
    -- Cerrrada
    love.graphics.setColor(0.30, 0.25, 0.20)
    love.graphics.rectangle("fill", self.x - w / 2, self.y - h / 2, w, h, 3)
    love.graphics.setColor(0.45, 0.40, 0.35)
    love.graphics.rectangle("line", self.x - w / 2, self.y - h / 2, w, h, 3)
    love.graphics.setColor(0.55, 0.50, 0.45)
    love.graphics.circle("fill", self.x + 5, self.y, 1.5)
  else
    -- Abierta: brillo pulsante + apertura
    local pulso = 0.5 + 0.5 * math.sin(self.tiempoAnim * 4)
    local crecido = math.min(1, self.tiempoApertura * 4)
    local wAbierta = w * crecido
    local hAbierta = h * crecido

    love.graphics.setColor(0.40, 0.85, 0.95, 0.4 + pulso * 0.3)
    love.graphics.rectangle("fill",
      self.x - wAbierta / 2, self.y - hAbierta / 2,
      wAbierta, hAbierta, 4)

    love.graphics.setColor(0.75, 0.98, 1.0, 0.9)
    love.graphics.rectangle("line",
      self.x - wAbierta / 2, self.y - hAbierta / 2,
      wAbierta, hAbierta, 4)
  end
end

return Puerta