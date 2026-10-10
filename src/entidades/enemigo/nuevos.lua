-- ============================================================
-- ENEMIGOS DE LOS BIOMAS NUEVOS
-- Arquetipos: embestidor, torreta, kiter, aplastador, kamikaze,
--             blink, rayo, duelista
-- Los disparos se encolan en e.disparos y los consume juego/update.lua
-- ============================================================
local E            = require("src.entidades.enemigo.base")
local Colisiones   = require("src.sistemas.colisiones")
local datosEnemigos = require("src.datos.enemigos")
local Juice        = require("src.sistemas.juice")

E.registroIA = E.registroIA or {}
E.registroDibujo = E.registroDibujo or {}

local PI = math.pi
local atan2 = math.atan2 or math.atan

-- ------------------------------------------------------------
-- CONSTRUCTOR GENERICO
-- ------------------------------------------------------------
function E.nuevoDeBioma(tipo, x, y)
  local datos = datosEnemigos[tipo]
  if not datos or not datos.arquetipo then return nil end
  local e = setmetatable({}, E)
  e.tipo = tipo
  e.datos = datos
  e.x, e.y = x, y
  e.hpMax = datos.hpMax
  e.hp = datos.hpMax
  e.radio = datos.radio
  e.vivo = true
  e.flashDanio = 0
  e.ultimaDirX, e.ultimaDirY = 1, 0
  e.animTimer = math.random() * 10
  e.estado = "idle"
  e.timer = 0.3 + math.random() * 0.8
  e.cd = (datos.cooldown or 2) * (0.3 + math.random() * 0.7)
  e.disparos = {}
  e.dirX, e.dirY = 1, 0
  e.strafeSigno = (math.random() > 0.5) and 1 or -1
  e.strafeTimer = 0
  e.alpha = 1
  e.golpeActual = 0
  e.contactoDano = nil
  e:initStatus()
  return e
end

-- ------------------------------------------------------------
-- HELPERS
-- ------------------------------------------------------------
local function distancia(e, o)
  local dx, dy = o.x - e.x, o.y - e.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end
  return d, dx / d, dy / d
end

local function mover(e, mx, my, vel, dt, mapa)
  local bx, by = false, false
  local nx = e.x + mx * vel * dt
  if not Colisiones.circuloConMapa(nx, e.y, e.radio, mapa) then e.x = nx else bx = true end
  local ny = e.y + my * vel * dt
  if not Colisiones.circuloConMapa(e.x, ny, e.radio, mapa) then e.y = ny else by = true end
  return bx, by
end

local function danoMult(e) return e.danoMultiplicador or 1 end
local function velMult(e) return e.velocidadMultiplicador or 1 end

local function encolarDisparo(e, x, y, dx, dy, vel, dano, tipo)
  e.disparos[#e.disparos + 1] = {
    x = x, y = y, dx = dx, dy = dy, vel = vel, dano = dano, tipo = tipo,
  }
end

local function abanico(e, objetivo, cantidad, aperturaGrados, vel, dano, tipo)
  local ang = atan2(objetivo.y - e.y, objetivo.x - e.x)
  local ap = math.rad(aperturaGrados or 0)
  for i = 1, cantidad do
    local a = ang
    if cantidad > 1 then
      a = ang - ap / 2 + ap * (i - 1) / (cantidad - 1)
    end
    encolarDisparo(e, e.x, e.y, math.cos(a), math.sin(a), vel, dano, tipo)
  end
end

local function dentroDeCono(e, objetivo, ang, apertura, rango)
  local dx, dy = objetivo.x - e.x, objetivo.y - e.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d > rango + objetivo.radio then return false end
  local a = atan2(dy, dx)
  local dif = math.abs(((a - ang + PI) % (PI * 2)) - PI)
  return dif < apertura
end

local function sacudirLigero(mag) Juice.sacudir(mag, 0.18) end

-- Punto aleatorio libre alrededor del objetivo
local function puntoLibreAlrededor(e, objetivo, dMin, dMax, mapa)
  for _ = 1, 14 do
    local ang = math.random() * PI * 2
    local dist = dMin + math.random() * (dMax - dMin)
    local px = objetivo.x + math.cos(ang) * dist
    local py = objetivo.y + math.sin(ang) * dist
    if not Colisiones.circuloConMapa(px, py, e.radio + 2, mapa) then
      return px, py
    end
  end
  return nil
end

-- ============================================================
-- ARQUETIPO: EMBESTIDOR (lobo de sombra, yeti)
-- ============================================================
E.registroIA.embestidor = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "merodeo" then
    e.estado = "merodeo"
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local ring = d.alcanceEmbestida * 0.55
    local mx, my
    if dist > ring + 25 then
      mx, my = ux, uy
    elseif dist < ring - 25 then
      mx, my = -ux, -uy
    else
      e.strafeTimer = e.strafeTimer - dt
      if e.strafeTimer <= 0 then
        e.strafeTimer = 0.8 + math.random() * 0.8
        e.strafeSigno = -e.strafeSigno
      end
      mx, my = -uy * e.strafeSigno, ux * e.strafeSigno
    end
    mover(e, mx, my, d.velocidad * velMult(e), dt, mapa)

    if e.cd <= 0 and dist < d.alcanceEmbestida + 50 then
      e.estado = "aviso"
      e.timer = d.aviso
      e.dirX, e.dirY = ux, uy
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    -- sigue al jugador y fija la direccion justo antes de embestir
    if e.timer > 0.14 then
      e.dirX, e.dirY = ux, uy
    end
    e.ultimaDirX, e.ultimaDirY = e.dirX, e.dirY
    if e.timer <= 0 then
      e.estado = "embestida"
      e.timer = d.duracionEmbestida
      e.contactoDano = d.danoEmbestida
      Juice.chispas(e.x, e.y, 6, { 0.8, 0.8, 0.9 }, 60, 0.3)
    end

  elseif e.estado == "embestida" then
    e.timer = e.timer - dt
    local bx, by = mover(e, e.dirX, e.dirY, d.velEmbestida * velMult(e), dt, mapa)
    if math.random() < 0.5 then Juice.humo(e.x, e.y + 4, 1, { 0.7, 0.7, 0.75 }, 0.35) end
    if bx or by then
      e.contactoDano = nil
      e.estado = "recuperar"
      e.timer = d.descanso + (d.aturdeAlChocar or 0)
      if d.aturdeAlChocar then
        e:aplicarStun(d.aturdeAlChocar)
        Juice.chispas(e.x, e.y, 10, { 1, 1, 1 }, 90, 0.4)
        sacudirLigero(2)
      end
    elseif e.timer <= 0 then
      e.contactoDano = nil
      e.estado = "recuperar"
      e.timer = d.descanso
    end

  elseif e.estado == "recuperar" then
    e.contactoDano = nil
    e.timer = e.timer - dt
    if e.timer <= 0 then
      e.estado = "merodeo"
      e.cd = d.cooldown
    end
  end
