local Colisiones    = require("src.sistemas.colisiones")
local datosEnemigos = require("src.datos.enemigos")
local Juice         = require("src.sistemas.juice")
local Sangre        = require("src.sistemas.sangre")

local E = {}
E.__index = E

-- ============ CONSTRUCTORES ============

function E.nuevoSlime(x, y)
  local datos = datosEnemigos.slime_pequeno
  local e = setmetatable({}, E)
  e.tipo = "slime_pequeno"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.estado = "esperando"
  e.timer = math.random() * (datos.esperaMax - datos.esperaMin) + datos.esperaMin
  e.dirX, e.dirY = 0, 0
  e.saltoProgreso = 0
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.animTimer = math.random() * 10
  e:initStatus()
  return e
end

function E.nuevoEsqueleto(x, y)
  local datos = datosEnemigos.esqueleto_guardia
  local e = setmetatable({}, E)
  e.tipo = "esqueleto_guardia"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.estado = "persiguiendo"
  e.timer = 0
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.strafeAngle = 0
  e.strafeTimer = 0
  e.dodgeTimer = 0
  e.dodgeCooldown = 0
  e.dodgeDirX, e.dodgeDirY = 0, 0
  e.yaGolpeo = false
  e.animTimer = math.random() * 10
  e:initStatus()
  return e
end

function E.nuevoEsqueletoArquero(x, y)
  local datos = datosEnemigos.esqueleto_arquero
  local e = setmetatable({}, E)
  e.tipo = "esqueleto_arquero"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.cooldownDisparo = 0.6 + math.random() * 0.5
  e.strafeAngle = 0
  e.strafeTimer = 0
  e.quiereDisparar = false
  e.disparoDirX, e.disparoDirY = 0, 0
  e.animTimer = math.random() * 10
  e:initStatus()
  return e
end

function E.nuevoRata(x, y)
  local datos = datosEnemigos.rata_gigante
  local e = setmetatable({}, E)
  e.tipo = "rata_gigante"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.animTimer = math.random() * 10
  e.zigzagTimer = 0
  e.zigzagSigno = (math.random() > 0.5) and 1 or -1
  e:initStatus()
  return e
end

function E.nuevoMurcielago(x, y)
  local datos = datosEnemigos.murcielago
  local e = setmetatable({}, E)
  e.tipo = "murcielago"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.animTimer = math.random() * 10
  e.wanderOffsetX = 0
  e.wanderOffsetY = 0
  e.wanderTimer = 0
  e.z = 0
  e.zTimer = 0
  e:initStatus()
  return e
end

function E.nuevoMagoOscuro(x, y)
  local datos = datosEnemigos.mago_oscuro
  local e = setmetatable({}, E)
  e.tipo = "mago_oscuro"
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.cooldownDisparo = 1.5 + math.random() * 0.5
  e.strafeAngle = 0
  e.strafeTimer = 0
  e.quiereDisparar = false
  e.disparoDirX, e.disparoDirY = 0, 0
  e.cargando = false
  e.cargaTimer = 0
  e.animTimer = math.random() * 10
  e:initStatus()
  return e
end

-- ============ ESTADOS INICIALES ============

function E:initStatus()
  -- Estados alterados
  self.quemaduraTimer = 0
  self.quemaduraTick = 0
  self.quemaduraFlash = 0
  self.stunTimer = 0
  self.slowTimer = 0
  self.factorSlow = 1

  -- Orbes de Merlin
  self.orbeCooldown = 0

  -- Knockback
  self.knockbackVX = 0
  self.knockbackVY = 0
  self.knockbackTimer = 0

  -- Anti-atasco
  self.antiStuckTimer = 0
  self.antiStuckDirX = 0
  self.antiStuckDirY = 0
  self.ultimaPosX = self.x
  self.ultimaPosY = self.y
  self.stuckCheckTimer = 0
  self.tipoAtaque = "corte"

  -- Danio de contacto dinamico (los arquetipos nuevos lo overridean)
  self.contactoDano = nil

  -- Intangibilidad (blink de los nuevos)
  self.intangible = false

  -- Reduccion de danio (guardia del caballero, jefes, etc.)
  self.reduccionDanio = 0

  -- Elite
  self.esElite = false
  self.habEspecial = nil
  self.habCooldown = 0
  self.habTimer = 0
  self.habEstado = "listo"
  self.habExtraData = {}
  self.ondaSonica = nil
  self.dashRata = nil

  -- Multiplicadores (por defecto sin elite)
  self.danoMultiplicador = 1
  self.velocidadMultiplicador = 1
  self.monedasMultiplicador = 1

  -- Marca del Cazador (Kael)
  self.marcadoTimer = 0
  self.marcadoMultiplicador = nil

  -- Enemigos nuevos: cola de disparos pendientes
  self.disparos = {}
