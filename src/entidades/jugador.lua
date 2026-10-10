-- ============================================================
-- JUGADOR - Fachada
-- ============================================================
-- Este archivo expone la clase Jugador. Toda la logica esta
-- separada en modulos dentro de src/entidades/jugador/. Aqui
-- solo se ensamblan y se define el constructor.

local Jugador = {}
Jugador.__index = Jugador

-- ============================================================
-- CARGAR MODULOS
-- ============================================================
local Stats      = require("src.entidades.jugador.stats")
local Movimiento = require("src.entidades.jugador.movimiento")
local Efectos    = require("src.entidades.jugador.efectos")
local Dibujo     = require("src.entidades.jugador.dibujo")

-- ============================================================
-- MEZCLAR METODOS EN LA CLASE
-- ============================================================
for k, v in pairs(Stats) do      Jugador[k] = v end
for k, v in pairs(Movimiento) do Jugador[k] = v end
for k, v in pairs(Efectos) do    Jugador[k] = v end
for k, v in pairs(Dibujo) do     Jugador[k] = v end

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

function Jugador.nuevo(x, y)
  local j = setmetatable({}, Jugador)

  -- Posicion y dimensiones
  j.x, j.y = x, y
  j.radio = 6
  j.anchoDibujo = 16
  j.altoDibujo = 20

  -- Direccion
  j.ultimaDirX, j.ultimaDirY = 1, 0

  -- Estado
  j.estado = "normal"
  j.dashTimer = 0
  j.dashDirX, j.dashDirY = 0, 0
  j.invulnerable = 0
  j.buffVelocidad = 0
  j.buffDuracion = 5
  j.slowTimer = 0

  -- Efectos visuales
  j.flashTimer = 0
  j.flashColor = nil
  j.shakeTimer = 0
  j.shakeMag = 0

  -- Monedas y gemas
  j.monedas = 0
  j.gemas = 0

  -- Vida
  j.vivo = true
  j.velActualX, j.velActualY = 0, 0

  -- Animacion
  j.animTimer = 0
  j.caminando = false

  -- Ataque
  j.cooldownDisparo = 0
  j.cooldownDisparoMax = 0.28

  -- Regeneracion
  j.tiempoSinDano = 0
  j.tiempoRegenEscudo = 0
  j.tiempoDesdeAtaque = 999

  -- Combo melee
  j.comboPaso = 1
  j.comboTimer = 0

  -- ============================================================
  -- NUEVOS: esquiva, frascos, parry, sobrecarga, swing
  -- ============================================================
  j.rodando = false
  j.dashVel = nil
  j.parryActivo = false
  j.parryExito = false
  j.swingT = 0
  j.swingDur = 0.18
  j.swingLado = 1
  j.sobrecargaT = 0
  j.frascos = 2
  j.frascosMax = 3

  -- Orbes (Merlin)
  j.orbsActivos = false
  j.orbsTimer = 0
  j.orbsDuracionTotal = 5
  j.orbsAngulo = 0
  j.orbs = {}

  -- Buffs de personajes
  j.dualWield = 0              -- Coyote
  j.sinfoniaTimer = 0          -- Lyra
  j.sinfoniaDano = 1
  j.sinfoniaVelocidad = 1
  j.sinfoniaCadencia = 1
  j.dron = nil                 -- Nyx-7

  -- ============================================================
  -- Stats base (se sobreescriben en aplicarPersonaje)
  -- ============================================================
  j.hpMax = 6
  j.hp = 6
  j.escudoMax = 3
  j.escudo = 3
  j.velocidad = 90
  j.recursoTipo = "estamina"
  j.recursoMax = 100
  j.recurso = 100
  j.regenRecurso = 30
  j.retrasoRegen = 1.5
  j.costeAtaque = 20
  j.danoAtaque = 4
  j.cooldownAtaque = 0.28

  -- Sistema de balas (Coyote)
  j.recargando = false
  j.timerRecarga = 0
  j.duracionRecarga = 1.6

  -- Colores base (se sobreescriben en aplicarPersonaje)
  j.colorTunica = {0.35, 0.75, 0.45}
  j.colorCapa = {0.25, 0.55, 0.35}
  j.colorPelo = {0.55, 0.30, 0.15}
  j.colorPiel = {1, 0.85, 0.70}
  j.tipoArma = "arco"
  j.personaje = nil

  -- Aplicar stats del personaje actual
  j:aplicarPersonaje()
  j:resetearVida()

  return j
end

return Jugador