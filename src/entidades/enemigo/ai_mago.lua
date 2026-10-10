local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

function E:actualizarMagoOscuro(dt, mapa, objetivo)
  local datos = self.datos
  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end

  self.ultimaDirX, self.ultimaDirY = dx / d, dy / d

  if self:probarAtaqueEspecial(objetivo) then return end

  -- Cargando hechizo: quieto, sin moverse
  if self.cargando then
    self.cargaTimer = self.cargaTimer - dt
    if self.cargaTimer <= 0 then
      self.cargando = false
      self.quiereDisparar = true
      self.disparoDirX = dx / d
      self.disparoDirY = dy / d
      self.cooldownDisparo = datos.cooldownDisparo
    end
    return
  end

  -- Cooldown
  self.cooldownDisparo = self.cooldownDisparo - dt
  if self.cooldownDisparo <= 0 and d < datos.rangoDisparo then
    self.cargando = true
    self.cargaTimer = 0.8
    return
  end

  -- Strafe
  self.strafeTimer = self.strafeTimer - dt
  if self.strafeTimer <= 0 then
    self.strafeAngle = math.rad(math.random(0, 360))
    self.strafeTimer = 0.8 + math.random() * 0.7
  end

  -- Mantener distancia
  local movX, movY = 0, 0
  if d < datos.rangoMinimo then
    movX = -dx / d
    movY = -dy / d
  elseif d > datos.rangoIdeal + 40 then
    movX = dx / d
    movY = dy / d
  else
    movX = math.cos(self.strafeAngle)
    movY = math.sin(self.strafeAngle)
  end

  local vel = datos.velocidad
  local vx = movX * vel * dt
  local vy = movY * vel * dt
  local nx = self.x + vx
  if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
  local ny = self.y + vy
  if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
end

return E