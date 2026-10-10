local NPC = {}
NPC.__index = NPC

function NPC.nuevaJoy(x, y)
  local n = setmetatable({}, NPC)
  n.tipo = "joy"
  n.x, n.y = x, y
  n.radio = 8
  n.anchoDibujo = 14
  n.altoDibujo = 22
  n.anim = 0
  n.precioCura = 15
  n.resaltado = false
  return n
end

function NPC.nuevaMack(x, y)
  local n = setmetatable({}, NPC)
  n.tipo = "mack"
  n.x, n.y = x, y
  n.radio = 10
  n.anchoDibujo = 24
  n.altoDibujo = 28
  n.anim = 0
  n.resaltado = false
  return n
end

function NPC.nuevoHerrero(x, y)
  local n = setmetatable({}, NPC)
  n.tipo = "herrero"
  n.x, n.y = x, y
  n.radio = 10
  n.anchoDibujo = 24
  n.altoDibujo = 30
  n.anim = 0
  n.resaltado = false
  return n
end

function NPC:actualizar(dt)
  self.anim = self.anim + dt
end

function NPC:cerca(jugador)
  local dx = jugador.x - self.x
  local dy = jugador.y - self.y
  local r = jugador.radio + self.radio + 14
  return dx * dx + dy * dy < r * r
end

function NPC:dibujar()
  if self.tipo == "joy" then
    self:dibujarJoy()
  elseif self.tipo == "mack" then
    self:dibujarMack()
  elseif self.tipo == "herrero" then
    self:dibujarHerrero()
  end
end

function NPC:dibujarJoy()
  local cx, cy = self.x, self.y
  local bob = math.sin(self.anim * 2) * 1

  if self.resaltado then
    local pulso = 0.5 + 0.5 * math.sin(self.anim * 5)
    love.graphics.setColor(1, 0.85, 0.35, 0.20 + pulso * 0.20)
    love.graphics.circle("fill", cx, cy + bob, 22)
    love.graphics.setColor(1, 0.95, 0.5, 0.85)
    love.graphics.circle("line", cx, cy + bob, 22)
  end

  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.ellipse("fill", cx, cy + self.altoDibujo / 2 - 1, 7, 3)

  love.graphics.setColor(0.95, 0.95, 0.98)
  love.graphics.rectangle("fill", cx - 7, cy - 2 + bob, 14, 12, 2)

  love.graphics.setColor(0.9, 0.25, 0.30)
  love.graphics.rectangle("fill", cx - 1, cy + 2 + bob, 3, 7)
  love.graphics.rectangle("fill", cx - 3, cy + 4 + bob, 7, 3)

  love.graphics.setColor(1, 0.85, 0.75)
  love.graphics.circle("fill", cx, cy - 8 + bob, 6)

  love.graphics.setColor(0.95, 0.55, 0.75)
  love.graphics.circle("fill", cx, cy - 10 + bob, 7)
  love.graphics.rectangle("fill", cx - 7, cy - 10 + bob, 14, 5)
  love.graphics.circle("fill", cx - 6, cy - 6 + bob, 3)
  love.graphics.circle("fill", cx + 6, cy - 6 + bob, 3)

  love.graphics.setColor(0.15, 0.10, 0.15)
  love.graphics.circle("fill", cx - 2, cy - 7 + bob, 1)
  love.graphics.circle("fill", cx + 2, cy - 7 + bob, 1)

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", cx - 4, cy - 15 + bob, 8, 3, 1)
  love.graphics.setColor(0.9, 0.25, 0.30)
  love.graphics.rectangle("fill", cx - 1, cy - 15 + bob, 2, 3)
  love.graphics.rectangle("fill", cx - 3, cy - 14 + bob, 6, 1)
end

