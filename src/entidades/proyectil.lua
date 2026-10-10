local constantes = require("src.constantes")
local Colisiones = require("src.sistemas.colisiones")

local Proyectil = {}
Proyectil.__index = Proyectil

-- Efectos que un proyectil hostil aplica al jugador al impactar
Proyectil.EFECTOS = {
  bola_slime    = "slow",
  espora        = "slow",
  esquirla_hielo = "slow",
}

function Proyectil.nuevo()
  local p = setmetatable({}, Proyectil)
  p.x, p.y = 0, 0
  p.vx, p.vy = 0, 0
  p.dano = 0
  p.vida = 0
  p.radio = 3
  p.hostil = false
  p.tipo = "flecha"
  p.aplicaQuemadura = false
  p.target = nil
  p.danoExplosion = 0
  p.radioExplosion = 0

  -- Bumeran
  p.lanzador = nil
  p.regresando = false
  p.distanciaRecorrida = 0
  p.distanciaMax = 180
  p.anguloRotacion = 0
  p.golpeados = {}
  p.rebotesRestantes = 0

  -- Perforantes / efectos
  p.perforante = false
  p.efecto = nil

  return p
end

function Proyectil:lanzar(x, y, dirX, dirY, velocidad, dano, hostil, tipo, lanzador)
  self.x, self.y = x, y
  self.vx = dirX * velocidad
  self.vy = dirY * velocidad
  self.dano = dano
  self.vida = 2.5
  self.hostil = hostil or false
  self.tipo = tipo or "flecha"
  self.aplicaQuemadura = (self.tipo == "fuego")
  self.target = nil
  self.danoExplosion = 0
  self.radioExplosion = 0

  -- Bumeran
  self.lanzador = lanzador
  self.regresando = false
  self.distanciaRecorrida = 0
  self.distanciaMax = 180
  self.anguloRotacion = 0
  self.golpeados = {}
  self.rebotesRestantes = 0

  -- Perforantes / efectos
  self.perforante = false
  self.efecto = Proyectil.EFECTOS[self.tipo]

  -- ============================================================
  -- CONFIGURACION POR TIPO
  -- ============================================================
  if self.tipo == "bola_slime" then
    self.radio = 5

  elseif self.tipo == "fuego" then
    self.radio = 5

  elseif self.tipo == "orbe_fuego" then
    self.radio = 7
    self.vida = 3.0

  elseif self.tipo == "flecha_perforante" then
    self.radio = 6
    self.perforante = true

  elseif self.tipo == "flecha_marcadora" then
    self.radio = 4

  elseif self.tipo == "bola_oscura" then
    self.radio = 6
    self.vida = 3.5

  elseif self.tipo == "bumeran" then
    self.radio = 6
    self.vida = 3.5

  elseif self.tipo == "bumeran_ricochet" then
    self.radio = 6
    self.vida = 4.5

  elseif self.tipo == "bala" then
    self.radio = 2.5
    self.vida = 1.5

  elseif self.tipo == "bala_perforante" then
    self.radio = 3
    self.vida = 2.5
    self.perforante = true

  elseif self.tipo == "bala_plasma" then
    self.radio = 3
    self.vida = 2.0

  elseif self.tipo == "nota_musical" then
    self.radio = 4
    self.vida = 2.0

  -- ============================================================
  -- TIPOS DE LOS BIOMAS NUEVOS / JUGADORES NUEVOS
  -- ============================================================
  elseif self.tipo == "espora" then
    self.radio = 5
    self.vida = 4.0

  elseif self.tipo == "bola_fuego" then
    self.radio = 6
    self.vida = 3.2

  elseif self.tipo == "esquirla_hielo" then
    self.radio = 4
    self.vida = 3.5

  elseif self.tipo == "orbe_vacio" then
    self.radio = 7
    self.vida = 4.5

  elseif self.tipo == "roca" then
    self.radio = 8
    self.vida = 3.0

  elseif self.tipo == "daga" then
    self.radio = 3.5
    self.vida = 1.1

  elseif self.tipo == "perdigon" then
    self.radio = 3
    self.vida = 0.50

  elseif self.tipo == "onda_santa" then
    self.radio = 11
    self.vida = 0.45
    self.perforante = true
    self.golpeados = {}

  else
    self.radio = 3.5
  end
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================
function Proyectil:actualizar(dt, mapa)
  -- ============================================================
  -- BUMERANES: logica especial de ida y vuelta
  -- ============================================================
  if self.tipo == "bumeran" or self.tipo == "bumeran_ricochet" then
    self.anguloRotacion = self.anguloRotacion + dt * 30

    if not self.regresando then
      -- Fase de ida
      self.x = self.x + self.vx * dt
      self.y = self.y + self.vy * dt
      local velActual = math.sqrt(self.vx * self.vx + self.vy * self.vy)
      self.distanciaRecorrida = self.distanciaRecorrida + velActual * dt

      -- Colision con pared durante la ida
      if Colisiones.circuloConMapa(self.x, self.y, self.radio, mapa) then
        if self.tipo == "bumeran_ricochet" and self.rebotesRestantes > 0 then
          -- Ricochet: intentamos rebotar
          if not Colisiones.circuloConMapa(self.x - self.vx * dt, self.y, self.radio, mapa) then
            self.vx = -self.vx
            self.x = self.x - self.vx * dt
          elseif not Colisiones.circuloConMapa(self.x, self.y - self.vy * dt, self.radio, mapa) then
            self.vy = -self.vy
            self.y = self.y - self.vy * dt
          else
            self.regresando = true
          end
          self.rebotesRestantes = self.rebotesRestantes - 1
        else
          self.regresando = true
        end
      end

      if self.distanciaRecorrida >= self.distanciaMax then
        self.regresando = true
      end
    else
      -- Fase de vuelta: perseguimos al lanzador
      if self.lanzador and self.lanzador.vivo then
        local dx = self.lanzador.x - self.x
        local dy = self.lanzador.y - self.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < 14 then
          return false
        end
        local vel = 340
        self.vx = (dx / d) * vel
        self.vy = (dy / d) * vel
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
      else
        return false
      end
    end

    self.vida = self.vida - dt
    if self.vida <= 0 then return false end
    return true
  end

  -- ============================================================
  -- ORBE DE FUEGO persigue al objetivo (Merlin)
  -- ============================================================
  if self.tipo == "orbe_fuego" and self.target and self.target.vivo then
    local dx = self.target.x - self.x
    local dy = self.target.y - self.y
    local m = math.sqrt(dx * dx + dy * dy)
    if m > 0.01 then
      local vel = 240
      self.vx = (dx / m) * vel
      self.vy = (dy / m) * vel
    end
  end

  -- ============================================================
  -- MOVIMIENTO NORMAL
  -- ============================================================
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.vida = self.vida - dt
  if self.vida <= 0 then return false end
  if Colisiones.circuloConMapa(self.x, self.y, self.radio, mapa) then return false end
  return true
