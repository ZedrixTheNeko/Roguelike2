local Joystick = {}
Joystick.__index = Joystick

-- ============================================================
-- PALETA
-- ============================================================
local AZUL_MEDIO   = {0.15, 0.35, 0.75}
local AZUL_BRILLO  = {0.55, 0.85, 1.00}
local AZUL_CLARO   = {0.85, 0.95, 1.00}
local DORADO       = {1.00, 0.80, 0.30}

function Joystick.nuevo(baseX, baseY, radioMax, radioMuerto, zonaX, zonaY, zonaW, zonaH, modo)
  local j = setmetatable({}, Joystick)
  j.baseX, j.baseY = baseX, baseY
  j.radioMax = radioMax or 35
  j.radioMuerto = radioMuerto or 33
  j.zonaX, j.zonaY, j.zonaW, j.zonaH = zonaX, zonaY, zonaW, zonaH
  j.modo = modo or "mover"
  j.activo = false
  j.touchId = nil
  j.pulgarX, j.pulgarY = baseX, baseY
  j.dx, j.dy = 0, 0
  j.magnitud = 0
  j.disparando = false
  j.tiempo = 0
  return j
end

function Joystick:enZona(x, y)
  return x >= self.zonaX and x <= self.zonaX + self.zonaW
     and y >= self.zonaY and y <= self.zonaY + self.zonaH
end

function Joystick:touchpressed(id, x, y)
  if self.activo then return false end
  if not self:enZona(x, y) then return false end
  self.activo = true
  self.touchId = id
  self.pulgarX, self.pulgarY = self.baseX, self.baseY
  self.dx, self.dy, self.magnitud = 0, 0, 0
  self.disparando = false
  return true
end

function Joystick:touchmoved(id, x, y)
  if not self.activo or id ~= self.touchId then return false end
  local dx = x - self.baseX
  local dy = y - self.baseY
  local d = math.sqrt(dx * dx + dy * dy)
  if d > self.radioMax then
    dx = dx / d * self.radioMax
    dy = dy / d * self.radioMax
    d = self.radioMax
  end
  self.pulgarX = self.baseX + dx
  self.pulgarY = self.baseY + dy
  self.magnitud = d / self.radioMax
  if d > 0.001 then
    self.dx = dx / d
    self.dy = dy / d
  else
    self.dx, self.dy = 0, 0
  end
  if self.modo == "apuntar" then
    self.disparando = d > self.radioMuerto
  else
    self.disparando = false
  end
  return true
end

function Joystick:touchreleased(id, x, y)
  if not self.activo or id ~= self.touchId then return false end
  self.activo = false
  self.touchId = nil
  self.pulgarX, self.pulgarY = self.baseX, self.baseY
  self.dx, self.dy, self.magnitud = 0, 0, 0
  self.disparando = false
  return true
end

function Joystick:actualizar(dt)
  self.tiempo = self.tiempo + dt
end

-- ============================================================
-- DIBUJADO ARCANO
-- ============================================================

function Joystick:dibujar()
  local tiempoPulso = 0.5 + 0.5 * math.sin(self.tiempo * 2)

  -- ============================================================
  -- Base: circulo con gradiente y esquinas
  -- ============================================================
  -- Sombra exterior
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.circle("fill", self.baseX, self.baseY + 2, self.radioMax + 3)

  -- Fondo base con gradiente (dos capas)
  love.graphics.setColor(0.05, 0.08, 0.15, 0.75)
  love.graphics.circle("fill", self.baseX, self.baseY, self.radioMax + 2)
  love.graphics.setColor(0.10, 0.18, 0.32, 0.5)
  love.graphics.circle("fill", self.baseX, self.baseY, self.radioMax - 2)

  -- Anillo interior decorativo
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.4)
  love.graphics.setLineWidth(1.5)
  love.graphics.circle("line", self.baseX, self.baseY, self.radioMax - 6)
  love.graphics.setLineWidth(1)

  -- Borde exterior (arcano azul)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.75)
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", self.baseX, self.baseY, self.radioMax)
  love.graphics.setLineWidth(1)

  -- Puntitos brillantes alrededor del borde (12 puntos)
  for i = 1, 12 do
    local ang = (i - 1) / 12 * math.pi * 2 + self.tiempo * 0.3
    local px = self.baseX + math.cos(ang) * self.radioMax
    local py = self.baseY + math.sin(ang) * self.radioMax
    local alpha = 0.3 + 0.4 * (0.5 + 0.5 * math.sin(self.tiempo * 3 + i))
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], alpha)
    love.graphics.circle("fill", px, py, 1.5)
  end

  -- Si es modo apuntar, dibujar el circulo muerto
  if self.modo == "apuntar" then
    local colorMuerto
    local alphaMuerto
    if self.disparando then
      colorMuerto = {0.95, 0.35, 0.35}
      alphaMuerto = 0.30 + tiempoPulso * 0.20
    else
      colorMuerto = {0.40, 0.70, 0.95}
      alphaMuerto = 0.20
    end
    love.graphics.setColor(colorMuerto[1], colorMuerto[2], colorMuerto[3], alphaMuerto)
    love.graphics.circle("fill", self.baseX, self.baseY, self.radioMuerto)
    love.graphics.setColor(colorMuerto[1], colorMuerto[2], colorMuerto[3], 0.75)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", self.baseX, self.baseY, self.radioMuerto)
    love.graphics.setLineWidth(1)
  end

  -- ============================================================
  -- Pulgar
  -- ============================================================
  local radioPulgar = 12
  local esHover = self.activo

  -- Sombra
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.circle("fill", self.pulgarX, self.pulgarY + 1.5, radioPulgar + 1)

  -- Anillo exterior brillante
  local colorAnillo
  if self.modo == "apuntar" and self.disparando then
    colorAnillo = {1.00, 0.55, 0.55}
  else
    colorAnillo = AZUL_BRILLO
  end

  love.graphics.setColor(colorAnillo[1], colorAnillo[2], colorAnillo[3], 0.9)
  love.graphics.circle("fill", self.pulgarX, self.pulgarY, radioPulgar)

  -- Relleno interior
  local alphaInterior = esHover and 0.9 or 0.5
  love.graphics.setColor(0.15, 0.30, 0.55, alphaInterior)
  love.graphics.circle("fill", self.pulgarX, self.pulgarY, radioPulgar - 3)

  -- Reflejo superior
  love.graphics.setColor(1, 1, 1, 0.5 + tiempoPulso * 0.3)
  love.graphics.circle("fill", self.pulgarX - 3, self.pulgarY - 3.5, 3)

  -- Borde
  love.graphics.setColor(colorAnillo[1], colorAnillo[2], colorAnillo[3], 1)
  love.graphics.setLineWidth(1.5)
  love.graphics.circle("line", self.pulgarX, self.pulgarY, radioPulgar)
  love.graphics.setLineWidth(1)

  -- Puntito central
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.circle("fill", self.pulgarX, self.pulgarY, 2)

  -- Pequeño aura aditiva si esta activo
  if esHover then
    love.graphics.setBlendMode("add")
    love.graphics.setColor(colorAnillo[1], colorAnillo[2], colorAnillo[3], 0.15 + tiempoPulso * 0.10)
    love.graphics.circle("fill", self.pulgarX, self.pulgarY, radioPulgar + 6)
    love.graphics.setBlendMode("alpha")
  end
end

return Joystick