end

-- ============================================================
-- ARQUETIPO: TORRETA (hongo toxico, cristal helado)
-- ============================================================
E.registroIA.torreta = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.ultimaDirX, e.ultimaDirY = ux, uy
  e.cd = e.cd - dt
  e.angulo = (e.angulo or 0) + dt * 0.8

  if e.estado == "idle" then
    if e.cd <= 0 and dist < d.alcance then
      e.estado = "aviso"
      e.timer = d.aviso
    end
  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    if e.timer <= 0 then
      local dano = d.danoProyectil * danoMult(e)
      if d.modo == "radial" then
        local base = math.random() * PI * 2
        for i = 1, d.cantidad do
          local a = base + (i - 1) * PI * 2 / d.cantidad
          encolarDisparo(e, e.x, e.y, math.cos(a), math.sin(a), d.velProyectil, dano, d.tipoProyectil)
        end
      else
        abanico(e, objetivo, d.cantidad, d.apertura, d.velProyectil, dano, d.tipoProyectil)
      end
      e.estado = "idle"
      e.cd = d.cooldown
      e.retroceso = 0.2
    end
  end
  if e.retroceso and e.retroceso > 0 then e.retroceso = e.retroceso - dt end
end

-- ============================================================
-- ARQUETIPO: KITER (arana venenosa, salamandra)
-- ============================================================
E.registroIA.kiter = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "mover" then
    e.estado = "mover"
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local mx, my
    if dist < d.rangoMinimo then
      mx, my = -ux, -uy
    elseif dist > d.rangoIdeal + 40 then
      mx, my = ux, uy
    else
      e.strafeTimer = e.strafeTimer - dt
      if e.strafeTimer <= 0 then
        e.strafeTimer = 0.7 + math.random() * 0.9
        e.strafeSigno = -e.strafeSigno
      end
      mx, my = -uy * e.strafeSigno, ux * e.strafeSigno
    end
    mover(e, mx, my, d.velocidad * velMult(e), dt, mapa)

    if e.cd <= 0 and dist < d.rangoDisparo then
      e.estado = "aviso"
      e.timer = d.aviso
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    e.ultimaDirX, e.ultimaDirY = ux, uy
    if e.timer <= 0 then
      abanico(e, objetivo, d.cantidad, d.apertura, d.velProyectil,
        d.danoProyectil * danoMult(e), d.tipoProyectil)
      e.estado = "mover"
      e.cd = d.cooldown
    end
  end
end

-- ============================================================
-- ARQUETIPO: APLASTADOR (golem de lava)
-- ============================================================
E.registroIA.aplastador = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "avanzar" then
    e.estado = "avanzar"
    e.ultimaDirX, e.ultimaDirY = ux, uy
    mover(e, ux, uy, d.velocidad * velMult(e), dt, mapa)
    if dist < d.rangoAtaque and e.cd <= 0 then
      e.estado = "aviso"
      e.timer = d.aviso
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    if e.timer <= 0 then
      -- impacto
      Juice.explosion(e.x, e.y + 6, { 1.0, 0.45, 0.10 }, 1.3)
      sacudirLigero(3)
      local dx, dy = objetivo.x - e.x, objetivo.y - e.y
      if math.sqrt(dx * dx + dy * dy) < d.radioImpacto + objetivo.radio then
        objetivo:recibirDanio(d.danoAtaque * danoMult(e))
      end
      e.estado = "recuperar"
      e.timer = d.descanso
    end

  elseif e.estado == "recuperar" then
    e.timer = e.timer - dt
    if e.timer <= 0 then
      e.estado = "avanzar"
      e.cd = d.cooldown
    end
  end
end

-- ============================================================
-- ARQUETIPO: KAMIKAZE (espiritu de fuego)
-- ============================================================
E.registroIA.kamikaze = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)

  if e.estado == "idle" or e.estado == "volar" then
    e.estado = "volar"
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local t = e.animTimer * 3
    local mx = ux + math.cos(t) * 0.7
    local my = uy + math.sin(t * 1.3) * 0.7
    local m = math.sqrt(mx * mx + my * my)
    if m > 0.001 then mx, my = mx / m, my / m end
    local vel = (dist < 120) and d.velCarga or d.velocidad
    mover(e, mx, my, vel * velMult(e), dt, mapa)
    if dist < d.distanciaActivar then
      e.estado = "aviso"
      e.timer = d.aviso
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    -- sigue acercandose despacio
    mover(e, ux, uy, d.velocidad * 0.35 * velMult(e), dt, mapa)
    if e.timer <= 0 then
      Juice.explosion(e.x, e.y, { 1.0, 0.55, 0.15 }, 1.1)
      sacudirLigero(2.5)
      local dx, dy = objetivo.x - e.x, objetivo.y - e.y
      if math.sqrt(dx * dx + dy * dy) < d.radioExplosion + objetivo.radio then
        objetivo:recibirDanio(d.danoExplosion * danoMult(e))
      end
      e.vivo = false
    end
  end
end

