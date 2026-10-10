local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

function E:actualizarArquero(dt, mapa, objetivo)
  local datos = self.datos
  local velMult = self.velocidadMultiplicador or 1

  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end
  self.ultimaDirX, self.ultimaDirY = dx / d, dy / d

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

  self.cooldownDisparo = self.cooldownDisparo - dt
  if self.cooldownDisparo <= 0 and d < datos.rangoDisparo then
    self.cooldownDisparo = datos.cooldownDisparo
    self.quiereDisparar = true

    local tiempoVuelo = d / datos.velocidadFlecha
    local factor = datos.factorPrediccion or 0.5
    local velJX = objetivo.velActualX or 0
    local velJY = objetivo.velActualY or 0
    local predX = objetivo.x + velJX * tiempoVuelo * factor
    local predY = objetivo.y + velJY * tiempoVuelo * factor
    local pdx = predX - self.x
    local pdy = predY - self.y
    local pm = math.sqrt(pdx * pdx + pdy * pdy)
    if pm < 0.001 then pm = 0.001 end
    local angulo = math.atan2(pdy, pdx)
    local disp = datos.dispersionGrados or 0
    if disp > 0 then
      local radMax = math.rad(disp / 2)
      angulo = angulo + (math.random() - 0.5) * 2 * radMax
    end
    self.disparoDirX = math.cos(angulo)
    self.disparoDirY = math.sin(angulo)
  end

  self.strafeTimer = self.strafeTimer - dt
  if self.strafeTimer <= 0 then
    self.strafeAngle = math.rad(math.random(0, 360))
    self.strafeTimer = 0.8 + math.random() * 0.7
  end

  local movX, movY = 0, 0
  if d < datos.rangoMinimo then
    movX = -dx / d
    movY = -dy / d
  elseif d > datos.rangoIdeal + 30 then
    movX = dx / d
    movY = dy / d
  else
    movX = math.cos(self.strafeAngle)
    movY = math.sin(self.strafeAngle)
  end

  local vel = datos.velocidad * velMult
  local vx = movX * vel * dt
  local vy = movY * vel * dt
  local nx = self.x + vx
  if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
  local ny = self.y + vy
  if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
end

return E