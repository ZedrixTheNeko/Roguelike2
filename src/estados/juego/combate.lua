local J        = require("src.estados.juego.estado")
local sonidos  = require("src.datos.sonidos")

-- ============================================================
-- HELPERS LOCALES
-- ============================================================

local function snd(nombre)
  local s = sonidos[nombre]
  if s then s:stop() s:play() end
end

-- Cierra el ataque: gasta recurso, activa cooldown, sonido
local function cerrarAtaque(coste, cooldown, sonido)
  J.robin:gastarResistencia(coste)
  J.robin.cooldownDisparo = cooldown
  if sonido then snd(sonido) end
end

-- Aplica dano en cono (usado por melee)
local function danioCono(x, y, ang, rango, apertura, dano, empuje, stun)
  local hits = 0
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - x, e.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local a = math.atan2(dy, dx)
        local dif = math.abs(((a - ang + math.pi) % (math.pi * 2)) - math.pi)
        if dif < apertura then
          local murio = e:recibirDanio(dano)
          hits = hits + 1
          if murio then
            J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
          elseif empuje and e.aplicarKnockback then
            e:aplicarKnockback(math.cos(ang), math.sin(ang), empuje)
            if stun and e.aplicarStun then e:aplicarStun(stun) end
          end
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx, dy = jf.x - x, jf.y - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < rango + jf.radio then
      local a = math.atan2(dy, dx)
      local dif = math.abs(((a - ang + math.pi) % (math.pi * 2)) - math.pi)
      if dif < apertura then
        jf:recibirDanio(dano)
        hits = hits + 1
      end
    end
  end
  return hits
end

-- Aplica dano en circulo
local function danioCirculo(x, y, radio, dano, empuje)
  local hits = 0
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - x, e.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < radio + e.radio then
        local murio = e:recibirDanio(dano)
        hits = hits + 1
        if murio then
          J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
        elseif empuje and e.aplicarKnockback and d > 0.01 then
          e:aplicarKnockback(dx / d, dy / d, empuje)
        end
      end
    end
  end
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx, dy = jf.x - x, jf.y - y
    if math.sqrt(dx * dx + dy * dy) < radio + jf.radio then
      jf:recibirDanio(dano)
      hits = hits + 1
    end
  end
  return hits
end

-- Mueve al jugador hacia adelante hasta chocar
local function avanzarJugador(dist, dx, dy)
  local Colisiones = require("src.sistemas.colisiones")
  local r = J.robin
  local paso = 4
  local recorrido = 0
  while recorrido < dist do
    local nx, ny = r.x + dx * paso, r.y + dy * paso
    if Colisiones.circuloConMapa(nx, ny, r.radio, J.salaActual.mapa) then break end
    r.x, r.y = nx, ny
    recorrido = recorrido + paso
  end
  return recorrido
end

-- ============================================================
-- 1) ARQUERO (Robin) - arco
-- ============================================================

function J.atacarArquero(dirX, dirY)
  local p = J.poolFlechas:obtener()
  if not p then return end
  p:lanzar(J.robin.x, J.robin.y, dirX, dirY, 220, J.robin.danoAtaque, false, "flecha")
  cerrarAtaque(J.robin.costeAtaque, J.robin.cooldownAtaque, "disparo")
end

-- ============================================================
-- 2) MAGO (Merlin) - grimorio
-- ============================================================

function J.atacarMago(dirX, dirY)
  local p = J.poolFlechas:obtener()
  if not p then return end
  p:lanzar(J.robin.x, J.robin.y, dirX, dirY, 200, J.robin.danoAtaque, false, "fuego")
  J.robin:gastarResistencia(J.robin.costeAtaque)
  J.robin.cooldownDisparo = J.robin.cooldownAtaque
  if sonidos.fuego then sonidos.fuego:stop() sonidos.fuego:play()
  elseif sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 3) GUERRERO (Conan) - espada, combo de 3
-- ============================================================

function J.atacarGuerrero(dirX, dirY)
  local paso = J.robin.comboPaso
  J.robin.comboPaso = paso + 1
  if J.robin.comboPaso > 3 then J.robin.comboPaso = 1 end
  J.robin.comboTimer = 1.2

  local dano = J.robin.danoAtaque
  local esEstocada = false
  local rango, apertura, tipoCorte

  if paso == 1 then
    tipoCorte = "corte_izq"; rango = 34; apertura = math.rad(80)
  elseif paso == 2 then
    tipoCorte = "corte_der"; rango = 34; apertura = math.rad(80)
  else
    tipoCorte = "estocada"; dano = dano * 1.6; esEstocada = true
    rango = 50; apertura = math.rad(35)
  end

  local anguloBase = math.atan2(dirY, dirX)

  J.robin.swingLado = (paso == 1) and 1 or -1
  J.robin.swingDur = 0.2
  J.robin.swingT = 0.2

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase, tipo = tipoCorte,
    vida = 0.25, duracion = 0.25,
  })

  local empuje = esEstocada and 220 or nil
  danioCono(J.robin.x, J.robin.y, anguloBase, rango, apertura, dano, empuje, nil)

  J.robin:gastarResistencia(J.robin.costeAtaque)
  J.robin.cooldownDisparo = J.robin.cooldownAtaque
  if sonidos.corte then sonidos.corte:stop() sonidos.corte:play()
  elseif sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 4) CAZADOR (Kael) - bumeran