-- ============================================================
-- ARQUETIPO: BLINK (espectro de escarcha, acechador del vacio)
-- ============================================================
E.registroIA.blink = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "flotar" then
    e.estado = "flotar"
    e.alpha = 1
    e.intangible = false
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local ideal = (d.distanciaMin + d.distanciaMax) / 2
    local mx, my = 0, 0
    if dist > ideal + 30 then mx, my = ux, uy
    elseif dist < ideal - 30 then mx, my = -ux, -uy end
    mover(e, mx, my, d.velocidad * velMult(e), dt, mapa)
    if e.cd <= 0 then
      e.estado = "desvanecer"
      e.timer = 0.35
    end

  elseif e.estado == "desvanecer" then
    e.timer = e.timer - dt
    e.alpha = math.max(0, e.timer / 0.35)
    if e.alpha < 0.5 then e.intangible = true end
    if e.timer <= 0 then
      local px, py = puntoLibreAlrededor(e, objetivo, d.distanciaMin, d.distanciaMax, mapa)
      if px then
        Juice.chispas(e.x, e.y, 8, { 0.7, 0.6, 1.0 }, 60, 0.4)
        e.x, e.y = px, py
      end
      e.estado = "aparecer"
      e.timer = 0.25
    end

  elseif e.estado == "aparecer" then
    e.timer = e.timer - dt
    e.alpha = 1 - math.max(0, e.timer / 0.25)
    e.ultimaDirX, e.ultimaDirY = ux, uy
    if e.timer <= 0 then
      e.intangible = false
      e.alpha = 1
      e.estado = "aviso"
      e.timer = d.aviso
      e.dirX, e.dirY = ux, uy
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    if e.timer > 0.12 then e.dirX, e.dirY = ux, uy end
    e.ultimaDirX, e.ultimaDirY = e.dirX, e.dirY
    if e.timer <= 0 then
      if d.modoAtaque == "disparo" then
        abanico(e, objetivo, d.cantidad, d.apertura, d.velProyectil,
          d.danoProyectil * danoMult(e), d.tipoProyectil)
      else
        local ang = atan2(e.dirY, e.dirX)
        Juice.chispas(e.x + e.dirX * 20, e.y + e.dirY * 20, 8, { 0.8, 0.5, 1.0 }, 100, 0.3)
        if dentroDeCono(e, objetivo, ang, math.rad(d.aperturaTajo), d.rangoTajo) then
          objetivo:recibirDanio(d.danoAtaque * danoMult(e))
        end
        e.tajoVisual = 0.2
        e.tajoAng = ang
      end
      e.estado = "flotar"
      e.cd = d.cooldown
    end
  end
  if e.tajoVisual and e.tajoVisual > 0 then e.tajoVisual = e.tajoVisual - dt end
end

-- ============================================================
-- ARQUETIPO: RAYO (ojo del vacio)
-- ============================================================
E.registroIA.rayo = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "flotar" then
    e.estado = "flotar"
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local mx, my = 0, 0
    if dist > d.distanciaIdeal + 40 then mx, my = ux, uy
    elseif dist < d.distanciaIdeal - 40 then mx, my = -ux, -uy
    else mx, my = -uy * e.strafeSigno, ux * e.strafeSigno end
    mover(e, mx, my, d.velocidad * velMult(e), dt, mapa)
    if e.cd <= 0 then
      e.estado = "aviso"
      e.timer = d.aviso
      e.dirX, e.dirY = ux, uy
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    if e.timer > 0.28 then
      -- gira lentamente hacia el jugador
      local a0 = atan2(e.dirY, e.dirX)
      local a1 = atan2(uy, ux)
      local dif = ((a1 - a0 + PI) % (PI * 2)) - PI
      local paso = 2.4 * dt
      if dif > paso then dif = paso elseif dif < -paso then dif = -paso end
      a0 = a0 + dif
      e.dirX, e.dirY = math.cos(a0), math.sin(a0)
    end
    e.ultimaDirX, e.ultimaDirY = e.dirX, e.dirY
    if e.timer <= 0 then
      e.estado = "disparo"
      e.timer = d.duracionRayo
      e.rayoGolpeo = false
      sacudirLigero(1.5)
    end

  elseif e.estado == "disparo" then
    e.timer = e.timer - dt
    if not e.rayoGolpeo then
      -- distancia del jugador al segmento del rayo
      local sx, sy = e.dirX * d.largoRayo, e.dirY * d.largoRayo
      local px, py = objetivo.x - e.x, objetivo.y - e.y
      local t = (px * sx + py * sy) / (sx * sx + sy * sy)
      if t < 0 then t = 0 elseif t > 1 then t = 1 end
      local qx, qy = sx * t - px, sy * t - py
      if math.sqrt(qx * qx + qy * qy) < d.anchoRayo / 2 + objetivo.radio then
        e.rayoGolpeo = true
        objetivo:recibirDanio(d.danoRayo * danoMult(e))
      end
    end
    if e.timer <= 0 then
      e.estado = "flotar"
      e.cd = d.cooldown
    end
  end
end

-- ============================================================
-- ARQUETIPO: DUELISTA (caballero del vacio) - estilo soulslike
--   guardia alta al acercarse (reduce dano) -> combo telegrafiado
--   -> recuperacion (ventana de castigo)
-- ============================================================
E.registroIA.duelista = function(e, dt, mapa, objetivo)
  local d = e.datos
  local dist, ux, uy = distancia(e, objetivo)
  e.cd = e.cd - dt

  if e.estado == "idle" or e.estado == "acercar" then
    e.estado = "acercar"
    e.reduccionDanio = d.reduccionGuardia
    e.ultimaDirX, e.ultimaDirY = ux, uy
    local mx, my = ux, uy
    if dist < d.rangoAtaque * 0.8 then mx, my = 0, 0 end
    -- pequeno strafe para parecer vivo
    e.strafeTimer = e.strafeTimer - dt
    if e.strafeTimer <= 0 then
      e.strafeTimer = 0.8 + math.random()
      e.strafeSigno = -e.strafeSigno
    end
    if dist < 90 and dist >= d.rangoAtaque * 0.8 then
      mx = mx * 0.6 - uy * 0.4 * e.strafeSigno
      my = my * 0.6 + ux * 0.4 * e.strafeSigno
    end
    mover(e, mx, my, d.velocidadGuardia * velMult(e), dt, mapa)
    if dist < d.rangoAtaque + 6 and e.cd <= 0 then
      e.estado = "aviso"
      e.golpeActual = 1
      e.timer = d.aviso
      e.dirX, e.dirY = ux, uy
      e.reduccionDanio = 0.15
    end

  elseif e.estado == "aviso" then
    e.timer = e.timer - dt
    if e.timer > 0.1 then e.dirX, e.dirY = ux, uy end
    e.ultimaDirX, e.ultimaDirY = e.dirX, e.dirY
    if e.timer <= 0 then
      local ang = atan2(e.dirY, e.dirX)
      local ultimo = (e.golpeActual >= d.golpesCombo)
      local rango = ultimo and (d.rangoAtaque + 22) or d.rangoAtaque
      local ap = math.rad(ultimo and d.aperturaTajo * 0.5 or d.aperturaTajo)
      local dano = d.danoAtaque * (ultimo and 1.5 or 1) * danoMult(e)
      -- pequeno avance con el tajo
      mover(e, e.dirX, e.dirY, 260, 0.06, mapa)
      if dentroDeCono(e, objetivo, ang, ap, rango) then
        objetivo:recibirDanio(dano)
      end
      Juice.chispas(e.x + e.dirX * 22, e.y + e.dirY * 22, 6, { 0.8, 0.5, 1.0 }, 100, 0.25)
      e.tajoVisual = 0.2
      e.tajoAng = ang
      e.tajoUltimo = ultimo
      if ultimo then
        e.estado = "recuperar"
        e.timer = d.recuperacion
        e.reduccionDanio = 0
      else
        e.golpeActual = e.golpeActual + 1
        e.timer = d.aviso * 0.8
        e.dirX, e.dirY = ux, uy
      end
    end

  elseif e.estado == "recuperar" then
    e.reduccionDanio = 0
    e.timer = e.timer - dt
    if e.timer <= 0 then
      e.estado = "acercar"
      e.cd = d.cooldown
    end
  end
  if e.tajoVisual and e.tajoVisual > 0 then e.tajoVisual = e.tajoVisual - dt end