function NPC:dibujarMack()
  local cx, cy = self.x, self.y
  local bob = math.sin(self.anim * 2) * 1

  if self.resaltado then
    local pulso = 0.5 + 0.5 * math.sin(self.anim * 5)
    love.graphics.setColor(1, 0.65, 0.20, 0.20 + pulso * 0.20)
    love.graphics.circle("fill", cx, cy + bob, 28)
    love.graphics.setColor(1, 0.80, 0.40, 0.85)
    love.graphics.circle("line", cx, cy + bob, 28)
  end

  love.graphics.setColor(0, 0, 0, 0.30)
  love.graphics.ellipse("fill", cx, cy + 14, 12, 4)

  love.graphics.setColor(0.55, 0.50, 0.45)
  love.graphics.rectangle("fill", cx - 7, cy + 6 + bob, 4, 8)
  love.graphics.rectangle("fill", cx + 3, cy + 6 + bob, 4, 8)
  love.graphics.setColor(0.35, 0.30, 0.28)
  love.graphics.rectangle("fill", cx - 7, cy + 6 + bob, 4, 1.5)
  love.graphics.rectangle("fill", cx + 3, cy + 6 + bob, 4, 1.5)

  love.graphics.setColor(0.60, 0.55, 0.50)
  love.graphics.rectangle("fill", cx - 10, cy - 8 + bob, 20, 16, 2)

  love.graphics.setColor(0.40, 0.35, 0.32)
  love.graphics.rectangle("fill", cx - 6, cy - 4 + bob, 12, 8, 1)
  love.graphics.setColor(0.35, 0.85, 0.95)
  love.graphics.circle("fill", cx - 3, cy - 1 + bob, 1.5)
  love.graphics.setColor(1, 0.45, 0.20)
  love.graphics.circle("fill", cx, cy - 1 + bob, 1)
  love.graphics.setColor(0.55, 0.95, 0.40)
  love.graphics.circle("fill", cx + 3, cy - 1 + bob, 1.5)

  love.graphics.setColor(0.35, 0.30, 0.28)
  love.graphics.circle("fill", cx - 8, cy - 6 + bob, 1)
  love.graphics.circle("fill", cx + 8, cy - 6 + bob, 1)
  love.graphics.circle("fill", cx - 8, cy + 6 + bob, 1)
  love.graphics.circle("fill", cx + 8, cy + 6 + bob, 1)

  love.graphics.setColor(0.50, 0.45, 0.42)
  love.graphics.rectangle("fill", cx - 2, cy - 12 + bob, 4, 5)

  love.graphics.setColor(0.65, 0.60, 0.55)
  love.graphics.rectangle("fill", cx - 8, cy - 22 + bob, 16, 12, 2)
  love.graphics.setColor(0.45, 0.40, 0.38)
  love.graphics.rectangle("line", cx - 8, cy - 22 + bob, 16, 12, 2)

  love.graphics.setColor(0.15, 0.10, 0.10)
  love.graphics.rectangle("fill", cx - 6, cy - 19 + bob, 12, 5, 1)
  love.graphics.setColor(0.95, 0.45, 0.20)
  love.graphics.rectangle("fill", cx - 5, cy - 18 + bob, 4, 3)
  love.graphics.rectangle("fill", cx + 1, cy - 18 + bob, 4, 3)

  love.graphics.setColor(1, 0.85, 0.55, 0.9)
  love.graphics.rectangle("fill", cx - 5, cy - 18 + bob, 1.5, 1)
  love.graphics.rectangle("fill", cx + 1, cy - 18 + bob, 1.5, 1)

  love.graphics.setColor(0.40, 0.35, 0.32)
  love.graphics.rectangle("fill", cx - 1, cy - 30 + bob, 2, 8)
  local pulsoAntena = 0.5 + 0.5 * math.sin(self.anim * 6)
  love.graphics.setColor(1, 0.35, 0.20, 0.7 + pulsoAntena * 0.3)
  love.graphics.circle("fill", cx, cy - 31 + bob, 2.5)
  love.graphics.setColor(1, 0.90, 0.60, 0.9)
  love.graphics.circle("fill", cx, cy - 31 + bob, 1.2)

  love.graphics.setColor(0.40, 0.22, 0.12)
  love.graphics.ellipse("fill", cx, cy - 23 + bob, 13, 3)
  love.graphics.setColor(0.55, 0.32, 0.18)
  love.graphics.ellipse("fill", cx, cy - 23 + bob, 12, 2)
  love.graphics.setColor(0.40, 0.22, 0.12)
  love.graphics.polygon("fill",
    cx - 8, cy - 23 + bob, cx + 8, cy - 23 + bob,
    cx + 6, cy - 32 + bob, cx - 6, cy - 32 + bob)

  love.graphics.setColor(0.75, 0.35, 0.20)
  love.graphics.rectangle("fill", cx - 7, cy - 26 + bob, 14, 2.5)

  love.graphics.setColor(0.95, 0.80, 0.25)
  love.graphics.circle("fill", cx, cy - 29 + bob, 2)
  love.graphics.setColor(1, 0.95, 0.55)
  love.graphics.circle("fill", cx, cy - 29 + bob, 1)

  love.graphics.setColor(0.50, 0.45, 0.42)
  love.graphics.rectangle("fill", cx - 14, cy - 6 + bob, 5, 12)
  love.graphics.rectangle("fill", cx + 9, cy - 6 + bob, 5, 12)
  love.graphics.setColor(0.40, 0.35, 0.32)
  love.graphics.rectangle("fill", cx - 14, cy - 6 + bob, 5, 1.5)
  love.graphics.rectangle("fill", cx + 9, cy - 6 + bob, 5, 1.5)
