local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

function E:actualizarRata(dt, mapa, objetivo)
  local datos = self.datos
  local velMult = self.velocidadMultiplicador or 1

  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end

  if self:probarAtaqueEspecial(objetivo) then return end

  -- Anti-atasco
  if self.antiStuckTimer > 0 then
    self.antiStuckTimer = self.antiStuckTimer - dt
    local vel = datos.velocidad * 1.5 * velMult
    local vx = self.antiStuckDirX * vel * dt
    local vy = self.antiStuckDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    return
  end

  self.ultimaDirX, self.ultimaDirY = dx / d, dy / d

  -- Zigzag: cambia de signo periodicamente
  self.zigzagTimer = self.zigzagTimer - dt
  if self.zigzagTimer <= 0 then
    self.zigzagTimer = 0.4 + math.random() * 0.4
    self.zigzagSigno = -self.zigzagSigno
  end

  local anguloBase = math.atan2(dy, dx)
  local anguloFinal = anguloBase + self.zigzagSigno * math.rad(20)

  local mx = math.cos(anguloFinal)
  local my = math.sin(anguloFinal)
  local vel = datos.velocidad * velMult

  local vx = mx * vel * dt
  local vy = my * vel * dt
  local nx = self.x + vx
  if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
  local ny = self.y + vy
  if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
end

return E