end

-- ============================================================
-- DIBUJO
-- ============================================================
local function col(e, r, g, b)
  if e.flashDanio > 0 then
    love.graphics.setColor(1, 1, 1)
  else
    love.graphics.setColor(r, g, b, e.alpha or 1)
  end
end

local function sombraSuelo(e, ancho)
  love.graphics.setColor(0, 0, 0, 0.30 * (e.alpha or 1))
  love.graphics.ellipse("fill", e.x, e.y + e.radio * 0.9, ancho, ancho * 0.32)
end

local function telegrafoCirculo(x, y, r, k, r0, g0, b0)
  love.graphics.setColor(r0 or 1, g0 or 0.3, b0 or 0.2, 0.12 + 0.18 * k)
  love.graphics.circle("fill", x, y, r)
  love.graphics.setColor(r0 or 1, g0 or 0.35, b0 or 0.25, 0.55 + 0.35 * k)
  love.graphics.circle("line", x, y, r)
  love.graphics.setColor(r0 or 1, g0 or 0.35, b0 or 0.25, 0.35)
  love.graphics.circle("fill", x, y, r * k)
end

local function telegrafoCono(x, y, ang, ap, rango, k, r0, g0, b0)
  love.graphics.setColor(r0 or 1, g0 or 0.3, b0 or 0.3, 0.12 + 0.2 * k)
  love.graphics.arc("fill", x, y, rango, ang - ap, ang + ap)
  love.graphics.setColor(r0 or 1, g0 or 0.4, b0 or 0.4, 0.7)
  love.graphics.arc("line", "open", x, y, rango, ang - ap, ang + ap)
  love.graphics.setColor(r0 or 1, g0 or 0.4, b0 or 0.4, 0.4)
  love.graphics.arc("fill", x, y, rango * k, ang - ap, ang + ap)
end

local function progresoAviso(e)
  local t = e.datos.aviso or 0.5
  return math.max(0, math.min(1, 1 - (e.timer or 0) / t))
end

local function ojos(e, cx, cy, sep, r, rr, gg, bb)
  love.graphics.setColor(rr, gg, bb, e.alpha or 1)
  love.graphics.circle("fill", cx - sep, cy, r)
  love.graphics.circle("fill", cx + sep, cy, r)
  love.graphics.setColor(1, 1, 1, 0.8 * (e.alpha or 1))
  love.graphics.circle("fill", cx - sep - r * 0.3, cy - r * 0.3, r * 0.35)
  love.graphics.circle("fill", cx + sep - r * 0.3, cy - r * 0.3, r * 0.35)
end

-- ---------- LOBO DE SOMBRA ----------
E.registroDibujo.lobo_sombra = function(e)
  sombraSuelo(e, 10)
  local ang = atan2(e.ultimaDirY, e.ultimaDirX)
  local agachado = (e.estado == "aviso")
  local k = progresoAviso(e)
  love.graphics.push()
  love.graphics.translate(e.x, e.y)
  love.graphics.rotate(ang)
  if e.estado == "embestida" then
    for i = 1, 3 do
      love.graphics.setColor(0.3, 0.25, 0.5, 0.12 * (4 - i))
      love.graphics.ellipse("fill", -i * 7, 0, 10, 4)
    end
  end
  local corre = (e.estado == "embestida") and 14 or (e.estado == "merodeo" and 8 or 2)
  local pata = math.sin(e.animTimer * corre) * 2.5
  -- patas
  col(e, 0.10, 0.09, 0.16)
  love.graphics.rectangle("fill", -6 + pata, 2, 2, 5)
  love.graphics.rectangle("fill", 4 - pata, 2, 2, 5)
  love.graphics.rectangle("fill", -3 - pata, 3, 2, 4)
  love.graphics.rectangle("fill", 7 + pata, 3, 2, 4)
  -- cola
  col(e, 0.14, 0.12, 0.22)
  love.graphics.polygon("fill", -9, -1, -17, -4 + math.sin(e.animTimer * 6) * 2, -9, 3)
  -- cuerpo
  local alto = agachado and 3.8 or 5
  col(e, 0.20, 0.18, 0.30)
  love.graphics.ellipse("fill", 0, 0, 10, alto)
  col(e, 0.28, 0.25, 0.40)
  love.graphics.ellipse("fill", 1, -1.5, 7, alto * 0.45)
  -- cabeza
  col(e, 0.22, 0.20, 0.33)
  love.graphics.polygon("fill", 6, -4, 15, -1, 15, 3, 6, 5)
  love.graphics.polygon("fill", 7, -4, 9, -8, 11, -4)
  love.graphics.polygon("fill", 11, -4, 13, -7, 14, -3)
  -- ojos
  local glow = 0.7 + 0.3 * k
  love.graphics.setColor(1, 0.75 - 0.4 * k, 0.15, glow)
  love.graphics.circle("fill", 11, -1.5, 1.3 + k * 0.7)
  love.graphics.setColor(1, 0.9, 0.5, 0.25 + 0.3 * k)
  love.graphics.circle("fill", 11, -1.5, 4 + k * 3)
  love.graphics.pop()
end

