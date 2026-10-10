-- ============================================================
-- HABILIDADES DE CONAN (Guerrero)
-- ============================================================
-- 1. Corte Noqueador
-- 2. Estocada Maestra (con carga)
-- 3. Danza Cortante (teleport + 2 cortes)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades._helpers")

-- ============================================================
-- HABILIDAD 1: Corte Noqueador
-- ============================================================
-- Cono amplio que empuja y stunea.

function J.habilidadConan1()
  local h = J.robin.personaje.habilidades[1]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "golpe_fuerte",
    vida = h.duracionAnim,
    duracion = h.duracionAnim,
  })

  Helpers.aplicarCono(J.robin.x, J.robin.y, anguloBase,
    h.rango, h.apertura, h.dano, h.empuje, h.stunDur)

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirCorte()
end

-- ============================================================
-- HABILIDAD 2: Estocada Maestra
-- ============================================================
-- Carga durante 1.1s y luego hace una estocada devastadora.

function J.habilidadConan2()
  local h = J.robin.personaje.habilidades[2]
  J.accionEspecial.tipo = "carga_estocada"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.cargaTiempo
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
end

function J.ejecutarEstocadaMaestra()
  local h = J.robin.personaje.habilidades[2]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "estocada_dorada",
    vida = 0.6,
    duracion = 0.6,
  })

  Helpers.aplicarCono(J.robin.x, J.robin.y, anguloBase,
    h.rango, h.apertura, h.dano, h.empuje, nil)

  Helpers.reproducirCorte()
end

-- ============================================================
-- HABILIDAD 3: Danza Cortante
-- ============================================================
-- Se teleporta junto al enemigo, hace 2 cortes rapidos y sale.

function J.habilidadConan3()
  local mejor = Helpers.enemigoMasCercano(J.robin.x, J.robin.y, 220)

  if mejor == nil then return end

  local h = J.robin.personaje.habilidades[3]
  J.accionEspecial.tipo = "danza_cortante"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.duracionTotal
  J.accionEspecial.fase = 1
  J.accionEspecial.enemigoObjetivo = mejor
  J.accionEspecial.origenX = J.robin.x
  J.accionEspecial.origenY = J.robin.y
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
end

return true