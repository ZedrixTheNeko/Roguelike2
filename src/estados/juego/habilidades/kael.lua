-- ============================================================
-- HABILIDADES DE KAEL (Cazador de Sombras)
-- ============================================================
-- 1. Lanzamiento Gemelo (2 bumeranes en V)
-- 2. Ricochet Fatal (bumeran que rebota)
-- 3. Marca del Cazador (marca enemigos, +40% dano recibido)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades._helpers")

-- ============================================================
-- HABILIDAD 1: Lanzamiento Gemelo
-- ============================================================
-- Lanza 2 bumeranes en V que vuelven al jugador.

function J.habilidadKael1()
  local h = J.robin.personaje.habilidades[1]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local apertura = math.rad(15)

  for i = -1, 1, 2 do
    local ang = anguloBase + i * apertura
    local p = J.poolFlechas:obtener()
    if p then
      p:lanzar(J.robin.x, J.robin.y, math.cos(ang), math.sin(ang),
        h.velocidad, h.dano, false, "bumeran", J.robin)
      p.distanciaMax = 160
    end
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 2: Ricochet Fatal
-- ============================================================
-- Bumeran que rebota hasta agotar sus rebotes contra paredes.

function J.habilidadKael2()
  local h = J.robin.personaje.habilidades[2]
  local p = J.poolFlechas:obtener()
  if p then
    p:lanzar(J.robin.x, J.robin.y,
      J.robin.ultimaDirX, J.robin.ultimaDirY,
      h.velocidad, h.dano, false, "bumeran_ricochet", J.robin)
    p.rebotesRestantes = h.rebotes
    p.distanciaMax = 320
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 3: Marca del Cazador
-- ============================================================
-- Marca a todos los enemigos en radio 200 durante 6s.
-- Los marcados reciben +40% dano.

function J.habilidadKael3()
  local h = J.robin.personaje.habilidades[3]
  local marcados = 0

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d2 = dx * dx + dy * dy
      if d2 <= h.radio * h.radio then
        e.marcadoTimer = h.duracion
        e.marcadoMultiplicador = h.multiplicadorDano
        marcados = marcados + 1
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local dx = J.salaActual.jefe.x - J.robin.x
    local dy = J.salaActual.jefe.y - J.robin.y
    local d2 = dx * dx + dy * dy
    if d2 <= h.radio * h.radio then
      J.salaActual.jefe.marcadoTimer = h.duracion
      J.salaActual.jefe.marcadoMultiplicador = h.multiplicadorDano
      marcados = marcados + 1
    end
  end

  -- Efecto visual: anillo expansivo dorado
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "marca_cazador",
    vida = 0.8,
    duracion = 0.8,
    radio = h.radio,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirDisparo()
end

return true