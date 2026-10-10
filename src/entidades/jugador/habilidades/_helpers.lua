-- ============================================================
-- HABILIDADES - Helpers compartidos
-- ============================================================
-- Funciones reutilizables por todas las habilidades.

local J       = require("src.estados.juego.estado")
local sonidos = require("src.datos.sonidos")

local Helpers = {}

-- ============================================================
-- SONIDOS
-- ============================================================

function Helpers.reproducirImpacto()
  if sonidos.impacto then
    sonidos.impacto:stop()
    sonidos.impacto:play()
  end
end

function Helpers.reproducirMuerte()
  if sonidos.muerte_enemigo then
    sonidos.muerte_enemigo:stop()
    sonidos.muerte_enemigo:play()
  end
end

function Helpers.reproducirCorte()
  if sonidos.corte then
    sonidos.corte:stop()
    sonidos.corte:play()
  end
end

function Helpers.reproducirDisparo()
  if sonidos.disparo then
    sonidos.disparo:stop()
    sonidos.disparo:play()
  end
end

function Helpers.reproducirFuego()
  if sonidos.fuego then
    sonidos.fuego:stop()
    sonidos.fuego:play()
  elseif sonidos.disparo then
    sonidos.disparo:stop()
    sonidos.disparo:play()
  end
end

-- ============================================================
-- DROPS
-- ============================================================

function Helpers.soltarMonedas(e)
  if e == nil then return end
  if e.datos == nil then return end
  J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
end

-- ============================================================
-- APLICAR DAÑO EN CONO
-- ============================================================
-- Aplica daño a todos los enemigos dentro de un cono.
--   x, y         : origen del cono
--   anguloBase   : direccion central (radianes)
--   rango        : distancia maxima
--   apertura     : mitad del angulo de apertura (radianes)
--   dano         : cantidad de daño
--   empuje       : fuerza de knockback (opcional)
--   stunDur      : duracion del stun (opcional)
-- ============================================================

function Helpers.aplicarCono(x, y, anguloBase, rango, apertura, dano, empuje, stunDur)
  local dirX = math.cos(anguloBase)
  local dirY = math.sin(anguloBase)

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - x
      local dy = e.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < apertura then
          local murio = e:recibirDanio(dano)
          Helpers.reproducirImpacto()
          if murio then
            Helpers.reproducirMuerte()
            Helpers.soltarMonedas(e)
          else
            if empuje and e.aplicarKnockback then
              e:aplicarKnockback(dirX, dirY, empuje)
            end
            if stunDur and e.aplicarStun then
              e:aplicarStun(stunDur)
            end
          end
        end
      end
    end
  end

  -- Jefe
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = jf.x - x
    local dy = jf.y - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < rango + jf.radio then
      local angE = math.atan2(dy, dx)
      local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
      if dif < apertura then
        jf:recibirDanio(dano)
        Helpers.reproducirImpacto()
      end
    end
  end
end

-- ============================================================
-- APLICAR DAÑO A UN ENEMIGO
-- ============================================================

function Helpers.aplicarDanioAEnemigo(e, dano)
  if e == nil then return false end
  if not e.vivo then return false end
  local murio = e:recibirDanio(dano)
  Helpers.reproducirImpacto()
  if murio then
    Helpers.reproducirMuerte()
    Helpers.soltarMonedas(e)
  end
  return murio
end

-- ============================================================
-- EXPLOSION DE ORBE DE FUEGO (Merlin)
-- ============================================================

function J.explotarOrbeFuego(x, y, radio, dano)
  if radio == nil then radio = 42 end
  if dano == nil then dano = 8 end

  table.insert(J.cortes, {
    x = x, y = y,
    angulo = 0,
    tipo = "explosion_fuego",
    vida = 0.5,
    duracion = 0.5,
    radio = radio,
  })

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - x
      local dy = e.y - y
      local r = radio + e.radio
      if dx * dx + dy * dy < r * r then
        local murio = e:recibirDanio(dano)
        if e.aplicarQuemadura then
          e:aplicarQuemadura(5.0)
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
    local dx = jf.x - x
    local dy = jf.y - y
    local r = radio + jf.radio
    if dx * dx + dy * dy < r * r then
      jf:recibirDanio(dano)
    end
  end
end

-- ============================================================
-- BUSCAR ENEMIGO MAS CERCANO
-- ============================================================

function Helpers.enemigoMasCercano(x, y, distMax)
  local mejor = nil
  local mejorD = (distMax or 999999) ^ 2

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - x
      local dy = e.y - y
      local d2 = dx * dx + dy * dy
      if d2 < mejorD then
        mejorD = d2
        mejor = e
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local dx = J.salaActual.jefe.x - x
    local dy = J.salaActual.jefe.y - y
    local d2 = dx * dx + dy * dy
    if d2 < mejorD then
      mejorD = d2
      mejor = J.salaActual.jefe
    end
  end

  return mejor
end

return Helpers