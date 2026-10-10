local Colisiones = require("src.sistemas.colisiones")

local Drop = {}
Drop.__index = Drop

local GRAVEDAD = 380
local RADIO_IMAN = 34
local VELOCIDAD_IMAN = 260

function Drop.nuevo()
  local d = setmetatable({}, Drop)
  d.x, d.y = 0, 0
  d.vx, d.vy = 0, 0
  d.z = 0            -- altura visual sobre el suelo
  d.vz = 0
  d.activo = false
  d.tipo = "moneda"  -- "moneda" | "gema"
  d.cantidad = 1     -- cuantas unidades vale este drop
  d.estado = "volando"  -- "volando" | "suelo" | "imantado"
  d.tiempoVida = 20  -- desaparece despues de 20s si no se recoge
  return d
end

function Drop:lanzar(x, y, tipo, cantidad)
  self.x, self.y = x, y
  self.vx = (math.random() - 0.5) * 60
  self.vy = (math.random() - 0.5) * 60
  self.z = 0
  self.vz = 90
  self.tipo = tipo or "moneda"
  self.cantidad = cantidad or 1
  self.estado = "volando"
  self.activo = true
  self.tiempoVida = 20
end

function Drop:actualizar(dt, jugador, mapa)
  if self.estado == "volando" or self.estado == "suelo" then
    -- Fisica vertical (rebote)
    self.vz = self.vz - GRAVEDAD * dt
    self.z = self.z + self.vz * dt
    if self.z <= 0 then
      self.z = 0
      self.vz = -self.vz * 0.35
      if math.abs(self.vz) < 20 then
        self.vz = 0
        self.estado = "suelo"
      end
    end

    -- Movimiento horizontal con friccion
    local nx = self.x + self.vx * dt
    if not Colisiones.circuloConMapa(nx, self.y, 3, mapa) then
      self.x = nx
    else
      self.vx = -self.vx * 0.4
    end
    local ny = self.y + self.vy * dt
    if not Colisiones.circuloConMapa(self.x, ny, 3, mapa) then
      self.y = ny
    else
      self.vy = -self.vy * 0.4
    end
    self.vx = self.vx * (1 - 3 * dt)
    self.vy = self.vy * (1 - 3 * dt)
  end

  if self.estado == "suelo" then
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local d2 = dx * dx + dy * dy
    if d2 < RADIO_IMAN * RADIO_IMAN then
      self.estado = "imantado"
    end
  end

  if self.estado == "imantado" then
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 1 then d = 1 end
    local vel = VELOCIDAD_IMAN * (1 + (RADIO_IMAN - d) / RADIO_IMAN)
    self.x = self.x + (dx / d) * vel * dt
    self.y = self.y + (dy / d) * vel * dt

    -- Inline del helper d2magnet (antes era una funcion global fragil)
    if dx * dx + dy * dy < 36 then
      return true  -- recogido
    end
  end

  self.tiempoVida = self.tiempoVida - dt
  if self.tiempoVida <= 0 then
    self.activo = false
    return "expirado"
  end

  return false
end

function Drop:dibujar()
  if not self.activo then return end
  local cy = self.y - self.z
  local sombra = 1 - (self.z / 30)
  if sombra < 0.3 then sombra = 0.3 end

  -- Sombra en el suelo
  love.graphics.setColor(0, 0, 0, 0.3 * sombra)
  love.graphics.ellipse("fill", self.x, self.y + 5, 4, 2)

  if self.tipo == "moneda" then
    love.graphics.setColor(0.95, 0.80, 0.20)
    love.graphics.circle("fill", self.x, cy, 4)
    love.graphics.setColor(1, 0.95, 0.55)
    love.graphics.circle("fill", self.x - 1, cy - 1, 2)
  else
    love.graphics.setColor(0.30, 0.90, 0.95)
    love.graphics.polygon("fill",
      self.x, cy - 4,
      self.x + 4, cy,
      self.x, cy + 4,
      self.x - 4, cy)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.polygon("line",
      self.x, cy - 4,
      self.x + 4, cy,
      self.x, cy + 4,
      self.x - 4, cy)
  end
end

return Drop