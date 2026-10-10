-- ============================================================
-- HABILIDADES DE SHEN (Samurai)
-- ============================================================
-- 1. Iai (Desenvaine): corte circular instantaneo en area.
--    Enemigos muy cerca reciben el doble de dano.
-- 2. Pasos de Viento: 3 dashes consecutivos con estela que daña.
-- 3. Corte del Vacio: carga 0.8s y libera un tajo de energia
--    masivo con onda expansiva.
--
-- NOTA: los sonidos se llaman a traves de Helpers para no
-- tener que requerir sonidos directo y mantener consistencia
-- con el resto de los modulos de habilidad.

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- HABILIDAD 1: Iai (Desenvaine)
-- ============================================================
-- Corte circular instantaneo. Enemigos a menos de 20px reciben
-- dano x2. Tambien hace un dash corto hacia atras para "escapar".

function J.habilidadShen1()
  local h = J.robin.personaje.habilidades[1]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local rango = h.rango or 50

  -- Efecto visual: circulo amplio de corte
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "iai_corte",
    vida = 0.35,
    duracion = 0.35,
    radio = rango,
  })

  -- Aplicar dano a enemigos en radio
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local dano = h.dano
        local radioCerca = h.radioCercano or 20
        local multiplicador = h.multiplicadorCercano or 2.0

        -- Si esta muy cerca, doble dano
        if d < radioCerca + e.radio then
          dano = dano * multiplicador
        end

        local murio = e:recibirDanio(dano)
        if e.aplicarKnockback then
          local ang = math.atan2(dy, dx)
          e:aplicarKnockback(math.cos(ang), math.sin(ang), 180)
        end
        Helpers.reproducirImpacto()
        if murio then
          Helpers.reproducirMuerte()
          J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
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
      local dano = h.dano
      if d < 20 + jf.radio then
        dano = dano * (h.multiplicadorCercano or 2.0)
      end
      jf:recibirDanio(dano)
      Helpers.reproducirImpacto()
    end
  end

  -- Pequeno retroceso hacia atras para el estilo iai
  local Colisiones = require("src.sistemas.colisiones")
  local retroX = J.robin.x - math.cos(anguloBase) * 15
  local retroY = J.robin.y - math.sin(anguloBase) * 15
  if not Colisiones.circuloConMapa(retroX, J.robin.y, J.robin.radio, J.salaActual.mapa) then
    J.robin.x = retroX
  end
  if not Colisiones.circuloConMapa(J.robin.x, retroY, J.robin.radio, J.salaActual.mapa) then
    J.robin.y = retroY
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.6)
  Helpers.reproducirCorte()
end

-- ============================================================
-- HABILIDAD 2: Pasos de Viento
-- ============================================================
-- 3 dashes consecutivos con 0.2s entre ellos. Cada dash deja una
-- estela que daña a enemigos que la atraviesen.

function J.habilidadShen2()
  local h = J.robin.personaje.habilidades[2]

  J.accionEspecial.tipo = "pasos_viento"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = 0.6    -- 3 dashes * 0.2s
  J.accionEspecial.fase = 1
  J.accionEspecial.dashesRestantes = h.dashes or 3
  J.accionEspecial.dashActual = 0
  J.accionEspecial.dashIntervalo = 0.2
  J.accionEspecial.timerDash = 0
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true
  J.accionEspecial.direccionX = J.robin.ultimaDirX
  J.accionEspecial.direccionY = J.robin.ultimaDirY
  J.accionEspecial.distancia = h.distancia or 55
  J.accionEspecial.danoEstela = h.danoEstela or 3

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 1.2)
  Helpers.reproducirCorte()
end

-- ============================================================
-- HABILIDAD 3: Corte del Vacio
-- ============================================================
-- Carga 0.8s. Al liberar, produce un tajo vertical de energia
-- que se expande hacia adelante, con onda expansiva.

function J.habilidadShen3()
  local h = J.robin.personaje.habilidades[3]

  J.accionEspecial.tipo = "carga_corte_vacio"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.cargaTiempo or 0.8
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 2.0)
end

-- ============================================================
-- EJECUTAR CORTE DEL VACIO (al terminar la carga)
-- ============================================================

function J.ejecutarCorteVacio()
  local h = J.robin.personaje.habilidades[3]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)
  local rango = h.rango or 80

  -- Efecto visual: tajo de energia
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "corte_vacio",
    vida = 0.6,
    duracion = 0.6,
    rango = rango,
  })

  -- Onda expansiva
  table.insert(J.cortes, {
    x = J.robin.x + math.cos(anguloBase) * rango * 0.5,
    y = J.robin.y + math.sin(anguloBase) * rango * 0.5,
    angulo = 0,
    tipo = "explosion_vacio",
    vida = 0.5,
    duracion = 0.5,
    radio = 60,
  })

  -- Aplicar dano a enemigos en el cono
  local dirX = math.cos(anguloBase)
  local dirY = math.sin(anguloBase)
  local apertura = math.rad(45)

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local ex = e.x - J.robin.x
      local ey = e.y - J.robin.y
      local d = math.sqrt(ex * ex + ey * ey)
      if d < rango + e.radio then
        local angE = math.atan2(ey, ex)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < apertura then
          local murio = e:recibirDanio(h.dano)
          if e.aplicarKnockback then
            e:aplicarKnockback(dirX, dirY, h.empuje or 400)
          end
          Helpers.reproducirImpacto()
          if murio then
            Helpers.reproducirMuerte()
            J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
          end
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local ex = jf.x - J.robin.x
    local ey = jf.y - J.robin.y
    local d = math.sqrt(ex * ex + ey * ey)
    if d < rango + jf.radio then
      local angE = math.atan2(ey, ex)
      local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
      if dif < apertura then
        jf:recibirDanio(h.dano)
        Helpers.reproducirImpacto()
      end
    end
  end

  Helpers.reproducirCorte()
end

return true