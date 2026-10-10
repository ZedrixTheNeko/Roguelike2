local BotonRedondo = {}
BotonRedondo.__index = BotonRedondo

-- ============================================================
-- PALETA
-- ============================================================
local DORADO      = {1.00, 0.80, 0.30}
local DORADO_CLARO= {1.00, 0.95, 0.65}
local AZUL_BRILLO = {0.55, 0.85, 1.00}

function BotonRedondo.nuevo(cx, cy, radio, etiqueta, colorBase, alSoltar)
  local b = setmetatable({}, BotonRedondo)
  b.cx, b.cy = cx, cy
  b.radio = radio
  b.etiqueta = etiqueta or ""
  b.colorBase = colorBase or {0.35, 0.50, 0.75}
  b.presionado = false
  b.touchId = nil
  b.cooldown = 0
  b.cooldownTotal = 0
  b.alSoltar = alSoltar
  b.tiempo = 0
  return b
end

function BotonRedondo:contiene(x, y)
  local dx, dy = x - self.cx, y - self.cy
  return dx * dx + dy * dy <= self.radio * self.radio
end

function BotonRedondo:touchpressed(id, x, y)
  if self.touchId then return false end
  if not self:contiene(x, y) then return false end
  self.touchId = id
  self.presionado = true
  return true
end

function BotonRedondo:touchreleased(id, x, y)
  if self.touchId ~= id then return false end
  self.touchId = nil
  self.presionado = false
  if self:contiene(x, y) and self.alSoltar then self.alSoltar() end
  return true
end

function BotonRedondo:estaPulsado()
  return self.presionado
end

function BotonRedondo:listo()
  return self.cooldown <= 0
end

function BotonRedondo:activarCooldown(segundos)
  self.cooldown = segundos
  self.cooldownTotal = segundos
end

function BotonRedondo:actualizar(dt)
  self.tiempo = self.tiempo + dt
  if self.cooldown > 0 then
    self.cooldown = math.max(0, self.cooldown - dt)
  end
end

-- ============================================================
-- DIBUJADO ARCANO
-- ============================================================

function BotonRedondo:dibujar()
  local c = self.colorBase
  local radio = self.radio
  local tiempoPulso = 0.5 + 0.5 * math.sin(self.tiempo * 2)

  -- ============================================================
  -- Sombra exterior profunda
  -- ============================================================
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.circle("fill", self.cx, self.cy + 2, radio + 2)

  -- ============================================================
  -- Anillo exterior decorativo (puntos y marcas)
  -- ============================================================
  -- Circulo base oscuro
  love.graphics.setColor(0.05, 0.08, 0.15, 0.9)
  love.graphics.circle("fill", self.cx, self.cy, radio + 2)

  -- Si esta pulsado, resaltar el anillo exterior
  if self.presionado then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.95)
  else
    love.graphics.setColor(c[1], c[2], c[3], 0.85)
  end
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", self.cx, self.cy, radio + 2)
  love.graphics.setLineWidth(1)

  -- 8 puntitos alrededor
  for i = 1, 8 do
    local ang = (i - 1) / 8 * math.pi * 2 + self.tiempo * 0.2
    local px = self.cx + math.cos(ang) * (radio + 2)
    local py = self.cy + math.sin(ang) * (radio + 2)

    if self.presionado then
      love.graphics.setColor(DORADO_CLARO[1], DORADO_CLARO[2], DORADO_CLARO[3], 1)
    else
      love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.65)
    end
    love.graphics.circle("fill", px, py, 1.5)
  end

  -- ============================================================
  -- Cuerpo del boton (gradiente radial)
  -- ============================================================
  local cBase = {c[1] * 0.55, c[2] * 0.55, c[3] * 0.55}
  if self.presionado then
    cBase = {c[1] * 0.85, c[2] * 0.85, c[3] * 0.85}
  end

  -- Circulo exterior
  love.graphics.setColor(cBase[1], cBase[2], cBase[3], 0.95)
  love.graphics.circle("fill", self.cx, self.cy, radio)

  -- Circulo interior mas claro (efecto de luz desde arriba)
  local cInterior = {
    math.min(1, c[1] + 0.15 + (self.presionado and 0.20 or 0)),
    math.min(1, c[2] + 0.15 + (self.presionado and 0.20 or 0)),
    math.min(1, c[3] + 0.15 + (self.presionado and 0.20 or 0)),
  }
  love.graphics.setColor(cInterior[1], cInterior[2], cInterior[3], 0.9)
  love.graphics.circle("fill", self.cx, self.cy - radio * 0.15, radio * 0.8)

  -- Reflejo superior (highlight)
  love.graphics.setColor(1, 1, 1, 0.35 + tiempoPulso * 0.15)
  love.graphics.ellipse("fill", self.cx - radio * 0.25, self.cy - radio * 0.35, radio * 0.35, radio * 0.25)

  -- ============================================================
  -- Anillo interior decorativo (runas latiendo)
  -- ============================================================
  love.graphics.setColor(cInterior[1] + 0.1, cInterior[2] + 0.1, cInterior[3] + 0.1, 0.5)
  love.graphics.setLineWidth(1)
  love.graphics.circle("line", self.cx, self.cy, radio - 4)

  -- ============================================================
  -- Cooldown overlay
  -- ============================================================
  if self.cooldown > 0 and self.cooldownTotal > 0 then
    local frac = self.cooldown / self.cooldownTotal
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.arc("fill", self.cx, self.cy, radio,
      -math.pi / 2, -math.pi / 2 + math.pi * 2 * frac)

    -- Numero del cooldown en dorado
    local f = love.graphics.getFont()
    local txt = string.format("%.1f", self.cooldown)
    local tw = f:getWidth(txt)
    local th = f:getHeight()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.print(txt, self.cx - tw / 2 + 1, self.cy - th / 2 + 1)
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 1)
    love.graphics.print(txt, self.cx - tw / 2, self.cy - th / 2)
  end

  -- ============================================================
  -- Etiqueta (numero de habilidad)
  -- ============================================================
  if self.etiqueta ~= "" and self.cooldown <= 0 then
    local f = love.graphics.getFont()
    local tw = f:getWidth(self.etiqueta)
    local th = f:getHeight()
    local tx = self.cx - tw / 2
    local ty = self.cy - th / 2

    -- Sombra
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.print(self.etiqueta, tx + 1, ty + 1)

    -- Glow sutil
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print(self.etiqueta, tx - 0.5, ty)
    love.graphics.print(self.etiqueta, tx + 0.5, ty)
    love.graphics.print(self.etiqueta, tx, ty - 0.5)
    love.graphics.print(self.etiqueta, tx, ty + 0.5)

    -- Texto principal
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.etiqueta, tx, ty)
  end

  -- ============================================================
  -- Aura aditiva si esta pulsado
  -- ============================================================
  if self.presionado then
    love.graphics.setBlendMode("add")
    love.graphics.setColor(c[1], c[2], c[3], 0.25 + tiempoPulso * 0.15)
    love.graphics.circle("fill", self.cx, self.cy, radio + 8)
    love.graphics.setBlendMode("alpha")
  end
end

return BotonRedondo