end

-- ============================================================
-- DIBUJADO - ROUTER
-- ============================================================
function Proyectil:dibujar()
  if self.tipo == "bola_slime" then
    self:dibujarBolaSlime()
  elseif self.tipo == "fuego" then
    self:dibujarFuego()
  elseif self.tipo == "orbe_fuego" then
    self:dibujarOrbeFuego()
  elseif self.tipo == "bola_oscura" then
    self:dibujarBolaOscura()
  elseif self.tipo == "flecha_perforante" then
    self:dibujarFlechaPerforante()
  elseif self.tipo == "flecha_marcadora" then
    self:dibujarFlechaMarcadora()
  elseif self.tipo == "bumeran" then
    self:dibujarBumeran(false)
  elseif self.tipo == "bumeran_ricochet" then
    self:dibujarBumeran(true)
  elseif self.tipo == "bala" then
    self:dibujarBala()
  elseif self.tipo == "bala_perforante" then
    self:dibujarBalaPerforante()
  elseif self.tipo == "bala_plasma" then
    self:dibujarBalaPlasma()
  elseif self.tipo == "nota_musical" then
    self:dibujarNotaMusical()
  -- ============================================================
  -- TIPOS DE LOS BIOMAS NUEVOS
  -- ============================================================
  elseif self.tipo == "espora" then
    self:dibujarEspora()
  elseif self.tipo == "bola_fuego" then
    self:dibujarBolaFuego()
  elseif self.tipo == "esquirla_hielo" then
    self:dibujarEsquirla()
  elseif self.tipo == "orbe_vacio" then
    self:dibujarOrbeVacio()
  elseif self.tipo == "roca" then
    self:dibujarRoca()
  -- ============================================================
  -- TIPOS DE LOS JUGADORES NUEVOS
  -- ============================================================
  elseif self.tipo == "daga" then
    self:dibujarDaga()
  elseif self.tipo == "perdigon" then
    self:dibujarBala()
  elseif self.tipo == "onda_santa" then
    self:dibujarOndaSanta()
  else
    self:dibujarFlecha()
  end
