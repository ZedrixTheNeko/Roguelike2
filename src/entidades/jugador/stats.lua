-- ============================================================
-- JUGADOR - Stats, vida y recursos
-- ============================================================

local Personajes = require("src.datos.personajes")
local Progreso   = require("src.datos.progreso")

local Stats = {}

-- ============================================================
-- CLONAR PERSONAJE (para no mutar el modulo compartido)
-- ============================================================

local function clonarPersonaje(p)
  local habilidadesClonadas = {}
  for i, h in ipairs(p.habilidades or {}) do
    local copia = {}
    for k, v in pairs(h) do copia[k] = v end
    habilidadesClonadas[i] = copia
  end

  return {
    id              = p.id,
    nombre          = p.nombre,
    tipo            = p.tipo,
    arma            = p.arma,
    desc1           = p.desc1,
    desc2           = p.desc2,
    colorTunica     = {p.colorTunica[1], p.colorTunica[2], p.colorTunica[3]},
    colorCapa       = {p.colorCapa[1], p.colorCapa[2], p.colorCapa[3]},
    colorPelo       = {p.colorPelo[1], p.colorPelo[2], p.colorPelo[3]},
    colorPiel       = {p.colorPiel[1], p.colorPiel[2], p.colorPiel[3]},
    tipoArma        = p.tipoArma,
    hpMax           = p.hpMax,
    escudoMax       = p.escudoMax,
    velocidad       = p.velocidad,
    recursoTipo     = p.recursoTipo,
    recursoMax      = p.recursoMax,
    regenRecurso    = p.regenRecurso,
    retrasoRegen    = p.retrasoRegen,
    costeAtaque     = p.costeAtaque,
    danoAtaque      = p.danoAtaque,
    cooldownAtaque  = p.cooldownAtaque,
    rangoMelee      = p.rangoMelee,
    danoArrojado    = p.danoArrojado,
    habBuffVelocidad = p.habBuffVelocidad,
    habVelOrbita    = p.habVelOrbita,
    habilidades     = habilidadesClonadas,
  }
end

-- ============================================================
-- APLICAR PERSONAJE
-- ============================================================

function Stats:aplicarPersonaje()
  local p = Personajes.actualData()

  self.personaje = clonarPersonaje(p)

  self.colorTunica = {self.personaje.colorTunica[1], self.personaje.colorTunica[2], self.personaje.colorTunica[3]}
  self.colorCapa   = {self.personaje.colorCapa[1], self.personaje.colorCapa[2], self.personaje.colorCapa[3]}
  self.colorPelo   = {self.personaje.colorPelo[1], self.personaje.colorPelo[2], self.personaje.colorPelo[3]}
  self.colorPiel   = {self.personaje.colorPiel[1], self.personaje.colorPiel[2], self.personaje.colorPiel[3]}
  self.tipoArma    = self.personaje.tipoArma

  self.hpMax       = self.personaje.hpMax
  self.escudoMax   = self.personaje.escudoMax
  self.velocidad   = self.personaje.velocidad
  self.recursoTipo = self.personaje.recursoTipo
  self.recursoMax  = self.personaje.recursoMax
  self.regenRecurso = self.personaje.regenRecurso
  self.retrasoRegen = self.personaje.retrasoRegen

  self.costeAtaque    = self.personaje.costeAtaque
  self.danoAtaque     = self.personaje.danoAtaque
  self.cooldownAtaque = self.personaje.cooldownAtaque
  self.cooldownDisparoMax = self.personaje.cooldownAtaque

  -- Reset de estados temporales
  self.estado = "normal"
  self.invulnerable = 0
  self.buffVelocidad = 0
  self.slowTimer = 0
  self.cooldownDisparo = 0
  self.dashTimer = 0
  self.flashTimer = 0
  self.shakeTimer = 0
  self.orbsActivos = false
  self.orbsTimer = 0
  self.orbs = {}
  self.comboPaso = 1
  self.comboTimer = 0

  -- Buff de doble revolver (Coyote)
  self.dualWield = 0

  -- Sinfonia Belica (Lyra)
  self.sinfoniaTimer = 0
  self.sinfoniaDano = 1
  self.sinfoniaVelocidad = 1
  self.sinfoniaCadencia = 1

  -- Dron Centinela (Nyx-7)
  self.dron = nil

  -- Sistema de balas (Coyote)
  self.recargando = false
  self.timerRecarga = 0
  self.duracionRecarga = 1.6

  -- Roll / frascos / parry / sobrecarga
  self.rodando = false
  self.dashVel = nil
  self.parryActivo = false
  self.parryExito = false
  self.swingT = 0
  self.swingDur = 0.18
  self.swingLado = 1
  self.sobrecargaT = 0
  self.frascos = 2
  self.frascosMax = 3

  Progreso.aplicarAlJugador(self)

  if self.hp > self.hpMax then self.hp = self.hpMax end
  if self.escudo > self.escudoMax then self.escudo = self.escudoMax end

  if self.recursoTipo == "balas" then
    self.recurso = self.recursoMax
    self.recargando = false
    self.timerRecarga = 0
  else
    if self.recurso > self.recursoMax then self.recurso = self.recursoMax end
  end
