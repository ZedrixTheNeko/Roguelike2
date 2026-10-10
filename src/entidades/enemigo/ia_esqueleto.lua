local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

function E:actualizarEsqueleto(dt, mapa, objetivo, flechasJugador)
  local datos = self.datos
  local velMult = self.velocidadMultiplicador or 1
  local danoMult = self.danoMultiplicador or 1

  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end

  if self:probarAtaqueEspecial(objetivo) then return end

  if self.dodgeCooldown > 0 then self.dodgeCooldown = self.dodgeCooldown - dt end

  -- Esquivar flechas
  self.dodgeTimer = self.dodgeTimer - dt
  if self.dodgeTimer <= 0 and self.dodgeCooldown <= 0 and flechasJugador then
    for i = 1, #flechasJugador do
      local p = flechasJugador[i]
      local px, py = p.x - self.x, p.y - self.y
      local pd = math.sqrt(px * px + py * py)
      if pd > 4 and pd < 40 then
        local pvx, pvy = p.vx, p.vy
        local pvm = math.sqrt(pvx * pvx + pvy * pvy)
        if pvm > 0.01 then pvx, pvy = pvx / pvm, pvy / pvm end
        local hmx, hmy = (self.x - p.x) / pd, (self.y - p.y) / pd
        local dot = pvx * hmx + pvy * hmy
        if dot > 0.96 then
          local side = (math.random() > 0.5) and 1 or -1
          self.dodgeDirX = -pvy * side
          self.dodgeDirY =  pvx * side
          self.dodgeTimer = 0.18
          self.dodgeCooldown = 0.9
          break
        end
      end
    end
  end

  if self.dodgeTimer > 0 then
    local vel = datos.velocidad * 2.0 * velMult
    local vx = self.dodgeDirX * vel * dt
    local vy = self.dodgeDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    return
  end

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

  if self.estado == "persiguiendo" then
    if d > 0.001 then
      self.ultimaDirX, self.ultimaDirY = dx / d, dy / d
    end

    if d < datos.rangoCorte then
      self.estado = "windup_corte"
      self.timer = datos.windupCorte
      self.yaGolpeo = false
    elseif d < datos.rangoEstocada then
      self.estado = "windup_estocada"
      self.timer = datos.windupEstocada
      self.yaGolpeo = false
    else
      self.strafeTimer = self.strafeTimer - dt
      if self.strafeTimer <= 0 then
        self.strafeAngle = math.rad(math.random(-25, 25))
        self.strafeTimer = 0.9 + math.random() * 1.0
      end
      local ang = math.atan2(dy, dx)
      local anguloFinal = ang
      if d > datos.rangoEstocada * 1.5 then
        anguloFinal = ang + self.strafeAngle
      end
      local mx, my = math.cos(anguloFinal), math.sin(anguloFinal)
      local vel = datos.velocidad * velMult
      local vx = mx * vel * dt
      local vy = my * vel * dt
      local nx = self.x + vx
      if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
      local ny = self.y + vy
      if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    end

  elseif self.estado == "windup_corte" then
    local vel = -15 * velMult
    local vx = self.ultimaDirX * vel * dt
    local vy = self.ultimaDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "atacando_corte"
      self.timer = datos.duracionCorte
      local adx = objetivo.x - self.x
      local ady = objetivo.y - self.y
      local am = math.sqrt(adx * adx + ady * ady)
      if am > 0.001 then
        self.ultimaDirX, self.ultimaDirY = adx / am, ady / am
      end
    end

  elseif self.estado == "atacando_corte" then
    local vel = 30 * velMult
    local vx = self.ultimaDirX * vel * dt
    local vy = self.ultimaDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

    if not self.yaGolpeo then
      self.yaGolpeo = true
      local gdx = objetivo.x - self.x
      local gdy = objetivo.y - self.y
      local gd = math.sqrt(gdx * gdx + gdy * gdy)
      if gd < datos.rangoGolpeCorte + objetivo.radio then
        local angE = math.atan2(gdy, gdx)
        local angBase = math.atan2(self.ultimaDirY, self.ultimaDirX)
        local dif = math.abs(((angE - angBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < math.rad(50) then
          local dano = datos.danoAtaque * danoMult
          objetivo:recibirDanio(dano)
        end
      end
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "cooldown"
      self.timer = datos.cooldownAtaque
    end

  elseif self.estado == "windup_estocada" then
    local vel = -35 * velMult
    local vx = self.ultimaDirX * vel * dt
    local vy = self.ultimaDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "atacando_estocada"
      self.timer = datos.duracionEstocada
      local adx = objetivo.x - self.x
      local ady = objetivo.y - self.y
      local am = math.sqrt(adx * adx + ady * ady)
      if am > 0.001 then
        self.ultimaDirX, self.ultimaDirY = adx / am, ady / am
      end
    end

  elseif self.estado == "atacando_estocada" then
    local vel = 220 * velMult
    local vx = self.ultimaDirX * vel * dt
    local vy = self.ultimaDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

    if not self.yaGolpeo then
      self.yaGolpeo = true
      local gdx = objetivo.x - self.x
      local gdy = objetivo.y - self.y
      local gd = math.sqrt(gdx * gdx + gdy * gdy)
      if gd < datos.rangoGolpeEstocada + objetivo.radio then
        local angE = math.atan2(gdy, gdx)
        local angBase = math.atan2(self.ultimaDirY, self.ultimaDirX)
        local dif = math.abs(((angE - angBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < math.rad(30) then
          local dano = datos.danoAtaque * danoMult
          objetivo:recibirDanio(dano)
        end
      end
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "cooldown"
      self.timer = datos.cooldownAtaque
    end

  elseif self.estado == "cooldown" then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "persiguiendo"
    end
  end
end

return E