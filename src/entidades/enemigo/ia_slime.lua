local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

function E:actualizarSlime(dt, mapa, objetivo)
  local datos = self.datos

  if self:probarAtaqueEspecial(objetivo) then return end

  -- Anti-atasco (por si un slime queda pegado contra un pilar)
  if self.antiStuckTimer > 0 then
    self.antiStuckTimer = self.antiStuckTimer - dt
    local vel = datos.velocidad * 1.5 * (self.velocidadMultiplicador or 1)
    local vx = self.antiStuckDirX * vel * dt
    local vy = self.antiStuckDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    return
  end

  if self.estado == "esperando" then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local dx = objetivo.x - self.x
      local dy = objetivo.y - self.y
      local m = math.sqrt(dx * dx + dy * dy)
      if m > 0.001 then
        self.dirX, self.dirY = dx / m, dy / m
      else
        self.dirX, self.dirY = 0, 0
      end
      self.estado = "saltando"
      self.timer = datos.duracionSalto
      self.saltoProgreso = 0
    end

  elseif self.estado == "saltando" then
    self.timer = self.timer - dt
    self.saltoProgreso = 1 - (self.timer / datos.duracionSalto)
    local vel = datos.velocidad * (self.velocidadMultiplicador or 1)
    local vx = self.dirX * vel * dt
    local vy = self.dirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    if self.timer <= 0 then
      self.estado = "esperando"
      self.timer = math.random() * (datos.esperaMax - datos.esperaMin) + datos.esperaMin
      self.saltoProgreso = 0
    end
  end
end

return E