end

-- ============================================================
-- VIDA
-- ============================================================

function Stats:subirVidaMaxima(cantidad)
  self.hpMax = self.hpMax + cantidad
  self.hp = self.hp + cantidad
end

function Stats:resetearVida()
  self.hp = self.hpMax
  self.escudo = self.escudoMax
  self.tiempoSinDano = 0
  self.tiempoRegenEscudo = 0
  self.tiempoDesdeAtaque = 999

  self.recurso = self.recursoMax
  self.recargando = false
  self.timerRecarga = 0
end

-- ============================================================
-- RECIBIR DANO
-- ============================================================

function Stats:recibirDanio(cantidad)
  if self.invulnerable > 0 then return false end
  if not self.vivo then return false end

  if self.parryActivo then
    self.parryExito = true
    return false
  end

  self.tiempoSinDano = 0
  self.tiempoRegenEscudo = 0

  if self.escudo > 0 then
    local absorbido = math.min(self.escudo, cantidad)
    self.escudo = self.escudo - absorbido
    cantidad = cantidad - absorbido

    self.flashTimer = 0.20
    self.flashColor = {0.45, 0.85, 1.0}
    self.shakeTimer = 0.10
    self.shakeMag = 1.5

    if cantidad <= 0 then
      self.invulnerable = 0.45
      return "escudo"
    end
  end

  self.hp = math.max(0, self.hp - cantidad)
  self.invulnerable = 0.70
  self.flashTimer = 0.25
  self.flashColor = {1.0, 0.35, 0.35}
  self.shakeTimer = 0.15
  self.shakeMag = 3

  -- Shader: pulso rojo en los bordes + aberracion cromatica (seguro: pcall)
  pcall(function()
    local Shaders = require("src.utils.shaders")
    require("src.sistemas.sangre").herida(self, cantidad * 1.5, "jugador")
    Shaders.dano(0.7)
    Shaders.golpe(0.0025)
  end)

  if self.hp <= 0 then
    self.vivo = false
    return true
  end
  return true
end

-- ============================================================
-- RECURSOS
-- ============================================================

function Stats:gastarResistencia(cantidad)
  self.recurso = math.max(0, self.recurso - cantidad)
  self.tiempoDesdeAtaque = 0

  if self.recursoTipo == "balas" and self.recurso <= 0 and not self.recargando then
    self.recargando = true
    self.timerRecarga = self.duracionRecarga
  end
end

function Stats:puedeDisparar()
  if self.recursoTipo == "balas" and self.recargando then return false end
  return self.cooldownDisparo <= 0 and self.estado == "normal" and self.vivo
end

-- ============================================================
-- ACCIONES (roll, frascos)
-- ============================================================

-- Esquiva: roll en la direccion del joystick de movimiento.
-- Si no hay input de movimiento, rueda HACIA DONDE APUNTA.
-- (Antes iba al reves: ese era el bug de "rueda para atras".)
function Stats:rodar(dx, dy)
  if self.estado ~= "normal" or not self.vivo then return false end
  local coste = math.max(14, self.recursoMax * 0.16)
  if self.recurso < coste then return false end

  local m = math.sqrt(dx * dx + dy * dy)
  if m < 0.01 then
    -- Sin joystick: roll en la direccion de apuntado (ultimaDir).
    -- Antes tenia "-self.ultimaDirX" y por eso rodaba hacia atras.
    dx, dy = self.ultimaDirX, self.ultimaDirY
    m = math.sqrt(dx * dx + dy * dy)
    if m < 0.01 then
      dx, dy = 1, 0
      m = 1
    end
  end
  dx, dy = dx / m, dy / m

  self.recurso = self.recurso - coste
  self.tiempoDesdeAtaque = 0
  self.estado = "dash"
  self.rodando = true
  self.dashTimer = 0.30
  self.dashDirX, self.dashDirY = dx, dy
  self.dashVel = 255
  self.rodarSigno = (dx >= 0) and 1 or -1
  self.invulnerable = math.max(self.invulnerable, 0.34)
  return true
end

function Stats:beber()
  if not self.vivo or self.frascos <= 0 or self.hp >= self.hpMax then return false end
  self.frascos = self.frascos - 1
  local cura = math.max(2, math.ceil(self.hpMax * 0.4))
  self.hp = math.min(self.hpMax, self.hp + cura)
  self.flashTimer = 0.25
  self.flashColor = {0.50, 1.0, 0.55}
  self.slowTimer = math.max(self.slowTimer, 0.5)
  return true
end

return Stats