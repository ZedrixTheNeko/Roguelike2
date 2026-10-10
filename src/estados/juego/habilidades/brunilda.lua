-- ============================================================
-- HABILIDADES DE BRUNILDA (Valquiria)
-- ============================================================
-- 1. Carga del Cuervo (dash atravesando enemigos)
-- 2. Lluvia de Valquiria (lanza al cielo que cae sobre el enemigo mas lejano)
-- 3. Furia del Valhalla (invulnerabilidad + atraccion + explosion final)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- HABILIDAD 1: Carga del Cuervo
-- ============================================================
-- Dash corto hacia adelante. Los enemigos atravesados reciben
-- dano y son empujados + stuneados.

function J.habilidadBrunilda1()
  local h = J.robin.personaje.habilidades[1]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)

  -- Activamos el dash (empuja al jugador en la direccion opuesta)
  local ok = J.robin:activarDash(J.robin.ultimaDirX, J.robin.ultimaDirY)
  if ok then
    -- El dash de activarDash va en direccion CONTRARIA al frente.
    -- Aqui queremos ir HACIA el frente, asi que invertimos.
    J.robin.dashDirX = math.cos(anguloBase)
    J.robin.dashDirY = math.sin(anguloBase)
  end

  -- Aplicar dano a enemigos cercanos en la direccion del dash
  local alcance = h.distancia or 90
  local radioChoque = 30

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < alcance then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < math.rad(50) then
          local murio = e:recibirDanio(h.dano)
          if e.aplicarKnockback then
            e:aplicarKnockback(math.cos(anguloBase), math.sin(anguloBase), h.empuje)
          end
          if e.aplicarStun then
            e:aplicarStun(0.6)
          end
          Helpers.reproducirImpacto()
          if murio then
            Helpers.reproducirMuerte()
            Helpers.soltarMonedas(e)
          end
        end
      end
    end
  end

  -- Jefe
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = jf.x - J.robin.x
    local dy = jf.y - J.robin.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < alcance then
      local angE = math.atan2(dy, dx)
      local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
      if dif < math.rad(50) then
        jf:recibirDanio(h.dano)
        Helpers.reproducirImpacto()
      end
    end
  end

  -- Efecto visual: corte/estela de dash
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "carga_cuervo",
    vida = 0.35,
    duracion = 0.35,
    rango = alcance,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirCorte()
end

-- ============================================================
-- HABILIDAD 2: Lluvia de Valquiria
-- ============================================================
-- Busca el enemigo mas lejano, lanza una lanza al cielo que
-- cae sobre el con explosion sagrada.

function J.habilidadBrunilda2()
  local h = J.robin.personaje.habilidades[2]

  -- Encontrar enemigo mas LEJANO dentro de un rango
  local mejor = nil
  local mejorD = 0
  local distMax = 500

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d2 = dx * dx + dy * dy
      if d2 > mejorD and d2 < distMax * distMax then
        mejorD = d2
        mejor = e
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local dx = J.salaActual.jefe.x - J.robin.x
    local dy = J.salaActual.jefe.y - J.robin.y
    local d2 = dx * dx + dy * dy
    if d2 > mejorD and d2 < distMax * distMax then
      mejorD = d2
      mejor = J.salaActual.jefe
    end
  end

  -- Si no hay enemigos, no hace nada
  if not mejor then return end

  -- Colocar la explosion sobre el enemigo
  local objetivoX = mejor.x
  local objetivoY = mejor.y

  -- Danio inmediato a enemigos en el area
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - objetivoX
      local dy = e.y - objetivoY
      local r = h.radio + e.radio
      if dx * dx + dy * dy < r * r then
        local murio = e:recibirDanio(h.dano)
        if e.aplicarKnockback then
          local ang = math.atan2(dy, dx)
          e:aplicarKnockback(math.cos(ang), math.sin(ang), 300)
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
    local r = h.radio + jf.radio
    if dx * dx + dy * dy < r * r then
      jf:recibirDanio(h.dano)
    end
  end

  -- Efecto visual: explosion sagrada en la posicion del enemigo
  table.insert(J.cortes, {
    x = objetivoX, y = objetivoY,
    angulo = 0,
    tipo = "explosion_sagrada",
    vida = 0.6,
    duracion = 0.6,
    radio = h.radio,
  })

  -- Estela desde Robin hasta el objetivo
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = math.atan2(objetivoY - J.robin.y, objetivoX - J.robin.x),
    tipo = "estela_lanza",
    vida = 0.3,
    duracion = 0.3,
    rango = math.sqrt((objetivoX - J.robin.x)^2 + (objetivoY - J.robin.y)^2),
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirImpacto()
end

-- ============================================================
-- HABILIDAD 3: Furia del Valhalla
-- ============================================================
-- 4s de invulnerabilidad, atrae enemigos cercanos hacia Robin,
-- y al terminar explota con dano masivo en area.

function J.habilidadBrunilda3()
  local h = J.robin.personaje.habilidades[3]
  J.accionEspecial.tipo = "furia_valquiria"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.duracion
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = false
  J.accionEspecial.radio = h.radio
  J.accionEspecial.danoFinal = h.danoFinal

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirCorte()
end

-- ============================================================
-- EXPLOSION FINAL DE FURIA DEL VALHALLA
-- ============================================================

function J.ejecutarFuriaValhalla()
  local a = J.accionEspecial
  local radio = a.radio or 100
  local dano = a.danoFinal or 30

  -- Aplicar dano en area
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local r = radio + e.radio
      if dx * dx + dy * dy < r * r then
        local murio = e:recibirDanio(dano)
        if e.aplicarKnockback then
          local ang = math.atan2(dy, dx)
          e:aplicarKnockback(math.cos(ang), math.sin(ang), 500)
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
    local dx = jf.x - J.robin.x
    local dy = jf.y - J.robin.y
    local r = radio + jf.radio
    if dx * dx + dy * dy < r * r then
      jf:recibirDanio(dano)
    end
  end

  -- Efecto visual: explosion grande dorada
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "explosion_valquiria",
    vida = 0.7,
    duracion = 0.7,
    radio = radio,
  })

  Helpers.reproducirCorte()
end

return true