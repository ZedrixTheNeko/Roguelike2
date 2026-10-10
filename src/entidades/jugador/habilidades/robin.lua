-- ============================================================
-- HABILIDADES DE ROBIN (Arquera)
-- ============================================================
-- 1. Dash Flechero
-- 2. Lluvia de Flechas
-- 3. Flecha Perforante

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades._helpers")

-- ============================================================
-- HABILIDAD 1: Dash Flechero
-- ============================================================
-- Dispara 3 flechas en abanico y hace dash en direccion opuesta.

function J.habilidadRobin1()
  local h = J.robin.personaje.habilidades[1]
  local baseX = J.robin.ultimaDirX
  local baseY = J.robin.ultimaDirY
  local anguloBase = math.atan2(baseY, baseX)
  local apertura = math.rad(15)

  for i = -1, 1 do
    local ang = anguloBase + i * apertura
    local dx = math.cos(ang)
    local dy = math.sin(ang)
    local p = J.poolFlechas:obtener()
    if p then
      p:lanzar(J.robin.x, J.robin.y, dx, dy, 242, J.robin.danoAtaque, false, "flecha")
    end
  end

  J.robin.ultimaDirX = math.cos(anguloBase)
  J.robin.ultimaDirY = math.sin(anguloBase)

  local ok = J.robin:activarDash(J.robin.ultimaDirX, J.robin.ultimaDirY)
  if ok then
    J.robin.buffDuracion = h.duracion
    local inv = h.invulnerableDurante or 0.5
    J.robin.invulnerable = math.max(J.robin.invulnerable, inv)
  end

  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 2: Lluvia de Flechas
-- ============================================================
-- Dispara una flecha marcadora. Al impactar o expirar, cae una
-- lluvia de flechas en esa zona durante unos segundos.

function J.habilidadRobin2()
  local h = J.robin.personaje.habilidades[2]
  local p = J.poolFlechas:obtener()
  if p then
    p:lanzar(J.robin.x, J.robin.y,
      J.robin.ultimaDirX, J.robin.ultimaDirY,
      280, 0, false, "flecha_marcadora")

    J.accionEspecial.tipo = "esperando_marcadora"
    J.accionEspecial.timer = 0
    J.accionEspecial.duracion = 2.0
    J.accionEspecial.marcadoraRef = p
    J.accionEspecial.particulas = {}
    J.accionEspecial.golpeAplicado = {}
    J.accionEspecial.bloqueaMovimiento = false

    J.robin.invulnerable = math.max(J.robin.invulnerable, 0.4)
  end
end

-- ============================================================
-- HABILIDAD 3: Flecha Perforante
-- ============================================================
-- Flecha grande que atraviesa enemigos.

function J.habilidadRobin3()
  local h = J.robin.personaje.habilidades[3]
  local p = J.poolFlechas:obtener()
  if p then
    p:lanzar(J.robin.x, J.robin.y,
      J.robin.ultimaDirX, J.robin.ultimaDirY,
      h.velocidad, h.dano, false, "flecha_perforante")
  end
  J.robin.invulnerable = math.max(J.robin.invulnerable, 0.4)
  Helpers.reproducirDisparo()
end

return true