end

-- ============================================================
-- DIBUJOS CLASICOS
-- ============================================================
function Proyectil:dibujarFlecha()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  if self.hostil then
    love.graphics.setColor(0.45, 0.20, 0.15)
  else
    love.graphics.setColor(0.75, 0.55, 0.28)
  end
  love.graphics.rectangle("fill", -11, -1, 19, 2)

  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.rectangle("fill", -11, 1, 19, 0.8)

  if self.hostil then
    love.graphics.setColor(0.95, 0.35, 0.35)
  else
    love.graphics.setColor(0.88, 0.92, 0.98)
  end
  love.graphics.polygon("fill", 8, -3.5, 14, 0, 8, 3.5)

  love.graphics.setColor(1, 1, 1, 0.75)
  love.graphics.polygon("fill", 9, -1.8, 13, 0, 9, 1.8)

  if self.hostil then
    love.graphics.setColor(0.70, 0.18, 0.18)
  else
    love.graphics.setColor(0.95, 0.80, 0.45)
  end
  love.graphics.polygon("fill", -11, -3.5, -6, -0.8, -11, -0.8)
  love.graphics.polygon("fill", -13, -3.5, -8, -0.8, -13, -0.8)
  love.graphics.polygon("fill", -11, 0.8, -6, 0.8, -11, 3.5)
  love.graphics.polygon("fill", -13, 0.8, -8, 0.8, -13, 3.5)

  love.graphics.pop()
end

function Proyectil:dibujarFlechaMarcadora()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  love.graphics.setColor(0.35, 0.75, 1.0, 0.3)
  love.graphics.rectangle("fill", -22, -3, 30, 6)
  love.graphics.setColor(0.35, 0.65, 0.95)
  love.graphics.rectangle("fill", -12, -1.5, 20, 3)
  love.graphics.setColor(0.55, 0.85, 1.0)
  love.graphics.polygon("fill", 8, -4, 16, 0, 8, 4)
  love.graphics.setColor(0.85, 0.95, 1.0, 0.9)
  love.graphics.polygon("fill", 10, -2, 14, 0, 10, 2)
  local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 12)
  love.graphics.setColor(0.55, 0.85, 1.0, 0.4 + pulso * 0.4)
  love.graphics.circle("line", 0, 0, 6 + pulso * 2)
  love.graphics.pop()
end

function Proyectil:dibujarFlechaPerforante()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  love.graphics.setColor(1, 0.85, 0.30, 0.3)
  love.graphics.rectangle("fill", -30, -4, 40, 8)
  love.graphics.setColor(0.90, 0.75, 0.30)
  love.graphics.rectangle("fill", -18, -2, 30, 4)
  love.graphics.setColor(1, 0.95, 0.55)
  love.graphics.polygon("fill", 12, -6, 24, 0, 12, 6)
  love.graphics.setColor(1, 1, 0.85, 0.9)
  love.graphics.polygon("fill", 14, -3, 21, 0, 14, 3)
  love.graphics.setColor(1, 0.85, 0.30, 0.5)
  love.graphics.circle("line", 0, 0, 8)
  love.graphics.pop()
