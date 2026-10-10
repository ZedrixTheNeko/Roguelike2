local constantes = require("src.constantes")

local Boton = {}
Boton.__index = Boton

function Boton.nuevo(x, y, w, h, texto, alPulsar)
  local b = setmetatable({}, Boton)
  b.x, b.y, b.w, b.h = x, y, w, h
  b.texto = texto
  b.alPulsar = alPulsar
  b.presionado = false
  b.toquesActivos = {}
  return b
end

function Boton:contiene(x, y)
  return x >= self.x and x <= self.x + self.w
     and y >= self.y and y <= self.y + self.h
end

function Boton:touchpressed(id, x, y)
  if self:contiene(x, y) then
    self.toquesActivos[id] = true
    self.presionado = true
    return true
  end
  return false
end

function Boton:touchreleased(id, x, y)
  if self.toquesActivos[id] then
    self.toquesActivos[id] = nil
    if self:contiene(x, y) and self.alPulsar then self.alPulsar() end
    if not next(self.toquesActivos) then self.presionado = false end
    return true
  end
  return false
end

function Boton:mousepressed(x, y, b)
  if b == 1 and self:contiene(x, y) then
    self.presionado = true
    return true
  end
  return false
end

function Boton:mousereleased(x, y, b)
  if b == 1 and self.presionado then
    self.presionado = false
    if self:contiene(x, y) and self.alPulsar then self.alPulsar() end
    return true
  end
  return false
end

function Boton:dibujar()
  local color = self.presionado and constantes.COLORES.botonActivo
                             or  constantes.COLORES.boton
  love.graphics.setColor(constantes.COLORES.botonBorde)
  love.graphics.rectangle("fill", self.x - 1, self.y - 1, self.w + 2, self.h + 2, 3)
  love.graphics.setColor(color)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 2)

  love.graphics.setColor(constantes.COLORES.texto)
  local f = love.graphics.getFont()
  local tw = f:getWidth(self.texto)
  local th = f:getHeight()
  love.graphics.print(self.texto,
    self.x + (self.w - tw) / 2,
    self.y + (self.h - th) / 2)
end

return Boton