-- ============================================================

function J.atacarCazador(dirX, dirY)
  local p = J.poolFlechas:obtener()
  if not p then return end
  p:lanzar(J.robin.x, J.robin.y, dirX, dirY, 260, J.robin.danoAtaque, false, "bumeran", J.robin)
  cerrarAtaque(J.robin.costeAtaque, J.robin.cooldownAtaque, "disparo")
end

-- ============================================================
-- 5) SHADOW - dagas gemelas, combo de 3 con bonus por la espalda
-- ============================================================

function J.atacarShadow(dirX, dirY)
  local r = J.robin
  local ang = math.atan2(dirY, dirX)
  local paso = r.comboPaso
  r.comboPaso = paso + 1
  if r.comboPaso > 3 then r.comboPaso = 1 end
  r.comboTimer = 0.9

  r.swingLado = -(r.swingLado or 1)
  r.swingDur = 0.14
  r.swingT = 0.14

  local dano = r.danoAtaque
  if paso == 3 then
    dano = dano * 1.5
    avanzarJugador(10, dirX, dirY)
  end

  table.insert(J.cortes, {
    x = r.x, y = r.y,
    angulo = ang, tipo = "tajo_dagas",
    lado = r.swingLado,
    vida = 0.16, duracion = 0.16,
  })

  -- Dano con bonus por atacar por la espalda
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - r.x, e.y - r.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < 30 + e.radio then
        local a = math.atan2(dy, dx)
        local dif = math.abs(((a - ang + math.pi) % (math.pi * 2)) - math.pi)
        if dif < math.rad(65) then
          local dm = dano
          if e.ultimaDirX and e.ultimaDirY then
            if e.ultimaDirX * dirX + e.ultimaDirY * dirY > 0.25 then
              dm = dano * 1.6
              J.agregarNotificacion("ESPALDA!", e.x, e.y - e.radio - 14, {1.0, 0.75, 0.25})
            end
          end
          local murio = e:recibirDanio(dm)
          if murio then
            J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
          elseif e.aplicarKnockback then
            e:aplicarKnockback(dirX, dirY, 60)
          end
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx, dy = jf.x - r.x, jf.y - r.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 30 + jf.radio then
      local a = math.atan2(dy, dx)
      local dif = math.abs(((a - ang + math.pi) % (math.pi * 2)) - math.pi)
      if dif < math.rad(65) then
        jf:recibirDanio(dano)
      end
    end
  end

  cerrarAtaque(r.costeAtaque, r.cooldownAtaque, "corte")
end

-- ============================================================
-- 6) VALQUIRIA (Brunilda) - lanza, combo de 3 con abanico final
-- ============================================================

function J.atacarValquiria(dirX, dirY)
  local paso = J.robin.comboPaso
  J.robin.comboPaso = paso + 1
  if J.robin.comboPaso > 3 then J.robin.comboPaso = 1 end
  J.robin.comboTimer = 1.5

  local anguloBase = math.atan2(dirY, dirX)
  local dano = J.robin.danoAtaque
  local rango, apertura
  local costeExtra = 1.0

  if paso == 3 then
    rango = 62
    apertura = math.rad(20)
    dano = dano * 1.25
    costeExtra = 1.3

    local dispersiones = { -15, 0, 15 }

    for _, grados in ipairs(dispersiones) do
      local ang = anguloBase + math.rad(grados)

      table.insert(J.cortes, {
        x = J.robin.x, y = J.robin.y,
        angulo = ang, tipo = "estocada_lanza",
        vida = 0.28, duracion = 0.28, rango = rango,
      })

      local dirX2 = math.cos(ang)
      local dirY2 = math.sin(ang)
      danioCono(J.robin.x, J.robin.y, ang, rango, apertura, dano, 200, nil)
    end

  else
    rango = 55
    apertura = math.rad(25)

    table.insert(J.cortes, {
      x = J.robin.x, y = J.robin.y,
      angulo = anguloBase, tipo = "estocada_lanza",
      vida = 0.22, duracion = 0.22, rango = rango,
    })

    local dirFinalX = math.cos(anguloBase)
    local dirFinalY = math.sin(anguloBase)

    for _, e in ipairs(J.salaActual.enemigos) do
      if e.vivo then
        local dx = e.x - J.robin.x
        local dy = e.y - J.robin.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < rango + e.radio then
          local angE = math.atan2(dy, dx)
          local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
          if dif < apertura then
            local murio = e:recibirDanio(dano)
            if murio then
              J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
            elseif e.aplicarKnockback then
              e:aplicarKnockback(dirFinalX, dirFinalY, 150)
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
          jf:recibirDanio(dano)
        end
      end
    end
  end

  local coste = J.robin.costeAtaque * costeExtra
  J.robin:gastarResistencia(coste)
  J.robin.cooldownDisparo = J.robin.cooldownAtaque
  if sonidos.corte then sonidos.corte:stop() sonidos.corte:play()
  elseif sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 7) PISTOLERO (Coyote) - revolver, dual wield opcional