end

function Proyectil:dibujarOrbeFuego()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 18)
  local pulso2 = 0.5 + 0.5 * math.sin(t * 10)

  love.graphics.setColor(1, 0.30, 0.05, 0.25 + pulso2 * 0.15)
  love.graphics.circle("fill", self.x, self.y, 14 * pulso)
  love.graphics.setColor(1, 0.50, 0.15, 0.40)
  love.graphics.circle("fill", self.x, self.y, 11 * pulso)
  love.graphics.setColor(1, 0.40, 0.10)
  love.graphics.circle("fill", self.x, self.y, 8 * pulso)
  love.graphics.setColor(1, 0.80, 0.30)
  love.graphics.circle("fill", self.x, self.y, 5 * pulso)
  love.graphics.setColor(1, 1, 0.90, 0.95)
  love.graphics.circle("fill", self.x, self.y, 2.5 * pulso)

  for i = 1, 3 do
    local ang = t * 6 + i * 2.1
    local r = 10 + math.sin(t * 8 + i) * 3
    love.graphics.setColor(1, 0.75, 0.25, 0.7)
    love.graphics.circle("fill", self.x + math.cos(ang) * r, self.y + math.sin(ang) * r, 1.5)
  end
end

function Proyectil:dibujarBolaSlime()
  local pulso = 0.85 + 0.15 * math.sin(love.timer.getTime() * 12)
  love.graphics.setColor(0.15, 0.55, 0.30, 0.7)
  love.graphics.circle("fill", self.x, self.y, 5 * pulso)
  love.graphics.setColor(0.35, 0.90, 0.55)
  love.graphics.circle("fill", self.x, self.y, 4 * pulso)
  love.graphics.setColor(0.85, 1.0, 0.90, 0.9)
  love.graphics.circle("fill", self.x - 1.5, self.y - 1.5, 1.5)
  love.graphics.setColor(0.20, 0.65, 0.35, 0.9)
  love.graphics.circle("line", self.x, self.y, 4.5 * pulso)
end

function Proyectil:dibujarFuego()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 15)
  love.graphics.setColor(1, 0.35, 0.10, 0.30)
  love.graphics.circle("fill", self.x - self.vx * 0.02, self.y - self.vy * 0.02, 8 * pulso)
  love.graphics.setColor(1, 0.55, 0.15, 0.40)
  love.graphics.circle("fill", self.x, self.y, 7 * pulso)
  love.graphics.setColor(1, 0.45, 0.10)
  love.graphics.circle("fill", self.x, self.y, 5 * pulso)
  love.graphics.setColor(1, 0.85, 0.35)
  love.graphics.circle("fill", self.x, self.y, 3 * pulso)
  love.graphics.setColor(1, 1, 0.90, 0.95)
  love.graphics.circle("fill", self.x, self.y, 1.4 * pulso)
end

function Proyectil:dibujarBolaOscura()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 12)

  love.graphics.setColor(0.30, 0.05, 0.45, 0.35)
  love.graphics.circle("fill", self.x, self.y, 11 * pulso)

  love.graphics.setColor(0.45, 0.10, 0.65)
  love.graphics.circle("fill", self.x, self.y, 7 * pulso)

  love.graphics.setColor(0.85, 0.35, 1.0)
  love.graphics.circle("fill", self.x, self.y, 4 * pulso)

  love.graphics.setColor(1, 0.75, 1.0, 0.95)
  love.graphics.circle("fill", self.x, self.y, 2 * pulso)

  for i = 1, 4 do
    local ang = t * 8 + i * (math.pi / 2)
    local dx = math.cos(ang) * 9
    local dy = math.sin(ang) * 9
    love.graphics.setColor(0.75, 0.30, 0.95, 0.8)
    love.graphics.circle("fill", self.x + dx, self.y + dy, 1.5)
  end

  love.graphics.setColor(0.60, 0.15, 0.85, 0.9)
  love.graphics.circle("line", self.x, self.y, 8 * pulso)