end

-- ============ APLICAR EFECTOS ============

function E:aplicarQuemadura(duracion)
  self.quemaduraTimer = math.max(self.quemaduraTimer, duracion or 5.0)
end

function E:aplicarStun(duracion)
  self.stunTimer = math.max(self.stunTimer, duracion or 5.0)
end

function E:aplicarSlow(duracion, factor)
  if not self.slowTimer then self.slowTimer = 0 end
  if not self.factorSlow then self.factorSlow = 1 end
  self.slowTimer = math.max(self.slowTimer, duracion or 2.0)
  self.factorSlow = math.min(self.factorSlow, factor or 0.5)
end

function E:aplicarKnockback(dirX, dirY, fuerza)
  if self.esElite then
    fuerza = fuerza * 0.5
  end
  self.knockbackVX = dirX * fuerza
  self.knockbackVY = dirY * fuerza
  self.knockbackTimer = 0.25
end

-- ============ HACER ELITE ============

function E:hacerElite()
  if self.esElite then return end
  local elite = datosEnemigos.elite

  self.esElite = true
  self.hpMax = math.floor(self.hpMax * elite.hpMultiplicador)
  self.hp = self.hpMax
  self.radio = self.radio * elite.radioMultiplicador
  self.danoMultiplicador = elite.danoMultiplicador
  self.velocidadMultiplicador = elite.velocidadMultiplicador
  self.monedasMultiplicador = elite.monedasMultiplicador

  -- OJO: no tocamos self.datos.velocidad porque es una tabla compartida.

  -- Ataque especial segun tipo (los clasicos)
  if self.tipo == "slime_pequeno" then
    self.habEspecial = "salto_triple"
    self.habCooldown = 3.0
  elseif self.tipo == "esqueleto_guardia" then
    self.habEspecial = "estocada_cargada"
    self.habCooldown = 4.0
  elseif self.tipo == "esqueleto_arquero" then
    self.habEspecial = "abanico_flechas"
    self.habCooldown = 3.5
  elseif self.tipo == "rata_gigante" then
    self.habEspecial = "dash_aturdidor"
    self.habCooldown = 5.0
  elseif self.tipo == "murcielago" then
    self.habEspecial = "onda_sonica"
    self.habCooldown = 4.5
  elseif self.tipo == "mago_oscuro" then
    self.habEspecial = "lluvia_bolas"
    self.habCooldown = 5.0
  end
end

-- ============ UPDATE PRINCIPAL ============