-- ---------- HONGO TOXICO ----------
E.registroDibujo.hongo_toxico = function(e)
  sombraSuelo(e, 8)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  local hincha = 1 + k * 0.25 + math.sin(e.animTimer * 2) * 0.04
  local x, y = e.x, e.y
  love.graphics.setColor(0.55, 0.85, 0.20, 0.08 + k * 0.15)
  love.graphics.circle("fill", x, y, 16 + k * 10)
  col(e, 0.82, 0.78, 0.62)
  love.graphics.rectangle("fill", x - 3, y - 1, 6, 10, 2)
  col(e, 0.50, 0.62, 0.22)
  love.graphics.ellipse("fill", x, y - 3, 10 * hincha, 7 * hincha)
  col(e, 0.65, 0.80, 0.30)
  love.graphics.ellipse("fill", x - 1, y - 5, 7.5 * hincha, 4 * hincha)
  if e.flashDanio <= 0 then
    love.graphics.setColor(0.95, 0.95, 0.60, 0.9)
    love.graphics.circle("fill", x - 4, y - 4, 1.4)
    love.graphics.circle("fill", x + 3, y - 6, 1.1)
    love.graphics.circle("fill", x + 5, y - 2, 1.2)
    love.graphics.setColor(0.10, 0.12, 0.05)
    love.graphics.circle("fill", x - 2, y + 3, 1)
    love.graphics.circle("fill", x + 2, y + 3, 1)
  end
  if math.random() < 0.06 then Juice.humo(x, y - 8, 1, { 0.6, 0.85, 0.3 }, 0.8) end
end

-- ---------- ARANA VENENOSA ----------
E.registroDibujo.arana_venenosa = function(e)
  sombraSuelo(e, 8)
  local ang = atan2(e.ultimaDirY, e.ultimaDirX)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  love.graphics.push()
  love.graphics.translate(e.x, e.y)
  love.graphics.rotate(ang)
  local corre = (e.estado == "mover") and 12 or 3
  col(e, 0.10, 0.12, 0.08)
  love.graphics.setLineWidth(1.5)
  for i = 0, 3 do
    local f = math.sin(e.animTimer * corre + i * 1.4) * 2
    local base = -4 + i * 3.3
    love.graphics.line(base, -2, base + 2, -8 + f, base + 5, -9 + f)
    love.graphics.line(base, 2, base + 2, 8 - f, base + 5, 9 - f)
  end
  love.graphics.setLineWidth(1)
  col(e, 0.16, 0.20, 0.12)
  love.graphics.ellipse("fill", -4, 0, 7, 5.5)
  love.graphics.setColor(0.55 + k * 0.3, 0.85, 0.20, 0.9)
  love.graphics.circle("fill", -4, 0, 2 + k * 1.5)
  col(e, 0.22, 0.28, 0.16)
  love.graphics.ellipse("fill", 4, 0, 4.5, 4)
  love.graphics.setColor(1, 0.3, 0.25, e.alpha or 1)
  love.graphics.circle("fill", 7, -1.5, 0.9)
  love.graphics.circle("fill", 7, 1.5, 0.9)
  love.graphics.setColor(0.85, 0.85, 0.7)
  love.graphics.polygon("fill", 8, -1, 11, -0.5, 8, 0)
  love.graphics.polygon("fill", 8, 1, 11, 0.5, 8, 0)
  love.graphics.pop()
end

-- ---------- SALAMANDRA ----------
E.registroDibujo.salamandra = function(e)
  sombraSuelo(e, 10)
  local ang = atan2(e.ultimaDirY, e.ultimaDirX)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  love.graphics.push()
  love.graphics.translate(e.x, e.y)
  love.graphics.rotate(ang)
  local ond = math.sin(e.animTimer * 7)
  -- cola ondulante
  col(e, 0.65, 0.22, 0.10)
  love.graphics.polygon("fill", -6, -3, -18, ond * 4, -6, 3)
  col(e, 0.85, 0.45, 0.12)
  love.graphics.polygon("fill", -12, -1, -18, ond * 4, -12, 1)
  -- patas
  col(e, 0.45, 0.15, 0.08)
  local pata = math.sin(e.animTimer * 9) * 2
  love.graphics.rectangle("fill", -4 + pata, -7, 3, 3)
  love.graphics.rectangle("fill", -4 - pata, 4, 3, 3)
  love.graphics.rectangle("fill", 4 - pata, -7, 3, 3)
  love.graphics.rectangle("fill", 4 + pata, 4, 3, 3)
  -- cuerpo
  col(e, 0.78, 0.28, 0.12)
  love.graphics.ellipse("fill", 0, 0, 10, 5)
  col(e, 0.95, 0.62, 0.20)
  love.graphics.ellipse("fill", 1, 1.5, 7, 2.2)
  -- manchas de lava
  love.graphics.setColor(1, 0.85, 0.30, 0.8)
  love.graphics.circle("fill", -3, -2, 1)
  love.graphics.circle("fill", 2, -2.5, 1)
  -- cabeza
  col(e, 0.82, 0.30, 0.12)
  love.graphics.polygon("fill", 8, -4, 16, -2, 16, 2, 8, 4)
  love.graphics.setColor(1, 0.9, 0.3)
  love.graphics.circle("fill", 11, -2.5, 1.1)
  -- boca ardiendo
  love.graphics.setColor(1, 0.55, 0.12, 0.3 + k * 0.7)
  love.graphics.circle("fill", 16, 0, 2 + k * 5)
  love.graphics.setColor(1, 0.95, 0.5, k)
  love.graphics.circle("fill", 16, 0, 1 + k * 2)
  love.graphics.pop()
end

