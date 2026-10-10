-- ============================================================
-- HABILIDADES DE LYRA (Barda)
-- ============================================================
-- 1. Cancion de Cuna (cono de 90 grados que aturde enemigos)
-- 2. Nota Resonante (explosion en area con empuje)
-- 3. Sinfonia Belica (buff de dano, velocidad y cadencia)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- HABILIDAD 1: Cancion de Cuna
-- ============================================================
-- Cono de 90 grados (45 a cada lado) con rango 100. A los
-- enemigos dentro les aplica stun de 3s. No hace dano.

function J.habilidadLyra1()
  local h = J.robin.personaje.habilidades[1]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local rango = h.rango or 100
  local apertura = (h.apertura or math.rad(90)) / 2

  -- Efecto visual: arco de ondas musicales
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "cancion_cuna",
    vida = 0.7,
    duracion = 0.7,
    rango = rango,
    apertura = apertura,
  })

  -- Aplicar stun a enemigos en el cono
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < apertura then
          if e.aplicarStun then
            e:aplicarStun(h.duracion or 3.0)
          end
          if e.aplicarKnockback then
            e:aplicarKnockback(math.cos(angE), math.sin(angE), 60)
          end
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = jf.x - J.robin.x
    local dy = jf.y - J.robin.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < rango + jf.radio then
      local angE = math.atan2(dy, dx)
      local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
      if dif < apertura then
        -- El jefe recibe stun reducido
        if jf.aplicarStun then
          jf:aplicarStun((h.duracion or 3.0) * 0.4)
        end
      end
    end
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.5)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 2: Nota Resonante
-- ============================================================
-- Explosion en area radio 70, dano, empuje 220. Se dispara en
-- el enemigo mas cercano en direccion de apuntado, o hacia
-- adelante si no hay nadie.

function J.habilidadLyra2()
  local h = J.robin.personaje.habilidades[2]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local distancia = 80

  -- Buscar objetivo cercano en direccion de apuntado
  local objetivo = nil
  local mejorD = 180 * 180
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d2 = dx * dx + dy * dy
      if d2 < mejorD then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < math.rad(60) then
          mejorD = d2
          objetivo = e
        end
      end
    end
  end

  local objetivoX, objetivoY
  if objetivo then
    objetivoX = objetivo.x
    objetivoY = objetivo.y
  else
    objetivoX = J.robin.x + math.cos(anguloBase) * distancia
    objetivoY = J.robin.y + math.sin(anguloBase) * distancia
  end

  local radio = h.radio or 70
  local dano = h.dano or 8
  local empuje = h.empuje or 220

  -- Efecto visual
  table.insert(J.cortes, {
    x = objetivoX, y = objetivoY,
    angulo = 0,
    tipo = "nota_resonante",
    vida = 0.55,
    duracion = 0.55,
    radio = radio,
  })

  -- Aplicar dano en area
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - objetivoX
      local dy = e.y - objetivoY
      local r = radio + e.radio
      if dx * dx + dy * dy < r * r then
        local murio = e:recibirDanio(dano)
        if e.aplicarKnockback then
          local ang = math.atan2(dy, dx)
          e:aplicarKnockback(math.cos(ang), math.sin(ang), empuje)
        end
        Helpers.reproducirImpacto()
        if murio then
          Helpers.reproducirMuerte()
          Helpers.soltarMonedas(e)
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = jf.x - objetivoX
    local dy = jf.y - objetivoY
    local r = radio + jf.radio
    if dx * dx + dy * dy < r * r then
      jf:recibirDanio(dano)
    end
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.4)
  Helpers.reproducirImpacto()
end

-- ============================================================
-- HABILIDAD 3: Sinfonia Belica
-- ============================================================
-- Buff de 6s: +30% dano, +25% velocidad, +50% cadencia.

function J.habilidadLyra3()
  local h = J.robin.personaje.habilidades[3]

  J.robin.sinfoniaTimer = h.duracion or 6.0
  J.robin.sinfoniaDano = h.multiplicadorDano or 1.30
  J.robin.sinfoniaVelocidad = h.multiplicadorVelocidad or 1.25
  J.robin.sinfoniaCadencia = h.multiplicadorCadencia or 1.50

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "sinfonia_activada",
    vida = 0.8,
    duracion = 0.8,
    radio = 60,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.5)
  Helpers.reproducirDisparo()
end

return true