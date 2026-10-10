local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")

local t = constantes.TILE

function L.dibujarAntorcha(x, y, fase)
  love.graphics.setColor(0.30, 0.32, 0.42)
  love.graphics.rectangle("fill", x - 2, y, 4, 14)
  love.graphics.setColor(0.50, 0.55, 0.70)
  love.graphics.rectangle("fill", x - 2, y, 2, 14)
  love.graphics.setColor(0.20, 0.22, 0.30)
  love.graphics.rectangle("fill", x + 1, y, 1, 14)

  love.graphics.setColor(0.40, 0.35, 0.20)
  love.graphics.rectangle("fill", x - 4, y + 10, 8, 3)

  local p1 = 0.5 + 0.5 * math.sin(L.tGlobal * 10 + fase)
  local p2 = 0.5 + 0.5 * math.sin(L.tGlobal * 7 + fase * 1.3)

  love.graphics.setColor(0.55, 0.30, 0.95, 0.70)
  love.graphics.ellipse("fill", x, y - 4, 5 + p1 * 1.8, 7 + p2)
  love.graphics.setColor(0.45, 0.75, 1.0, 0.9)
  love.graphics.ellipse("fill", x, y - 4, 3, 5)
  love.graphics.setColor(0.85, 0.95, 1.0, 0.95)
  love.graphics.ellipse("fill", x, y - 4, 1.5, 2.5)
  love.graphics.setColor(0.40, 0.65, 1.0, 0.10 + p1 * 0.10)
  love.graphics.circle("fill", x, y - 4, 24 + p1 * 5)
end

function L.dibujarPlanta(x, y)
  love.graphics.setColor(0.10, 0.12, 0.20, 0.55)
  love.graphics.ellipse("fill", x, y + 8, 10, 3)

  love.graphics.setColor(0.28, 0.30, 0.42)
  love.graphics.polygon("fill", x - 8, y, x + 8, y, x + 6, y + 10, x - 6, y + 10)
  love.graphics.setColor(0.50, 0.55, 0.70)
  love.graphics.rectangle("fill", x - 8, y - 1, 16, 3)
  love.graphics.setColor(0.75, 0.60, 0.25, 0.7)
  love.graphics.rectangle("fill", x - 7, y + 1, 14, 1)

  love.graphics.setColor(0.20, 0.45, 0.40)
  love.graphics.polygon("fill", x, y - 2, x - 7, y - 12, x - 3, y - 14, x - 2, y - 6)
  love.graphics.polygon("fill", x, y - 2, x + 7, y - 12, x + 3, y - 14, x + 2, y - 6)
  love.graphics.setColor(0.30, 0.60, 0.55)
  love.graphics.polygon("fill", x, y - 2, x - 4, y - 16, x, y - 18, x + 4, y - 16)
  love.graphics.setColor(0.40, 0.75, 0.70)
  love.graphics.polygon("fill", x, y - 4, x - 2, y - 12, x + 2, y - 12)
end

