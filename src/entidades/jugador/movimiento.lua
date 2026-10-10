-- ============================================================
-- JUGADOR - Movimiento, dash, esquiva y regeneracion
-- ============================================================

local Colisiones = require("src.sistemas.colisiones")

local Movimiento = {}

-- ============================================================
-- ACTIVAR DASH (legacy, usado por Robin habilidad 1)
-- ============================================================

function Movimiento:activarDash(dirFrenteX, dirFrenteY)
  if self.estado == "dash" then return false end
  self.estado = "dash"
  self.rodando = false
  self.dashVel = nil
  self.dashTimer = 0.45
  self.dashDirX = -dirFrenteX
  self.dashDirY = -dirFrenteY
  self.invulnerable = math.max(self.invulnerable, 0.50)
  return true
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================

function Movimiento:actualizar(dt, dirX, dirY, mapa)
  -- Timers
  if self.invulnerable > 0 then self.invulnerable = self.invulnerable - dt end
  if self.buffVelocidad > 0 then self.buffVelocidad = self.buffVelocidad - dt end
  if self.slowTimer > 0 then self.slowTimer = self.slowTimer - dt end
  if self.cooldownDisparo > 0 then self.cooldownDisparo = self.cooldownDisparo - dt end
  if self.flashTimer > 0 then self.flashTimer = self.flashTimer - dt end
  if self.shakeTimer > 0 then self.shakeTimer = self.shakeTimer - dt end
  if self.comboTimer > 0 then self.comboTimer = self.comboTimer - dt end
  if self.swingT > 0 then self.swingT = self.swingT - dt end
  if self.sobrecargaT > 0 then self.sobrecargaT = self.sobrecargaT - dt end

  -- Buff de doble revolver (Coyote)
  if self.dualWield and self.dualWield > 0 then
    self.dualWield = self.dualWield - dt
    if self.dualWield < 0 then self.dualWield = 0 end
  end

  -- Sinfonia Belica (Lyra)
  if self.sinfoniaTimer and self.sinfoniaTimer > 0 then
    self.sinfoniaTimer = self.sinfoniaTimer - dt
    if self.sinfoniaTimer <= 0 then
      self.sinfoniaTimer = 0
      self.sinfoniaDano = 1
      self.sinfoniaVelocidad = 1
      self.sinfoniaCadencia = 1
    end
  end

  self.animTimer = self.animTimer + dt

  -- Regenerar escudo
  self.tiempoSinDano = self.tiempoSinDano + dt
  if self.tiempoSinDano > 5.0 and self.escudo < self.escudoMax then
    self.tiempoRegenEscudo = self.tiempoRegenEscudo + dt
    if self.tiempoRegenEscudo >= 2.5 then
      self.tiempoRegenEscudo = 0
      self.escudo = math.min(self.escudoMax, self.escudo + 1)
    end
  end

  -- ============================================================
  -- REGENERACION DE RECURSO
  -- ============================================================
  if self.recursoTipo == "balas" then
    -- Coyote: no regenera pasivamente. Solo recarga tras quedar vacio.
    if self.recargando then
      self.timerRecarga = self.timerRecarga - dt
      if self.timerRecarga <= 0 then
        self.recurso = self.recursoMax
        self.recargando = false
        self.timerRecarga = 0
      end
    end
  else
    self.tiempoDesdeAtaque = self.tiempoDesdeAtaque + dt
    if self.tiempoDesdeAtaque >= self.retrasoRegen then
      self.recurso = math.min(self.recursoMax,
        self.recurso + self.regenRecurso * dt)
    end
  end

  -- Orbes (Merlin)
  if self.orbsActivos and self.orbsTimer then
    self.orbsTimer = self.orbsTimer - dt
    if self.personaje and self.personaje.habVelOrbita then
      self.orbsAngulo = self.orbsAngulo + self.personaje.habVelOrbita * dt
    else
      self.orbsAngulo = self.orbsAngulo + 4.5 * dt
    end
    if self.orbsTimer <= 0 then
      self.orbsActivos = false
      self.orbs = {}
    end
  end

  if self.comboTimer <= 0 then
    self.comboPaso = 1
  end

  local evento = nil

  -- ============================================================
  -- ESTADO DASH / ESQUIVA
  -- ============================================================
  if self.estado == "dash" then
    self.caminando = false
    local vel = self.dashVel or 290
    self.velActualX = self.dashDirX * vel
    self.velActualY = self.dashDirY * vel

    local vx = self.dashDirX * vel * dt
    local vy = self.dashDirY * vel * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

    self.dashTimer = self.dashTimer - dt
    if self.dashTimer <= 0 then
      self.estado = "normal"
      if self.rodando then
        self.rodando = false
        self.dashVel = nil
        evento = "rodarFin"
      else
        evento = "dashFin"
      end
    end
  else
    -- ============================================================
    -- MOVIMIENTO NORMAL
    -- ============================================================
    local m = math.sqrt(dirX * dirX + dirY * dirY)
    if m > 1 then dirX, dirY = dirX / m, dirY / m end
    if m > 0.01 then
      self.ultimaDirX, self.ultimaDirY = dirX / m, dirY / m
    end

    self.caminando = m > 0.1

    local velMult = 1.0
    if self.buffVelocidad > 0 and self.personaje and self.personaje.habBuffVelocidad then
      velMult = velMult * self.personaje.habBuffVelocidad
    end
    -- Sinfonia Belica (Lyra)
    if self.sinfoniaTimer and self.sinfoniaTimer > 0 and self.sinfoniaVelocidad then
      velMult = velMult * self.sinfoniaVelocidad
    end
    if self.slowTimer > 0 then velMult = velMult * 0.80 end

    local vel = self.velocidad * velMult
    local vx = dirX * vel * dt
    local vy = dirY * vel * dt

    self.velActualX = dirX * vel
    self.velActualY = dirY * vel

    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
  end

  return evento
end

return Movimiento