end

-- ============================================================
-- DIBUJOS DE BUMERANES
-- ============================================================
function Proyectil:dibujarBumeran(esRicochet)
  local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 15)

  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.circle("fill", self.x, self.y + 1.5, self.radio + 1)

  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.anguloRotacion)

  local velo = math.sqrt(self.vx * self.vx + self.vy * self.vy)
  if velo > 0.1 then
    local nx, ny = self.vx / velo, self.vy / velo
    for i = 1, 4 do
      local alpha = (1 - i / 5) * 0.35
      love.graphics.setColor(0.55, 0.30, 0.15, alpha)
      love.graphics.circle("fill", -nx * i * 4, -ny * i * 4, self.radio - i * 0.6)
    end
  end

  local colorA, colorB
  if esRicochet then
    colorA = {0.65, 0.20, 0.85}
    colorB = {0.90, 0.50, 1.00}
  else
    colorA = {0.20, 0.15, 0.12}
    colorB = {0.55, 0.35, 0.20}
  end

  love.graphics.setColor(colorA)
  love.graphics.polygon("fill", 0, -2, -12, -10, -10, -4, 0, 2)
  love.graphics.polygon("fill", 0, -2, -12, 10, -10, 4, 0, 2)

  love.graphics.setColor(colorB)
  love.graphics.polygon("fill", 0, -1, -10, -8, -9, -4, 0, 1)
  love.graphics.polygon("fill", 0, -1, -10, 8, -9, 4, 0, 1)

  love.graphics.setColor(0.85, 0.55, 0.25)
  love.graphics.circle("fill", 0, 0, 2.5)

  if esRicochet then
    love.graphics.setColor(0.85, 0.35, 1.0, 0.6 + pulso * 0.4)
    love.graphics.circle("fill", -12, -10, 2.5)
    love.graphics.circle("fill", -12, 10, 2.5)
  else
    love.graphics.setColor(1, 0.85, 0.40, 0.7 + pulso * 0.3)
    love.graphics.circle("fill", -12, -10, 2)
    love.graphics.circle("fill", -12, 10, 2)
  end

  love.graphics.pop()

  love.graphics.setBlendMode("add")
  if esRicochet then
    love.graphics.setColor(0.65, 0.30, 0.95, 0.15 + pulso * 0.10)
  else
    love.graphics.setColor(0.90, 0.60, 0.30, 0.15 + pulso * 0.10)
  end
  love.graphics.circle("fill", self.x, self.y, self.radio + 5)
  love.graphics.setBlendMode("alpha")
end

-- ============================================================
-- DIBUJOS DE BALAS
-- ============================================================
function Proyectil:dibujarBala()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  love.graphics.setColor(1, 0.85, 0.40, 0.35)
  love.graphics.rectangle("fill", -16, -1.5, 14, 3)
  love.graphics.setColor(1, 0.95, 0.60, 0.55)
  love.graphics.rectangle("fill", -10, -0.8, 8, 1.6)

  love.graphics.setColor(1, 0.90, 0.40)
  love.graphics.circle("fill", 0, 0, self.radio)

  love.graphics.setColor(1, 1, 0.85)
  love.graphics.circle("fill", 0, 0, self.radio * 0.55)

  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", -0.5, -0.5, self.radio * 0.25)

  love.graphics.pop()
end

function Proyectil:dibujarBalaPerforante()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.55, 0.85, 1.0, 0.25)
  love.graphics.circle("fill", 0, 0, self.radio + 6)
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(0.55, 0.85, 1.0, 0.5)
  love.graphics.rectangle("fill", -24, -1.5, 22, 3)

  love.graphics.setColor(0.40, 0.80, 1.0)
  love.graphics.circle("fill", 0, 0, self.radio)

  love.graphics.setColor(0.85, 0.95, 1.0)
  love.graphics.circle("fill", 0, 0, self.radio * 0.55)

  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", -0.5, -0.5, self.radio * 0.30)

  love.graphics.pop()