function L.dibujarPilarRuna(x, y)
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.ellipse("fill", x, y + 24, 18, 5)

  love.graphics.setColor(0.22, 0.24, 0.34)
  love.graphics.rectangle("fill", x - 14, y + 18, 28, 6)
  love.graphics.setColor(0.32, 0.36, 0.48)
  love.graphics.rectangle("fill", x - 12, y + 14, 24, 5)

  love.graphics.setColor(0.30, 0.34, 0.46)
  love.graphics.rectangle("fill", x - 6, y - 24, 12, 38)
  love.graphics.setColor(0.42, 0.48, 0.62)
  love.graphics.rectangle("fill", x - 5, y - 24, 3, 38)
  love.graphics.setColor(0.18, 0.22, 0.32)
  love.graphics.rectangle("fill", x + 3, y - 24, 3, 38)

  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 3)
  love.graphics.setColor(0.40, 0.85, 1.0, 0.5 + pulso * 0.4)
  for i = 0, 7 do
    local ry = y - 22 + i * 5
    local offset = math.sin(L.tGlobal * 2 + i * 0.8) * 1.5
    love.graphics.rectangle("fill", x - 1 + offset, ry, 3, 2)
  end

  love.graphics.setColor(0.55, 0.95, 1.0, 0.6 + pulso * 0.3)
  for i = 0, 3 do
    local ry = y - 20 + i * 10
    love.graphics.polygon("fill", x - 6, ry, x - 3.5, ry + 2, x - 6, ry + 4)
    love.graphics.polygon("fill", x + 6, ry, x + 3.5, ry + 2, x + 6, ry + 4)
  end

  love.graphics.setColor(0.35, 0.75, 1.0, 0.08 + pulso * 0.08)
  love.graphics.circle("fill", x, y - 2, 28 + pulso * 5)

  love.graphics.setColor(0.32, 0.36, 0.48)
  love.graphics.rectangle("fill", x - 12, y - 28, 24, 5)
  love.graphics.setColor(0.22, 0.24, 0.34)
  love.graphics.rectangle("fill", x - 14, y - 32, 28, 5)
  love.graphics.setColor(0.75, 0.60, 0.25, 0.7)
  love.graphics.rectangle("fill", x - 12, y - 28, 24, 1)

  love.graphics.setColor(0.40, 0.85, 1.0, 0.7 + pulso * 0.3)
  love.graphics.circle("fill", x, y - 36, 3.5)
  love.graphics.setColor(0.85, 0.98, 1.0, 0.9)
  love.graphics.circle("fill", x, y - 36, 1.7)
  love.graphics.setColor(0.40, 0.85, 1.0, 0.3 + pulso * 0.2)
  love.graphics.circle("fill", x, y - 36, 7 + pulso * 3)
end

function L.dibujarAlfombraPilar(x, y)
  love.graphics.setColor(0.30, 0.16, 0.48)
  love.graphics.rectangle("fill", x - 26, y - 4, 52, 40, 4)
  love.graphics.setColor(0.75, 0.60, 0.25, 0.7)
  love.graphics.rectangle("line", x - 26, y - 4, 52, 40, 4)
  love.graphics.setColor(0.85, 0.55, 0.95, 0.4)
  love.graphics.rectangle("line", x - 22, y, 44, 32, 3)

  love.graphics.setColor(0.90, 0.70, 1.0, 0.75)
  love.graphics.circle("fill", x - 18, y + 4, 1.5)
  love.graphics.circle("fill", x + 18, y + 4, 1.5)
  love.graphics.circle("fill", x - 18, y + 32, 1.5)
  love.graphics.circle("fill", x + 18, y + 32, 1.5)
end

function L.dibujarTableroMisiones(x, y)
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle("fill", x - 26, y - 22, 54, 30, 4)

  love.graphics.setColor(0.30, 0.24, 0.20)
  love.graphics.rectangle("fill", x - 28, y - 24, 56, 30, 4)
  love.graphics.setColor(0.45, 0.38, 0.32)
  love.graphics.rectangle("line", x - 28, y - 24, 56, 30, 4)

  love.graphics.setColor(0.60, 0.12, 0.16)
  love.graphics.rectangle("fill", x - 28, y - 24, 56, 11, 4)
  love.graphics.setColor(0.30, 0.04, 0.07)
  local f = love.graphics.getFont()
  local txt = "MISIONES"
  local tw = f:getWidth(txt) * 0.7
  love.graphics.print(txt, x - tw / 2, y - 22, 0, 0.7, 0.7)

  love.graphics.setColor(0.92, 0.90, 0.82)
  love.graphics.rectangle("fill", x - 22, y - 10, 14, 9, 1)
  love.graphics.rectangle("fill", x - 4, y - 10, 14, 9, 1)
  love.graphics.rectangle("fill", x - 22, y + 1, 14, 9, 1)
  love.graphics.rectangle("fill", x - 4, y + 1, 14, 9, 1)

  love.graphics.setColor(0.30, 0.30, 0.35)
  for p = 1, 4 do
    local px = (p % 2 == 1) and x - 20 or x - 2
    local py = (p <= 2) and y - 8 or y + 3
    for i = 1, 3 do
      love.graphics.rectangle("fill", px, py + (i - 1) * 2.5, 10, 0.8)
    end
  end

  love.graphics.setColor(0.85, 0.15, 0.15)
  love.graphics.circle("fill", x - 15, y - 10, 1.2)
  love.graphics.circle("fill", x + 3, y - 10, 1.2)
  love.graphics.circle("fill", x - 15, y + 1, 1.2)
  love.graphics.circle("fill", x + 3, y + 1, 1.2)