function E:actualizar(dt, mapa, objetivo, flechasJugador)
  if not self.vivo then return end
  if self.flashDanio > 0 then self.flashDanio = self.flashDanio - dt end
  self.animTimer = self.animTimer + dt

  -- Slow (Anclaje Gravimetrico de Nyx-7 y otras fuentes)
  if self.slowTimer and self.slowTimer > 0 then
    self.slowTimer = self.slowTimer - dt
    dt = dt * (self.factorSlow or 1)
    if self.slowTimer <= 0 then
      self.factorSlow = 1
    end
  end

  -- Quemadura
  if self.quemaduraTimer > 0 then
    self.quemaduraTimer = self.quemaduraTimer - dt
    self.quemaduraTick = self.quemaduraTick + dt
    self.quemaduraFlash = self.quemaduraFlash + dt
    if self.quemaduraTick >= 1.0 then
      self.quemaduraTick = 0
      local murio = self:recibirDanio(1)
      if murio then return end
    end
  end

  -- Marca del Cazador (Kael)
  if self.marcadoTimer and self.marcadoTimer > 0 then
    self.marcadoTimer = self.marcadoTimer - dt
    if self.marcadoTimer <= 0 then
      self.marcadoTimer = 0
      self.marcadoMultiplicador = nil
    end
  end

  if self.orbeCooldown > 0 then self.orbeCooldown = self.orbeCooldown - dt end

  -- Knockback
  if self.knockbackTimer > 0 then
    self.knockbackTimer = self.knockbackTimer - dt
    local vx = self.knockbackVX * dt
    local vy = self.knockbackVY * dt
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then
      self.x = nx
    else
      self.knockbackVX = 0
    end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then
      self.y = ny
    else
      self.knockbackVY = 0
    end
    self.knockbackVX = self.knockbackVX * (1 - 8 * dt)
    self.knockbackVY = self.knockbackVY * (1 - 8 * dt)
  end

  -- Stun
  if self.stunTimer > 0 then
    self.stunTimer = self.stunTimer - dt
    return
  end

  -- Cooldown ataque especial
  if self.habCooldown > 0 then
    self.habCooldown = self.habCooldown - dt
  end

  -- Onda sonica (murcielago elite)
  if self.ondaSonica then
    self.ondaSonica.timer = self.ondaSonica.timer + dt
    self.ondaSonica.radio = self.ondaSonica.timer * 220
    local dx = objetivo.x - self.ondaSonica.x
    local dy = objetivo.y - self.ondaSonica.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > self.ondaSonica.radio - 12 and d < self.ondaSonica.radio + 12 then
      if not self.ondaSonica.hitPlayer then
        objetivo:recibirDanio(1)
        self.ondaSonica.hitPlayer = true
      end
    end
    if self.ondaSonica.timer > 1.5 then
      self.ondaSonica = nil
    end
  end

  -- Ataque especial activo (windup o activo)
  if self.habEstado == "windup" or self.habEstado == "activo" then
    self:actualizarAtaqueEspecial(dt, mapa, objetivo)
    return
  end

  -- Anti-atasco (no aplica a murcielago que atraviesa paredes)
  if self.tipo ~= "murcielago" then
    self.stuckCheckTimer = self.stuckCheckTimer + dt
    if self.stuckCheckTimer > 0.35 then
      local moved = math.abs(self.x - self.ultimaPosX) + math.abs(self.y - self.ultimaPosY)
      if moved < 3 then
        self.antiStuckTimer = 0.4
        local dx = objetivo.x - self.x
        local dy = objetivo.y - self.y
        local m = math.sqrt(dx * dx + dy * dy)
        if m > 0.001 then
          local side = (math.random() > 0.5) and 1 or -1
          self.antiStuckDirX = -dy / m * side
          self.antiStuckDirY = dx / m * side
        end
      end
      self.ultimaPosX = self.x
      self.ultimaPosY = self.y
      self.stuckCheckTimer = 0
    end
  end

  -- Despachar IA segun tipo (clasicos)
  if self.tipo == "slime_pequeno" then
    self:actualizarSlime(dt, mapa, objetivo)
  elseif self.tipo == "esqueleto_guardia" then
    self:actualizarEsqueleto(dt, mapa, objetivo, flechasJugador)
  elseif self.tipo == "esqueleto_arquero" then
    self:actualizarArquero(dt, mapa, objetivo)
  elseif self.tipo == "rata_gigante" then
    self:actualizarRata(dt, mapa, objetivo)
  elseif self.tipo == "murcielago" then
    self:actualizarMurcielago(dt, mapa, objetivo)
  elseif self.tipo == "mago_oscuro" then
    self:actualizarMagoOscuro(dt, mapa, objetivo)
  elseif self.datos.arquetipo and E.registroIA and E.registroIA[self.datos.arquetipo] then
    -- Enemigos nuevos de los biomas
    E.registroIA[self.datos.arquetipo](self, dt, mapa, objetivo)
  end
end

-- ============ DANIO ============

function E:recibirDanio(cantidad)
  if not self.vivo then return false end
  if self.intangible then return false end

  if self.reduccionDanio and self.reduccionDanio > 0 then
    cantidad = cantidad * (1 - self.reduccionDanio)
  end

  self.hp = self.hp - cantidad
  self.flashDanio = 0.12
  Juice.registrarDanio(self, cantidad)

  if self.hp <= 0 then
    self.vivo = false
    Juice.chispas(self.x, self.y, 9, {1.0, 0.92, 0.70}, 95, 0.45)
    Juice.golpe(0.035)
    pcall(Sangre.muerte, self, self.esElite and 1.4 or 1)
    return true
  end
  pcall(Sangre.herida, self, cantidad)
  return false
end

return E