-- ---------- GOLEM DE LAVA ----------
E.registroDibujo.golem_menor = function(e)
  local d = e.datos
  sombraSuelo(e, 14)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  if e.estado == "aviso" then
    telegrafoCirculo(e.x, e.y, d.radioImpacto, k, 1.0, 0.45, 0.1)
  end
  local x, y = e.x, e.y
  local paso = (e.estado == "avanzar") and math.sin(e.animTimer * 4) * 1.5 or 0
  local alza = k * 8
  -- piernas
  col(e, 0.22, 0.15, 0.14)
  love.graphics.rectangle("fill", x - 8, y + 4 + paso, 6, 8)
  love.graphics.rectangle("fill", x + 2, y + 4 - paso, 6, 8)
  -- brazos
  col(e, 0.30, 0.20, 0.18)
  love.graphics.rectangle("fill", x - 15, y - 8 - alza, 6, 15, 2)
  love.graphics.rectangle("fill", x + 9, y - 8 - alza, 6, 15, 2)
  col(e, 0.38, 0.26, 0.22)
  love.graphics.circle("fill", x - 12, y + 7 - alza, 4)
  love.graphics.circle("fill", x + 12, y + 7 - alza, 4)
  -- torso
  col(e, 0.26, 0.18, 0.16)
  love.graphics.polygon("fill", x - 11, y + 5, x - 9, y - 11, x + 9, y - 11, x + 11, y + 5)
  col(e, 0.36, 0.25, 0.22)
  love.graphics.polygon("fill", x - 9, y - 11, x - 2, y - 11, x - 3, y + 5, x - 11, y + 5)
  -- grietas de lava
  local a = 0.55 + 0.35 * math.sin(e.animTimer * 3) + k * 0.3
  love.graphics.setColor(1, 0.45, 0.10, math.min(1, a))
  love.graphics.line(x + 1, y - 9, x + 3, y - 3, x - 1, y + 1, x + 2, y + 4)
  love.graphics.line(x + 6, y - 6, x + 5, y - 1)
  love.graphics.setColor(1, 0.85, 0.35, math.min(1, a) * 0.7)
  love.graphics.circle("fill", x + 1, y - 3, 2.2)
  -- cabeza
  col(e, 0.32, 0.22, 0.20)
  love.graphics.rectangle("fill", x - 5, y - 18, 10, 8, 2)
  love.graphics.setColor(1, 0.7, 0.2)
  love.graphics.rectangle("fill", x - 3.5, y - 15, 2.5, 1.8)
  love.graphics.rectangle("fill", x + 1, y - 15, 2.5, 1.8)
end

-- ---------- ESPIRITU DE FUEGO ----------
E.registroDibujo.espiritu_fuego = function(e)
  local d = e.datos
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.ellipse("fill", e.x, e.y + 11, 5, 1.8)
  if e.estado == "aviso" then
    telegrafoCirculo(e.x, e.y, d.radioExplosion, k, 1.0, 0.45, 0.1)
  end
  local t = e.animTimer
  local fl = 0.9 + 0.1 * math.sin(t * 16)
  local y = e.y + math.sin(t * 5) * 2 - 3
  local r = (e.flashDanio > 0) and 1 or 0
  love.graphics.setColor(1, 0.35 + r, 0.05 + r, 0.25 + k * 0.2)
  love.graphics.circle("fill", e.x, y, (11 + k * 5) * fl)
  love.graphics.setColor(1, 0.45 + r * 0.5, 0.08 + r, 0.8)
  love.graphics.polygon("fill", e.x - 6, y + 2, e.x - 3, y - 10 - math.sin(t * 12) * 2,
    e.x, y - 4, e.x + 3, y - 12 + math.sin(t * 10) * 2, e.x + 6, y + 2, e.x, y + 8)
  love.graphics.setColor(1, 0.85, 0.35)
  love.graphics.circle("fill", e.x, y + 1, 4.5 * fl)
  love.graphics.setColor(1, 1, 0.85)
  love.graphics.circle("fill", e.x, y + 1.5, 2.2)
  love.graphics.setColor(0.2, 0.05, 0)
  love.graphics.circle("fill", e.x - 1.8, y + 0.5, 0.9)
  love.graphics.circle("fill", e.x + 1.8, y + 0.5, 0.9)
  if math.random() < 0.15 then Juice.chispas(e.x, y, 1, { 1, 0.6, 0.2 }, 20, 0.4) end
end

-- ---------- YETI ----------
E.registroDibujo.yeti = function(e)
  sombraSuelo(e, 13)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  local x, y = e.x, e.y
  local ang = atan2(e.ultimaDirY, e.ultimaDirX)
  local lado = (math.cos(ang) >= 0) and 1 or -1
  local paso = (e.estado == "merodeo" or e.estado == "embestida")
      and math.sin(e.animTimer * (e.estado == "embestida" and 14 or 6)) * 2 or 0
  local sh = (e.stunTimer > 0) and math.sin(e.animTimer * 30) * 1 or 0
  -- piernas
  col(e, 0.80, 0.86, 0.92)
  love.graphics.rectangle("fill", x - 7 + sh, y + 5 + paso, 6, 8, 2)
  love.graphics.rectangle("fill", x + 1 + sh, y + 5 - paso, 6, 8, 2)
  -- cuerpo (pelaje)
  col(e, 0.90, 0.94, 0.98)
  love.graphics.ellipse("fill", x + sh, y - 2, 12, 12)
  col(e, 0.78, 0.84, 0.92)
  love.graphics.ellipse("fill", x + sh - 3, y + 1, 7, 8)
  -- brazos
  local alza = k * 10 + ((e.estado == "embestida") and 6 or 0)
  col(e, 0.86, 0.91, 0.97)
  love.graphics.ellipse("fill", x - 12 + sh, y - 2 - alza, 4.5, 8)
  love.graphics.ellipse("fill", x + 12 + sh, y - 2 - alza, 4.5, 8)
  col(e, 0.40, 0.60, 0.78)
  love.graphics.circle("fill", x - 12 + sh, y + 4 - alza, 3)
  love.graphics.circle("fill", x + 12 + sh, y + 4 - alza, 3)
  -- cara
  col(e, 0.45, 0.65, 0.82)
  love.graphics.ellipse("fill", x + sh + lado, y - 9, 6, 5)
  love.graphics.setColor(1, 0.35 - k * 0.2, 0.25, 1)
  love.graphics.circle("fill", x + sh + lado - 2.5, y - 10, 1.3)
  love.graphics.circle("fill", x + sh + lado + 2.5, y - 10, 1.3)
  love.graphics.setColor(1, 1, 1)
  love.graphics.polygon("fill", x + sh + lado - 3, y - 6, x + sh + lado - 2, y - 3, x + sh + lado - 1, y - 6)
  love.graphics.polygon("fill", x + sh + lado + 1, y - 6, x + sh + lado + 2, y - 3, x + sh + lado + 3, y - 6)
  -- cuernos
  love.graphics.setColor(0.85, 0.82, 0.70)
  love.graphics.polygon("fill", x + sh - 6, y - 12, x + sh - 9, y - 18, x + sh - 3, y - 13)
  love.graphics.polygon("fill", x + sh + 6, y - 12, x + sh + 9, y - 18, x + sh + 3, y - 13)
  if e.estado == "aviso" then
    love.graphics.setColor(1, 0.3, 0.2, 0.25 + 0.4 * k)
    love.graphics.circle("line", x, y, 18 + k * 6)
  end