end

function L.dibujarRecepcionJoy(x, y)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", x, y + 18, 44, 9)

  local cartelW, cartelH = 72, 22
  local cartelX = x - cartelW / 2
  local cartelY = y - 50

  love.graphics.setColor(0.75, 0.15, 0.18)
  love.graphics.rectangle("fill", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.setColor(0.55, 0.08, 0.10)
  love.graphics.rectangle("line", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.rectangle("line", cartelX + 2, cartelY + 2, cartelW - 4, cartelH - 4, 2)

  love.graphics.setColor(0.30, 0.03, 0.05)
  local f = love.graphics.getFont()
  local txt = "ASISTENTE"
  local tw = f:getWidth(txt) * 0.75
  love.graphics.print(txt, x - tw / 2, cartelY + 5, 0, 0.75, 0.75)

  if L.npcJoy then
    L.npcJoy.anim = L.tGlobal
    L.npcJoy:dibujar()
  end

  love.graphics.setColor(0.25, 0.22, 0.30)
  love.graphics.rectangle("fill", x - 36, y + 4, 72, 18, 3)
  love.graphics.setColor(0.42, 0.40, 0.52)
  love.graphics.rectangle("fill", x - 36, y + 4, 72, 6, 3)
  love.graphics.setColor(0.75, 0.60, 0.25, 0.8)
  love.graphics.rectangle("fill", x - 36, y + 4, 72, 1.5, 3)
  love.graphics.setColor(0.15, 0.14, 0.20)
  love.graphics.rectangle("fill", x - 34, y + 14, 68, 1)

  love.graphics.setColor(0.92, 0.90, 0.82)
  love.graphics.rectangle("fill", x - 24, y + 7, 11, 7, 1)
  love.graphics.rectangle("fill", x + 8, y + 7, 9, 6, 1)

  love.graphics.setColor(0.20, 0.20, 0.30)
  love.graphics.rectangle("fill", x - 3, y + 7, 1.8, 8, 1)
  love.graphics.setColor(0.90, 0.85, 0.50)
  love.graphics.circle("fill", x - 2.1, y + 6, 1.4)
end

function L.dibujarPuestoMack(x, y)
  love.graphics.setColor(0.42, 0.22, 0.15)
  love.graphics.rectangle("fill", x - 40, y - 4, 80, 48, 4)
  love.graphics.setColor(0.65, 0.35, 0.20, 0.8)
  love.graphics.rectangle("line", x - 40, y - 4, 80, 48, 4)
  love.graphics.setColor(0.85, 0.60, 0.30, 0.5)
  love.graphics.rectangle("line", x - 36, y, 72, 40, 3)

  local cartelW, cartelH = 92, 22
  local cartelX = x - cartelW / 2
  local cartelY = y - 55

  love.graphics.setColor(0.55, 0.25, 0.15)
  love.graphics.rectangle("fill", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.setColor(0.35, 0.12, 0.08)
  love.graphics.rectangle("line", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.rectangle("line", cartelX + 2, cartelY + 2, cartelW - 4, cartelH - 4, 2)

  love.graphics.setColor(1, 0.85, 0.50)
  local f = love.graphics.getFont()
  local txt = "TIENDA"
  local tw = f:getWidth(txt) * 0.75
  love.graphics.print(txt, x - tw / 2, cartelY + 4, 0, 0.75, 0.75)

  if L.npcMack then
    L.npcMack.anim = L.tGlobal
    L.npcMack:dibujar()
  end

  love.graphics.setColor(0.45, 0.28, 0.15)
  love.graphics.rectangle("fill", x - 32, y + 10, 16, 16, 2)
  love.graphics.setColor(0.60, 0.40, 0.22)
  love.graphics.rectangle("fill", x - 32, y + 10, 16, 4, 2)
  love.graphics.setColor(0.35, 0.20, 0.10)
  love.graphics.line(x - 32, y + 14, x - 16, y + 14)

  love.graphics.setColor(0.45, 0.28, 0.15)
  love.graphics.rectangle("fill", x + 16, y + 10, 16, 16, 2)
  love.graphics.setColor(0.60, 0.40, 0.22)
  love.graphics.rectangle("fill", x + 16, y + 10, 16, 4, 2)
  love.graphics.setColor(0.35, 0.20, 0.10)
  love.graphics.line(x + 16, y + 14, x + 32, y + 14)

  love.graphics.setColor(0.55, 0.35, 0.20)
  love.graphics.rectangle("fill", x - 22, y - 6, 10, 10, 1)
  love.graphics.setColor(0.70, 0.50, 0.30)
  love.graphics.rectangle("fill", x - 22, y - 6, 10, 2.5, 1)
end

-- NUEVO: Puesto del Herrero (yunque + forja)
function L.dibujarPuestoHerrero(x, y)
  -- Alfombra gris/roja bajo el herrero
  love.graphics.setColor(0.35, 0.20, 0.15)
  love.graphics.rectangle("fill", x - 44, y - 4, 88, 48, 4)
  love.graphics.setColor(0.60, 0.30, 0.20, 0.8)
  love.graphics.rectangle("line", x - 44, y - 4, 88, 48, 4)
  love.graphics.setColor(0.85, 0.55, 0.25, 0.5)
  love.graphics.rectangle("line", x - 40, y, 80, 40, 3)

  -- Cartel "HERRERIA" con martillo
  local cartelW, cartelH = 100, 24
  local cartelX = x - cartelW / 2
  local cartelY = y - 58

  love.graphics.setColor(0.45, 0.15, 0.10)
  love.graphics.rectangle("fill", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.setColor(0.80, 0.35, 0.15)
  love.graphics.rectangle("line", cartelX, cartelY, cartelW, cartelH, 3)
  love.graphics.rectangle("line", cartelX + 2, cartelY + 2, cartelW - 4, cartelH - 4, 2)

  love.graphics.setColor(1, 0.75, 0.35)
  local f = love.graphics.getFont()
  local txt = "HERRERIA"
  local tw = f:getWidth(txt) * 0.8
  love.graphics.print(txt, x - tw / 2, cartelY + 5, 0, 0.8, 0.8)

  -- NPC Herrero
  if L.npcHerrero then
    L.npcHerrero.anim = L.tGlobal
    L.npcHerrero:dibujar()
  end

  -- Segundo yunque decorativo a la izquierda
  local ax2 = x - 26
  local ay2 = y + 10
  love.graphics.setColor(0.10, 0.10, 0.12)
  love.graphics.ellipse("fill", ax2, ay2 + 6, 10, 2.5)
  love.graphics.setColor(0.25, 0.25, 0.30)
  love.graphics.rectangle("fill", ax2 - 6, ay2, 12, 5, 1)
  love.graphics.setColor(0.35, 0.35, 0.42)
  love.graphics.rectangle("fill", ax2 - 8, ay2 - 5, 16, 5, 1)
  love.graphics.setColor(0.45, 0.45, 0.52)
  love.graphics.rectangle("fill", ax2 - 8, ay2 - 5, 16, 1.5, 1)
  love.graphics.setColor(0.20, 0.20, 0.25)
  love.graphics.rectangle("fill", ax2 - 5, ay2 + 5, 10, 3)

  -- Brasas al pie
  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 6)
  love.graphics.setColor(1, 0.35, 0.10, 0.4 + pulso * 0.2)
  love.graphics.circle("fill", ax2, ay2 + 3, 6 + pulso)
  love.graphics.setColor(1, 0.70, 0.25, 0.7)
  love.graphics.circle("fill", ax2, ay2 + 3, 2.5)

  -- Chispas flotantes
  for i = 1, 4 do
    local ang = L.tGlobal * 2 + i * 1.5
    local dx = math.cos(ang) * 12
    local dy = -8 - math.abs(math.sin(ang * 2)) * 8
    love.graphics.setColor(1, 0.60, 0.20, 0.7 - math.abs(math.sin(ang)))
    love.graphics.circle("fill", ax2 + dx, ay2 + dy, 1.2)
  end

  -- Caja de lingotes de hierro al lado
  love.graphics.setColor(0.30, 0.30, 0.35)
  love.graphics.rectangle("fill", x + 20, y + 12, 18, 14, 2)
  love.graphics.setColor(0.45, 0.45, 0.50)
  love.graphics.rectangle("fill", x + 20, y + 12, 18, 3, 2)
  love.graphics.setColor(0.60, 0.60, 0.65)
  love.graphics.rectangle("fill", x + 22, y + 16, 6, 3, 1)
  love.graphics.rectangle("fill", x + 30, y + 16, 6, 3, 1)
  love.graphics.setColor(0.70, 0.70, 0.75)
  love.graphics.rectangle("fill", x + 22, y + 16, 6, 1, 1)
  love.graphics.rectangle("fill", x + 30, y + 16, 6, 1, 1)
  love.graphics.setColor(0.60, 0.60, 0.65)
  love.graphics.rectangle("fill", x + 24, y + 21, 6, 3, 1)
  love.graphics.rectangle("fill", x + 32, y + 21, 6, 3, 1)
end

function L.dibujarArmario(x, y)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", x, y + 22, 40, 8)

  love.graphics.setColor(0.20, 0.18, 0.26)
  love.graphics.rectangle("fill", x - 38, y + 14, 76, 8, 2)

  love.graphics.setColor(0.28, 0.24, 0.32)
  love.graphics.rectangle("fill", x - 36, y - 32, 72, 48, 3)
  love.graphics.setColor(0.42, 0.38, 0.50)
  love.graphics.rectangle("line", x - 36, y - 32, 72, 48, 3)

  love.graphics.setColor(0.14, 0.12, 0.18)
  love.graphics.rectangle("fill", x - 1, y - 32, 2, 48)

  love.graphics.setColor(0.80, 0.65, 0.30)
  love.graphics.rectangle("fill", x - 30, y - 22, 3, 6)
  love.graphics.rectangle("fill", x - 30, y + 4, 3, 6)
  love.graphics.rectangle("fill", x + 27, y - 22, 3, 6)
  love.graphics.rectangle("fill", x + 27, y + 4, 3, 6)

  love.graphics.setColor(0.85, 0.70, 0.30)
  love.graphics.polygon("fill", x - 20, y - 18, x - 14, y - 12, x - 22, y - 10)
  love.graphics.polygon("fill", x + 20, y - 18, x + 14, y - 12, x + 22, y - 10)

  love.graphics.setColor(0.45, 0.15, 0.20)
  love.graphics.rectangle("fill", x - 36, y - 46, 72, 16, 3)
  love.graphics.setColor(0.75, 0.60, 0.25, 0.8)
  love.graphics.rectangle("line", x - 36, y - 46, 72, 16, 3)
  love.graphics.setColor(0.95, 0.85, 0.70)
  local f = love.graphics.getFont()
  local txt = "PERSONAJES"
  local tw = f:getWidth(txt) * 0.72
  love.graphics.print(txt, x - tw / 2, y - 44, 0, 0.72, 0.72)

  love.graphics.setColor(0.55, 0.75, 1.0, 0.25)
  love.graphics.rectangle("fill", x - 34, y - 30, 68, 1)
end

return L