end

function Proyectil:dibujarBalaPlasma()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)

  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.30, 0.75, 1.0, 0.40)
  love.graphics.rectangle("fill", -22, -2, 20, 4)
  love.graphics.setColor(0.55, 0.90, 1.0, 0.60)
  love.graphics.rectangle("fill", -14, -1.2, 12, 2.4)
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(0.30, 0.75, 1.0)
  love.graphics.circle("fill", 0, 0, self.radio)
  love.graphics.setColor(0.75, 0.95, 1.0)
  love.graphics.circle("fill", 0, 0, self.radio * 0.6)
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", -0.5, -0.5, self.radio * 0.3)

  love.graphics.pop()

  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.55, 0.90, 1.0, 0.22)
  love.graphics.circle("fill", self.x, self.y, self.radio + 4)
  love.graphics.setBlendMode("alpha")
end

function Proyectil:dibujarNotaMusical()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)

  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 10)

  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.65, 0.30, 1.0, 0.30 + pulso * 0.15)
  love.graphics.circle("fill", 0, 0, self.radio + 6)
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(0.75, 0.50, 1.0, 0.35)
  love.graphics.rectangle("fill", -10, -1, 8, 2)
  love.graphics.rectangle("fill", -16, -1, 6, 2)
  love.graphics.rectangle("fill", -22, -1, 4, 2)

  love.graphics.setColor(0.80, 0.55, 1.0)
  love.graphics.circle("fill", 0, 0, self.radio)
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", 0, 0, self.radio * 0.55)

  love.graphics.setColor(0.80, 0.55, 1.0)
  love.graphics.rectangle("fill", self.radio - 1, -self.radio - 3, 1.5, self.radio + 3)

  love.graphics.setColor(0.85, 0.65, 1.0)
  love.graphics.arc("line", "open",
    self.radio, -self.radio - 1,
    3, -math.pi * 0.5, math.pi * 0.3)

  love.graphics.pop()

  for i = 1, 3 do
    local a = t * 6 + i * (math.pi * 2 / 3)
    local d = 8 + math.sin(t * 8 + i) * 2
    love.graphics.setColor(0.85, 0.65, 1.0, 0.7)
    love.graphics.circle("fill",
      self.x + math.cos(a) * d,
      self.y + math.sin(a) * d, 1.2)
  end
end

-- ============================================================
-- DIBUJOS DE LOS BIOMAS NUEVOS
-- ============================================================
function Proyectil:dibujarEspora()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 9 + self.x)
  love.graphics.setColor(0.60, 0.85, 0.20, 0.25)
  love.graphics.circle("fill", self.x, self.y, 9 * pulso)
  love.graphics.setColor(0.55, 0.78, 0.20)
  love.graphics.circle("fill", self.x, self.y, 5 * pulso)
  love.graphics.setColor(0.85, 0.95, 0.45)
  love.graphics.circle("fill", self.x - 1, self.y - 1, 2.5)
  love.graphics.setColor(0.35, 0.50, 0.12, 0.9)
  love.graphics.circle("line", self.x, self.y, 5.5 * pulso)
  love.graphics.setColor(0.90, 1.0, 0.60, 0.8)
  love.graphics.circle("fill",
    self.x + math.cos(t * 7) * 6,
    self.y + math.sin(t * 7) * 6, 1)
end

function Proyectil:dibujarBolaFuego()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 16)
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.setColor(1, 0.30, 0.05, 0.28)
  love.graphics.circle("fill",
    self.x - math.cos(ang) * 6,
    self.y - math.sin(ang) * 6,
    8 * pulso)
  love.graphics.setColor(1, 0.35, 0.08, 0.45)
  love.graphics.circle("fill", self.x, self.y, 9 * pulso)
  love.graphics.setColor(1, 0.50, 0.12)
  love.graphics.circle("fill", self.x, self.y, 6 * pulso)
  love.graphics.setColor(1, 0.85, 0.35)
  love.graphics.circle("fill", self.x, self.y, 3.5 * pulso)
  love.graphics.setColor(1, 1, 0.9, 0.95)
  love.graphics.circle("fill", self.x, self.y, 1.6)