end

-- ---------- CRISTAL HELADO ----------
E.registroDibujo.cristal_helado = function(e)
  sombraSuelo(e, 9)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  local t = e.animTimer
  local x, y = e.x, e.y + math.sin(t * 2) * 1.5
  love.graphics.setColor(0.5, 0.8, 1.0, 0.10 + k * 0.2)
  love.graphics.circle("fill", x, y - 2, 16 + k * 6)
  -- fragmentos orbitando
  for i = 1, 3 do
    local a = t * 1.5 + i * 2.09
    local fx = x + math.cos(a) * 12
    local fy = y - 2 + math.sin(a) * 5
    love.graphics.setColor(0.7, 0.9, 1.0, 0.85)
    love.graphics.polygon("fill", fx, fy - 3, fx + 2, fy, fx, fy + 3, fx - 2, fy)
  end
  col(e, 0.40, 0.68, 0.90)
  love.graphics.polygon("fill", x - 7, y + 10, x - 4, y - 4, x, y - 14, x + 4, y - 4, x + 7, y + 10)
  col(e, 0.72, 0.92, 1.0)
  love.graphics.polygon("fill", x - 4, y - 4, x, y - 14, x, y + 10, x - 7, y + 10)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.line(x - 2, y - 6, x - 2, y + 6)
  love.graphics.setColor(1, 1, 1, 0.5 + k * 0.5)
  love.graphics.circle("fill", x + 1, y - 1, 2 + k * 2)
end

-- ---------- ESPECTRO DE ESCARCHA ----------
E.registroDibujo.fantasma_escarcha = function(e)
  local x, y = e.x, e.y + math.sin(e.animTimer * 3) * 2
  local al = e.alpha or 1
  love.graphics.setColor(0, 0, 0, 0.18 * al)
  love.graphics.ellipse("fill", e.x, e.y + 12, 6, 2)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  love.graphics.setColor(0.55, 0.80, 1.0, (0.10 + k * 0.2) * al)
  love.graphics.circle("fill", x, y, 18 + k * 5)
  local onda = math.sin(e.animTimer * 5)
  col(e, 0.62, 0.82, 0.98)
  love.graphics.polygon("fill", x - 7, y - 4, x + 7, y - 4, x + 9, y + 12 + onda,
    x + 4, y + 8, x, y + 13, x - 4, y + 8, x - 9, y + 12 - onda)
  love.graphics.setColor(0.85, 0.95, 1.0, 0.5 * al)
  love.graphics.polygon("fill", x - 4, y - 3, x, y - 3, x - 1, y + 9, x - 6, y + 9)
  col(e, 0.45, 0.65, 0.88)
  love.graphics.circle("fill", x, y - 8, 6)
  love.graphics.setColor(0.10, 0.18, 0.35, al)
  love.graphics.ellipse("fill", x, y - 8, 4, 4.5)
  love.graphics.setColor(0.6, 1.0, 1.0, al)
  love.graphics.circle("fill", x - 1.8, y - 8, 1)
  love.graphics.circle("fill", x + 1.8, y - 8, 1)
end

-- ---------- ACECHADOR DEL VACIO ----------
E.registroDibujo.acechador_vacio = function(e)
  local x, y = e.x, e.y
  local al = e.alpha or 1
  local d = e.datos
  love.graphics.setColor(0, 0, 0, 0.25 * al)
  love.graphics.ellipse("fill", x, y + 11, 6, 2)
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  if e.estado == "aviso" then
    telegrafoCono(x, y, atan2(e.dirY, e.dirX), math.rad(d.aperturaTajo), d.rangoTajo, k, 0.75, 0.35, 1.0)
  end
  local ond = math.sin(e.animTimer * 4)
  col(e, 0.10, 0.06, 0.16)
  love.graphics.polygon("fill", x - 5, y - 6, x + 5, y - 6, x + 7, y + 10 + ond, x + 2, y + 6, x, y + 11, x - 2, y + 6, x - 7, y + 10 - ond)
  col(e, 0.20, 0.12, 0.30)
  love.graphics.polygon("fill", x - 5, y - 6, x, y - 6, x - 1, y + 7, x - 6, y + 9)
  -- brazos largos con garras
  love.graphics.setColor(0.16, 0.09, 0.24, al)
  love.graphics.polygon("fill", x - 5, y - 5, x - 13, y + 3 + ond, x - 11, y + 5 + ond, x - 4, y)
  love.graphics.polygon("fill", x + 5, y - 5, x + 13, y + 3 - ond, x + 11, y + 5 - ond, x + 4, y)
  love.graphics.setColor(0.85, 0.6, 1.0, al)
  love.graphics.polygon("fill", x - 13, y + 3 + ond, x - 16, y + 7 + ond, x - 12, y + 5 + ond)
  love.graphics.polygon("fill", x + 13, y + 3 - ond, x + 16, y + 7 - ond, x + 12, y + 5 - ond)
  -- cabeza
  col(e, 0.14, 0.08, 0.22)
  love.graphics.circle("fill", x, y - 9, 5.5)
  ojos(e, x, y - 9, 2.2, 1.3, 0.85 + k * 0.15, 0.35, 1.0)
  if e.tajoVisual and e.tajoVisual > 0 then
    local a = e.tajoVisual / 0.2
    love.graphics.setColor(0.9, 0.6, 1.0, a)
    love.graphics.setLineWidth(3)
    love.graphics.arc("line", "open", e.x, e.y, d.rangoTajo * 0.8, e.tajoAng - 1, e.tajoAng + 1)
    love.graphics.setLineWidth(1)
  end
end

