-- ============================================================
-- HABILIDADES DE NYX-7 (Cazadora Estelar)
-- ============================================================
-- 1. Dron Centinela (drone orbitando que dispara solo)
-- 2. Anclaje Gravimetrico (zona que ralentiza y atrae)
-- 3. Rafaga Orbital (rayos desde el cielo + desintegracion)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- HABILIDAD 1: Dron Centinela
-- ============================================================

function J.habilidadNyx1()
  local h = J.robin.personaje.habilidades[1]

  J.robin.dron = {
    activo = true,
    timer = h.duracion or 8.0,
    angulo = 0,
    radioOrbita = 30,
    cooldownDisparo = 0.3,
    cadencia = h.cadencia or 0.5,
    dano = h.dano or 3,
  }

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "dron_activado",
    vida = 0.6,
    duracion = 0.6,
    radio = 40,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.5)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 2: Anclaje Gravimetrico
-- ============================================================

function J.habilidadNyx2()
  local h = J.robin.personaje.habilidades[2]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local distancia = 70

  J.accionEspecial.tipo = "anclaje_gravimetrico"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.duracion or 4.0
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = false
  J.accionEspecial.zonaX = J.robin.x + math.cos(anguloBase) * distancia
  J.accionEspecial.zonaY = J.robin.y + math.sin(anguloBase) * distancia
  J.accionEspecial.radio = h.radio or 80
  J.accionEspecial.factorSlow = h.factorSlow or 0.40

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.5)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 3: Rafaga Orbital
-- ============================================================

function J.habilidadNyx3()
  local h = J.robin.personaje.habilidades[3]

  J.accionEspecial.tipo = "rafaga_orbital_activa"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.duracion or 2.0
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = false
  J.accionEspecial.rayos = {}
  J.accionEspecial.danoPorRayo = h.dano or 14

  -- Recolectar enemigos vivos
  local enemigos = {}
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then table.insert(enemigos, e) end
  end
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    table.insert(enemigos, J.salaActual.jefe)
  end

  -- Crear rayos (round-robin si hay menos enemigos que rayos)
  local rayos = h.rayos or 5
  if #enemigos > 0 then
    for i = 1, rayos do
      local target = enemigos[((i - 1) % #enemigos) + 1]
      local retraso = (i - 1) * 0.15 + math.random() * 0.10
      table.insert(J.accionEspecial.rayos, {
        target = target,
        delay = retraso,
        timer = 0,
        activo = false,
        caido = false,
        x = target.x,
        y = target.y,
      })
    end
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 1.5)
  Helpers.reproducirDisparo()
end

return true