end

function Proyectil:dibujarEsquirla()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)
  love.graphics.setColor(0.45, 0.75, 1.0, 0.25)
  love.graphics.polygon("fill", -12, 0, -2, -5, 10, 0, -2, 5)
  love.graphics.setColor(0.60, 0.85, 1.0)
  love.graphics.polygon("fill", -7, 0, -1, -3.2, 9, 0, -1, 3.2)
  love.graphics.setColor(0.95, 1.0, 1.0, 0.95)
  love.graphics.polygon("fill", -2, 0, 1, -1.6, 8, 0, 1, 1.6)
  love.graphics.pop()
end

function Proyectil:dibujarOrbeVacio()
  local t = love.timer.getTime()
  local pulso = 0.85 + 0.15 * math.sin(t * 11 + self.x * 0.1)
  love.graphics.setColor(0.40, 0.10, 0.65, 0.30)
  love.graphics.circle("fill", self.x, self.y, 13 * pulso)
  love.graphics.setColor(0.08, 0.02, 0.14)
  love.graphics.circle("fill", self.x, self.y, 7.5 * pulso)
  love.graphics.setColor(0.70, 0.30, 1.0, 0.9)
  love.graphics.setLineWidth(1.5)
  love.graphics.circle("line", self.x, self.y, 8 * pulso)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.90, 0.65, 1.0, 0.9)
  love.graphics.circle("fill",
    self.x + math.cos(t * 9) * 5,
    self.y + math.sin(t * 9) * 5, 1.4)
  love.graphics.circle("fill",
    self.x - math.cos(t * 9) * 5,
    self.y - math.sin(t * 9) * 5, 1.4)
end

function Proyectil:dibujarRoca()
  local t = love.timer.getTime()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(t * 5)
  love.graphics.setColor(0.25, 0.16, 0.14)
  love.graphics.polygon("fill", -7, -2, -3, -7, 4, -6, 7, 0, 3, 7, -4, 6)
  love.graphics.setColor(0.42, 0.28, 0.24)
  love.graphics.polygon("fill", -3, -7, 4, -6, 1, -1, -5, -2)
  love.graphics.setColor(1.0, 0.45, 0.10, 0.9)
  love.graphics.line(-2, 3, 1, 0, 4, 2)
  love.graphics.pop()
end

-- ============================================================
-- DIBUJOS DE JUGADORES NUEVOS
-- ============================================================
function Proyectil:dibujarDaga()
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)
  love.graphics.setColor(0.65, 0.40, 0.95, 0.30)
  love.graphics.polygon("fill", -14, 0, -4, -3, 2, 0, -4, 3)
  love.graphics.setColor(0.88, 0.90, 0.98)
  love.graphics.polygon("fill", -4, -1.6, 8, 0, -4, 1.6)
  love.graphics.setColor(0.35, 0.22, 0.45)
  love.graphics.rectangle("fill", -8, -1, 4, 2)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.line(-3, -0.5, 6, 0)
  love.graphics.pop()
end

function Proyectil:dibujarOndaSanta()
  local k = math.max(0, self.vida / 0.45)
  local ang = math.atan2(self.vy, self.vx)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(ang)
  love.graphics.setColor(1.0, 0.90, 0.45, 0.25 * k + 0.1)
  love.graphics.arc("fill", 0, 0, 14, -1.0, 1.0)
  love.graphics.setColor(1.0, 0.95, 0.65, 0.9 * k + 0.1)
  love.graphics.setLineWidth(3)
  love.graphics.arc("line", "open", 0, 0, 13, -1.0, 1.0)
  love.graphics.setLineWidth(1)
  love.graphics.pop()
end

return Proyectil