-- ============================================================

function J.atacarPistolero(dirX, dirY)
  if J.robin.recargando then return end
  if J.robin.recurso <= 0 then return end

  local dualActivo = (J.robin.dualWield or 0) > 0
  local anguloBase = math.atan2(dirY, dirX)

  table.insert(J.cortes, {
    x = J.robin.x + dirX * 8,
    y = J.robin.y + dirY * 8,
    angulo = anguloBase,
    tipo = "disparo_revolver",
    vida = 0.1, duracion = 0.1,
  })

  if dualActivo and J.robin.recurso >= 2 then
    local perpX = math.cos(anguloBase + math.pi / 2) * 5
    local perpY = math.sin(anguloBase + math.pi / 2) * 5

    for i = -1, 1, 2 do
      local p = J.poolFlechas:obtener()
      if p then
        p:lanzar(
          J.robin.x + perpX * i,
          J.robin.y + perpY * i,
          dirX, dirY,
          480, J.robin.danoAtaque, false, "bala")
      end
    end

    J.robin:gastarResistencia(2)
    J.robin.cooldownDisparo = J.robin.cooldownAtaque

    table.insert(J.cortes, {
      x = J.robin.x, y = J.robin.y,
      angulo = anguloBase, tipo = "disparo_doble",
      vida = 0.15, duracion = 0.15,
    })
  else
    local p = J.poolFlechas:obtener()
    if not p then return end
    p:lanzar(J.robin.x, J.robin.y, dirX, dirY, 480, J.robin.danoAtaque, false, "bala")
    J.robin:gastarResistencia(1)
    J.robin.cooldownDisparo = J.robin.cooldownAtaque
  end

  if sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 8) SAMURAI (Shen Y Sable) - katana, combo de 3 con avance corto
-- ============================================================

function J.atacarSamurai(dirX, dirY)
  local paso = J.robin.comboPaso
  J.robin.comboPaso = paso + 1
  if J.robin.comboPaso > 3 then J.robin.comboPaso = 1 end
  J.robin.comboTimer = 0.9

  local anguloBase = math.atan2(dirY, dirX)
  local dano = J.robin.danoAtaque
  local rango, apertura, tipoCorte, avance

  if paso == 1 then
    tipoCorte = "corte_izq"; rango = 32; apertura = math.rad(70); avance = 10
  elseif paso == 2 then
    tipoCorte = "corte_der"; rango = 32; apertura = math.rad(70); avance = 10
  else
    tipoCorte = "corte_samurai"
    dano = dano * 1.5
    rango = 46; apertura = math.rad(60); avance = 15
  end

  -- Pequeno avance iaijutsu
  local Colisiones = require("src.sistemas.colisiones")
  local nx = J.robin.x + dirX * avance
  local ny = J.robin.y + dirY * avance
  if not Colisiones.circuloConMapa(nx, J.robin.y, J.robin.radio, J.salaActual.mapa) then
    J.robin.x = nx
  end
  if not Colisiones.circuloConMapa(J.robin.x, ny, J.robin.radio, J.salaActual.mapa) then
    J.robin.y = ny
  end

  -- Swing
  J.robin.swingLado = -(J.robin.swingLado or 1)
  J.robin.swingDur = 0.17
  J.robin.swingT = 0.17

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase, tipo = tipoCorte,
    vida = 0.20, duracion = 0.20,
  })

  local dirFinalX = math.cos(anguloBase)
  local dirFinalY = math.sin(anguloBase)

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif < apertura then
          local murio = e:recibirDanio(dano)
          if murio then
            J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
          else
            if paso == 3 and e.aplicarKnockback then
              e:aplicarKnockback(dirFinalX, dirFinalY, 120)
            end
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
        jf:recibirDanio(dano)
      end
    end
  end

  J.robin:gastarResistencia(J.robin.costeAtaque)
  J.robin.cooldownDisparo = J.robin.cooldownAtaque
  if sonidos.corte then sonidos.corte:stop() sonidos.corte:play()
  elseif sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 9) NYX-7 - ballesta de plasma