end

-- NUEVO: HERRERO
function NPC:dibujarHerrero()
  local cx, cy = self.x, self.y
  local bob = math.sin(self.anim * 1.5) * 0.8

  if self.resaltado then
    local pulso = 0.5 + 0.5 * math.sin(self.anim * 5)
    love.graphics.setColor(1, 0.55, 0.15, 0.25 + pulso * 0.20)
    love.graphics.circle("fill", cx, cy + bob, 30)
    love.graphics.setColor(1, 0.70, 0.25, 0.85)
    love.graphics.circle("line", cx, cy + bob, 30)
  end

  -- Sombra
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", cx, cy + 15, 14, 4)

  -- Yunque a la derecha
  local ax = cx + 24
  local ay = cy + 8
  love.graphics.setColor(0.10, 0.10, 0.12)
  love.graphics.ellipse("fill", ax, ay + 8, 12, 3)
  love.graphics.setColor(0.25, 0.25, 0.30)
  love.graphics.rectangle("fill", ax - 8, ay + 2, 16, 6, 1)
  love.graphics.setColor(0.35, 0.35, 0.42)
  love.graphics.rectangle("fill", ax - 10, ay - 4, 20, 6, 1)
  love.graphics.setColor(0.45, 0.45, 0.52)
  love.graphics.rectangle("fill", ax - 10, ay - 4, 20, 1.5, 1)
  -- Cuerno del yunque
  love.graphics.setColor(0.30, 0.30, 0.36)
  love.graphics.polygon("fill",
    ax + 8, ay - 4,
    ax + 16, ay - 2,
    ax + 8, ay + 1)

  -- Base del yunque
  love.graphics.setColor(0.20, 0.20, 0.25)
  love.graphics.rectangle("fill", ax - 6, ay + 8, 12, 3)

  -- Fuego de forja (brasas)
  local pulsoFuego = 0.5 + 0.5 * math.sin(self.anim * 8)
  love.graphics.setColor(1, 0.40, 0.10, 0.35 + pulsoFuego * 0.15)
  love.graphics.circle("fill", ax, ay - 2, 14 + pulsoFuego * 2)
  love.graphics.setColor(1, 0.65, 0.20, 0.6 + pulsoFuego * 0.3)
  love.graphics.circle("fill", ax, ay - 3, 6 + pulsoFuego * 1.5)
  love.graphics.setColor(1, 0.90, 0.50, 0.9)
  love.graphics.circle("fill", ax, ay - 3, 3)

  -- Chispas
  for i = 1, 3 do
    local ang = self.anim * 3 + i * 2.1
    local dist = 10 + math.sin(self.anim * 5 + i) * 6
    love.graphics.setColor(1, 0.70, 0.20, 0.7)
    love.graphics.circle("fill", ax + math.cos(ang) * dist, ay - 6 + math.sin(ang) * dist * 0.5, 1.5)
  end

  -- Cuerpo del herrero (delantal de cuero marron)
  love.graphics.setColor(0.40, 0.22, 0.12)
  love.graphics.rectangle("fill", cx - 9, cy - 6 + bob, 18, 16, 2)
  love.graphics.setColor(0.55, 0.32, 0.18)
  love.graphics.rectangle("fill", cx - 8, cy - 6 + bob, 16, 3, 2)

  -- Detalle del delantal (linea central)
  love.graphics.setColor(0.30, 0.16, 0.08)
  love.graphics.rectangle("fill", cx - 0.5, cy - 4 + bob, 1, 14)

  -- Camisa debajo (gris)
  love.graphics.setColor(0.70, 0.68, 0.65)
  love.graphics.rectangle("fill", cx - 11, cy - 8 + bob, 22, 4)
  love.graphics.setColor(0.55, 0.53, 0.50)
  love.graphics.rectangle("fill", cx - 11, cy - 8 + bob, 22, 1)

  -- Brazos musculosos
  love.graphics.setColor(0.90, 0.72, 0.58)
  love.graphics.rectangle("fill", cx - 14, cy - 8 + bob, 5, 12)
  love.graphics.rectangle("fill", cx + 9, cy - 8 + bob, 5, 12)
  love.graphics.setColor(0.75, 0.58, 0.45)
  love.graphics.rectangle("fill", cx - 14, cy - 8 + bob, 5, 1.5)
  love.graphics.rectangle("fill", cx + 9, cy - 8 + bob, 5, 1.5)

  -- Puños
  love.graphics.setColor(1, 0.82, 0.68)
  love.graphics.circle("fill", cx - 11.5, cy + 5 + bob, 3)
  love.graphics.circle("fill", cx + 11.5, cy + 5 + bob, 3)

  -- Cabeza con color piel
  love.graphics.setColor(1, 0.80, 0.65)
  love.graphics.circle("fill", cx, cy - 15 + bob, 7)

  -- Barba grande
  love.graphics.setColor(0.55, 0.35, 0.20)
  love.graphics.arc("fill", cx, cy - 13 + bob, 7.5, 0.1, math.pi - 0.1)
  love.graphics.polygon("fill",
    cx - 6, cy - 14 + bob,
    cx + 6, cy - 14 + bob,
    cx + 4, cy - 4 + bob,
    cx - 4, cy - 4 + bob)
  love.graphics.setColor(0.75, 0.55, 0.35)
  love.graphics.polygon("fill",
    cx - 4, cy - 13 + bob,
    cx - 1, cy - 13 + bob,
    cx - 1, cy - 8 + bob)
  love.graphics.polygon("fill",
    cx + 1, cy - 13 + bob,
    cx + 4, cy - 13 + bob,
    cx + 4, cy - 8 + bob)

  -- Bigote
  love.graphics.setColor(0.45, 0.28, 0.15)
  love.graphics.rectangle("fill", cx - 5, cy - 14 + bob, 10, 2, 1)

  -- Ojos
  love.graphics.setColor(0.10, 0.08, 0.05)
  love.graphics.circle("fill", cx - 2.5, cy - 16 + bob, 1)
  love.graphics.circle("fill", cx + 2.5, cy - 16 + bob, 1)

  -- Ceño fruncido
  love.graphics.setColor(0.35, 0.20, 0.10)
  love.graphics.rectangle("fill", cx - 4, cy - 18 + bob, 3, 1)
  love.graphics.rectangle("fill", cx + 1, cy - 18 + bob, 3, 1)

  -- Pelo corto (calvo en la parte de arriba, pelo a los lados)
  love.graphics.setColor(0.40, 0.25, 0.12)
  love.graphics.arc("fill", cx, cy - 18 + bob, 7, math.pi * 1.1, math.pi * 1.9)
  love.graphics.circle("fill", cx - 6, cy - 14 + bob, 2)
  love.graphics.circle("fill", cx + 6, cy - 14 + bob, 2)

  -- Banda en la frente (cuero)
  love.graphics.setColor(0.35, 0.20, 0.10)
  love.graphics.rectangle("fill", cx - 7, cy - 20 + bob, 14, 2.5)
  love.graphics.setColor(0.55, 0.35, 0.20)
  love.graphics.rectangle("fill", cx - 7, cy - 20 + bob, 14, 0.8)

  -- Martillo apoyado en el yunque
  local hx = ax + 4
  local hy = ay - 8
  love.graphics.setColor(0.45, 0.32, 0.18)
  love.graphics.rectangle("fill", hx - 1, hy, 2, 10)
  love.graphics.setColor(0.55, 0.55, 0.62)
  love.graphics.rectangle("fill", hx - 5, hy - 3, 10, 4, 1)
  love.graphics.setColor(0.70, 0.70, 0.78)
  love.graphics.rectangle("fill", hx - 5, hy - 3, 10, 1.5, 1)
end

return NPC