-- ---------- OJO DEL VACIO ----------
E.registroDibujo.ojo_del_vacio = function(e)
  local d = e.datos
  local x, y = e.x, e.y + math.sin(e.animTimer * 2.5) * 2
  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.ellipse("fill", e.x, e.y + 13, 8, 2.5)

  -- telegrafo / rayo
  if e.estado == "aviso" or e.estado == "disparo" then
    local ex = e.x + e.dirX * d.largoRayo
    local ey = e.y + e.dirY * d.largoRayo
    if e.estado == "aviso" then
      local k = progresoAviso(e)
      love.graphics.setColor(0.8, 0.4, 1.0, 0.2 + 0.5 * k)
      love.graphics.setLineWidth(1 + k * 2)
      love.graphics.line(e.x, e.y, ex, ey)
      love.graphics.setLineWidth(1)
    else
      local a = math.max(0, e.timer / d.duracionRayo)
      love.graphics.setColor(0.65, 0.25, 1.0, 0.45 * a + 0.2)
      love.graphics.setLineWidth(d.anchoRayo)
      love.graphics.line(e.x, e.y, ex, ey)
      love.graphics.setColor(0.95, 0.85, 1.0, 0.9)
      love.graphics.setLineWidth(d.anchoRayo * 0.4)
      love.graphics.line(e.x, e.y, ex, ey)
      love.graphics.setLineWidth(1)
    end
  end

  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  love.graphics.setColor(0.55, 0.20, 0.85, 0.15 + k * 0.2)
  love.graphics.circle("fill", x, y, 16 + k * 4)
  -- tentaculos
  love.graphics.setColor(0.25, 0.10, 0.38)
  for i = 1, 5 do
    local a = i * 1.26 + e.animTimer * 0.8
    local tx = x + math.cos(a) * 12
    local ty = y + 8 + math.abs(math.sin(a)) * 5
    love.graphics.line(x + math.cos(a) * 5, y + 5, tx, ty)
  end
  col(e, 0.92, 0.90, 0.95)
  love.graphics.circle("fill", x, y, 10)
  love.graphics.setColor(0.65, 0.25, 0.95)
  local lx = e.ultimaDirX * 3
  local ly = e.ultimaDirY * 3
  love.graphics.circle("fill", x + lx, y + ly, 5.5)
  love.graphics.setColor(0.05, 0.02, 0.10)
  love.graphics.circle("fill", x + lx * 1.2, y + ly * 1.2, 2.8 - k * 1.2)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("fill", x + lx - 1.5, y + ly - 1.5, 1)
  love.graphics.setColor(0.4, 0.15, 0.3, 0.6)
  love.graphics.setLineWidth(1)
  love.graphics.circle("line", x, y, 10)
end

-- ---------- CABALLERO DEL VACIO ----------
E.registroDibujo.caballero_vacio = function(e)
  local d = e.datos
  sombraSuelo(e, 10)
  local x, y = e.x, e.y
  local k = (e.estado == "aviso") and progresoAviso(e) or 0
  local ang = atan2(e.ultimaDirY, e.ultimaDirX)
  if e.estado == "aviso" then
    local ultimo = (e.golpeActual >= d.golpesCombo)
    telegrafoCono(x, y, atan2(e.dirY, e.dirX),
      math.rad(ultimo and d.aperturaTajo * 0.5 or d.aperturaTajo),
      ultimo and d.rangoAtaque + 22 or d.rangoAtaque, k, 0.8, 0.35, 1.0)
  end
  local guardia = (e.reduccionDanio or 0) > 0.4
  local paso = (e.estado == "acercar") and math.sin(e.animTimer * 7) * 1.5 or 0
  -- capa
  col(e, 0.20, 0.10, 0.30)
  love.graphics.polygon("fill", x - 8, y - 6, x + 8, y - 6, x + 11, y + 13 + math.sin(e.animTimer * 3) * 1.5, x - 11, y + 13)
  -- piernas
  col(e, 0.16, 0.14, 0.22)
  love.graphics.rectangle("fill", x - 5, y + 6 + paso, 4, 8)
  love.graphics.rectangle("fill", x + 1, y + 6 - paso, 4, 8)
  -- torso armadura
  col(e, 0.28, 0.26, 0.38)
  love.graphics.polygon("fill", x - 8, y - 7, x + 8, y - 7, x + 7, y + 7, x - 7, y + 7)
  col(e, 0.40, 0.38, 0.54)
  love.graphics.polygon("fill", x - 8, y - 7, x - 1, y - 7, x - 2, y + 7, x - 7, y + 7)
  love.graphics.setColor(0.75, 0.40, 1.0, 0.8 * (e.alpha or 1))
  love.graphics.circle("fill", x, y - 1, 1.8)
  -- yelmo
  col(e, 0.30, 0.28, 0.42)
  love.graphics.circle("fill", x, y - 11, 6)
  love.graphics.setColor(0.05, 0.02, 0.10)
  love.graphics.rectangle("fill", x - 4, y - 12, 8, 2.5)
  love.graphics.setColor(0.85, 0.5, 1.0)
  love.graphics.rectangle("fill", x - 3, y - 11.5, 2, 1.5)
  love.graphics.rectangle("fill", x + 1, y - 11.5, 2, 1.5)
  love.graphics.setColor(0.65, 0.3, 0.95)
  love.graphics.polygon("fill", x - 2, y - 16, x, y - 22 - k * 3, x + 2, y - 16)
  -- espada
  local alza = (e.estado == "aviso") and (-1.2 + k * 0.4) or 0.4
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(ang + alza)
  love.graphics.setColor(0.70, 0.55, 0.95, 0.35 + k * 0.4)
  love.graphics.rectangle("fill", 6, -2.5, 24, 5)
  love.graphics.setColor(0.88, 0.86, 0.98)
  love.graphics.rectangle("fill", 6, -1.3, 22, 2.6)
  love.graphics.setColor(0.35, 0.25, 0.50)
  love.graphics.rectangle("fill", 4, -3, 3, 6)
  love.graphics.pop()
  -- aura de guardia
  if guardia then
    love.graphics.setColor(0.65, 0.35, 1.0, 0.22 + 0.1 * math.sin(e.animTimer * 8))
    love.graphics.circle("fill", x + math.cos(ang) * 6, y + math.sin(ang) * 6, 15)
    love.graphics.setColor(0.85, 0.65, 1.0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", x, y, 15, ang - 0.9, ang + 0.9)
    love.graphics.setLineWidth(1)
  elseif e.estado == "recuperar" then
    love.graphics.setColor(1, 0.9, 0.4, 0.5 + 0.3 * math.sin(e.animTimer * 12))
    love.graphics.print("!", x - 2, y - 32)
  end
  if e.tajoVisual and e.tajoVisual > 0 then
    local a = e.tajoVisual / 0.2
    love.graphics.setColor(0.9, 0.7, 1.0, a)
    love.graphics.setLineWidth(e.tajoUltimo and 4 or 3)
    love.graphics.arc("line", "open", x, y, d.rangoAtaque * 0.85, e.tajoAng - 0.9, e.tajoAng + 0.9)
    love.graphics.setLineWidth(1)
  end
end

return E