-- ============================================================

function J.atacarNyx(dirX, dirY)
  local p = J.poolFlechas:obtener()
  if not p then return end
  p:lanzar(J.robin.x, J.robin.y, dirX, dirY,
    340, J.robin.danoAtaque, false, "bala_plasma")
  cerrarAtaque(J.robin.costeAtaque, J.robin.cooldownAtaque, "disparo")
end

-- ============================================================
-- 10) LYRA - lira (nota musical + sinfonia belica aplicada)
-- ============================================================

function J.atacarLyra(dirX, dirY)
  local p = J.poolFlechas:obtener()
  if not p then return end

  local multDano = 1.0
  local multCadencia = 1.0
  if J.robin.sinfoniaTimer and J.robin.sinfoniaTimer > 0 then
    multDano = J.robin.sinfoniaDano or 1.0
    multCadencia = J.robin.sinfoniaCadencia or 1.0
  end

  local dano = J.robin.danoAtaque * multDano

  p:lanzar(J.robin.x, J.robin.y, dirX, dirY,
    240, dano, false, "nota_musical")

  J.robin:gastarResistencia(J.robin.costeAtaque)
  J.robin.cooldownDisparo = J.robin.cooldownAtaque / multCadencia
  if sonidos.disparo then sonidos.disparo:stop() sonidos.disparo:play() end
end

-- ============================================================
-- 11) THORIN - martillo sagrado
-- ============================================================

function J.atacarMartillo(dirX, dirY)
  local r = J.robin
  local ang = math.atan2(dirY, dirX)

  r.swingLado = -(r.swingLado or 1)
  r.swingDur = 0.26
  r.swingT = 0.26

  local ix, iy = r.x + dirX * 34, r.y + dirY * 34

  table.insert(J.cortes, {
    x = ix, y = iy, angulo = 0,
    tipo = "impacto_martillo",
    radio = 30, vida = 0.32, duracion = 0.32,
  })

  local h1 = danioCono(r.x, r.y, ang, 42, math.rad(70), r.danoAtaque, 190, 0.4)
  local h2 = danioCirculo(ix, iy, 24, r.danoAtaque * 0.5, 120)

  cerrarAtaque(r.costeAtaque, r.cooldownAtaque, "corte")
end

-- ============================================================
-- 12) REX - rifle de plasma (auto + sobrecarga)
-- ============================================================

function J.atacarRifle(dirX, dirY)
  local r = J.robin
  local ang = math.atan2(dirY, dirX)
  local sobre = (r.sobrecargaT or 0) > 0
  local n = sobre and 3 or 1
  local spread = sobre and math.rad(9) or math.rad(2.5)

  for i = 1, n do
    local p = J.poolFlechas:obtener()
    if p then
      local a = ang
      if sobre then
        a = ang + (i - 2) * spread
      else
        a = ang + (math.random() - 0.5) * spread
      end
      p:lanzar(r.x + math.cos(a) * 10, r.y + math.sin(a) * 10,
        math.cos(a), math.sin(a),
        340, r.danoAtaque, false, "bala")
    end
  end

  if not sobre then
    r:gastarResistencia(r.costeAtaque)
  else
    r.tiempoDesdeAtaque = 0
  end
  r.cooldownDisparo = r.cooldownAtaque * (sobre and 0.55 or 1)
  snd("disparo")
end

-- ============================================================
-- ROUTER PRINCIPAL
-- ============================================================

function J.dispararEnDireccion(dirX, dirY)
  local tipo = J.robin.tipoArma
  if tipo == "arco" then
    J.atacarArquero(dirX, dirY)
  elseif tipo == "grimorio" then
    J.atacarMago(dirX, dirY)
  elseif tipo == "espada" then
    J.atacarGuerrero(dirX, dirY)
  elseif tipo == "bumeran" then
    J.atacarCazador(dirX, dirY)
  elseif tipo == "dagas" then
    J.atacarShadow(dirX, dirY)
  elseif tipo == "lanza" then
    J.atacarValquiria(dirX, dirY)
  elseif tipo == "revolver" then
    J.atacarPistolero(dirX, dirY)
  elseif tipo == "katana" then
    J.atacarSamurai(dirX, dirY)
  elseif tipo == "ballesta_plasma" then
    J.atacarNyx(dirX, dirY)
  elseif tipo == "lira" then
    J.atacarLyra(dirX, dirY)
  elseif tipo == "martillo" then
    J.atacarMartillo(dirX, dirY)
  elseif tipo == "rifle" then
    J.atacarRifle(dirX, dirY)
  end
end

return J