local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local sonidos    = require("src.datos.sonidos")

local intro = {}

-- ============================================================
-- CONFIGURACION
-- ============================================================
local TEXTO = {"F","A","C","T","R","A","L"," ","C","O","D","I","C","É"}
local ESCALA = 2.8

-- Colores base (azul arcano)
local AZUL_PROFUNDO = {0.05, 0.08, 0.20}
local AZUL_MEDIO    = {0.15, 0.35, 0.75}
local AZUL_BRILLO   = {0.55, 0.85, 1.00}
local AZUL_CLARO    = {0.85, 0.95, 1.00}

-- ============================================================
-- ESTADO
-- ============================================================
local letras = {}
local tiempoTotal = 0
local todoCayo = false
local blinkTimer = 0

local shakeX, shakeY = 0, 0
local shakeAmount = 0

local delayFinal = 0

-- Luciernagas
local luciernagas = {}
local timerLuciernaga = 0
local MAX_LUCIERNAGAS = 70

-- Ondas expansivas (al aterrizar cada letra)
local ondas = {}

-- Rayos verticales de la base
local rayos = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function crearLuciernaga(forzarInterior)
  local y
  if forzarInterior then
    -- Para el pre-poblado: cualquier parte alta
    y = math.random() * constantes.ALTO_VIRTUAL
  else
    -- Spawn natural: desde abajo
    y = constantes.ALTO_VIRTUAL + 8 + math.random() * 30
  end

  local p = {
    x = math.random() * constantes.ANCHO_VIRTUAL,
    y = y,
    vx = (math.random() - 0.5) * 14,
    vy = -16 - math.random() * 34,
    radio = 1 + math.random() * 2.2,
    vida = 4 + math.random() * 5,
    maxVida = 0,
    fase = math.random() * math.pi * 2,
    brillo = 0.55 + math.random() * 0.45,
    pulsar = 0.5 + math.random() * 0.8,
  }
  p.maxVida = p.vida
  return p
end

local function crearOnda(x, y)
  table.insert(ondas, {
    x = x,
    y = y,
    radio = 0,
    vida = 0.9,
    maxVida = 0.9,
  })
end

local function crearRayo()
  return {
    x = math.random() * constantes.ANCHO_VIRTUAL,
    ancho = 1 + math.random() * 3,
    largo = 80 + math.random() * 140,
    vy = -30 - math.random() * 60,
    y = constantes.ALTO_VIRTUAL + math.random() * 60,
    vida = 2 + math.random() * 3,
    maxVida = 0,
    alpha = 0.10 + math.random() * 0.20,
  }
end

-- ============================================================
-- ENTRAR
-- ============================================================

function intro.entrar()
  letras = {}
  tiempoTotal = 0
  todoCayo = false
  blinkTimer = 0
  shakeAmount = 0
  delayFinal = 0

  luciernagas = {}
  timerLuciernaga = 0
  ondas = {}
  rayos = {}

  -- Pre-poblar luciernagas para que el fondo ya este vivo al iniciar
  for i = 1, 35 do
    table.insert(luciernagas, crearLuciernaga(true))
  end

  -- Pre-poblar algunos rayos
  for i = 1, 12 do
    local r = crearRayo()
    r.y = math.random() * constantes.ALTO_VIRTUAL
    r.maxVida = r.vida
    table.insert(rayos, r)
  end

  -- Construir letras
  local f = love.graphics.getFont()
  local widths = {}
  local totalW = 0
  for i = 1, #TEXTO do
    local c = TEXTO[i]
    local w = f:getWidth(c) * ESCALA
    widths[i] = w
    totalW = totalW + w
  end

  local x0 = (constantes.ANCHO_VIRTUAL - totalW) / 2
  local accX = x0

  for i = 1, #TEXTO do
    local c = TEXTO[i]
    table.insert(letras, {
      c = c,
      x = accX,
      y = -60 - i * 14,
      targetY = 100,
      vy = 0,
      landed = false,
      startDelay = 0.15 + i * 0.09,
      activa = false,
      indexBase = i,
    })
    accX = accX + widths[i]
  end
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================

function intro.actualizar(dt)
  tiempoTotal = tiempoTotal + dt

  -- Shake
  if shakeAmount > 0 then
    shakeAmount = math.max(0, shakeAmount - dt * 55)
    shakeX = (math.random() - 0.5) * shakeAmount
    shakeY = (math.random() - 0.5) * shakeAmount
  else
    shakeX, shakeY = 0, 0
  end

  -- Letras cayendo
  local todasListas = true
  for _, l in ipairs(letras) do
    if tiempoTotal >= l.startDelay then l.activa = true end

    if l.activa and not l.landed then
      todasListas = false
      l.vy = l.vy + 1100 * dt
      l.y = l.y + l.vy * dt

      if l.y >= l.targetY then
        l.y = l.targetY
        if math.abs(l.vy) > 70 then
          l.vy = -l.vy * 0.32
          shakeAmount = 6
          -- Onda expansiva azul en la base de la letra
          local f = love.graphics.getFont()
          local wLetra = f:getWidth(l.c) * ESCALA
          crearOnda(l.x + wLetra / 2, l.targetY + 40)
          if sonidos.letra_cae then
            sonidos.letra_cae:stop()
            sonidos.letra_cae:play()
          end
        else
          l.vy = 0
          l.landed = true
        end
      end
    elseif not l.activa then
      todasListas = false
    end
  end

  -- Ondas
  local io = 1
  while io <= #ondas do
    local o = ondas[io]
    o.vida = o.vida - dt
    o.radio = o.radio + 80 * dt
    if o.vida <= 0 then
      table.remove(ondas, io)
    else
      io = io + 1
    end
  end

  -- Luciernagas
  timerLuciernaga = timerLuciernaga - dt
  if timerLuciernaga <= 0 then
    timerLuciernaga = 0.06 + math.random() * 0.14
    if #luciernagas < MAX_LUCIERNAGAS then
      table.insert(luciernagas, crearLuciernaga(false))
    end
  end

  local il = 1
  while il <= #luciernagas do
    local p = luciernagas[il]
    p.fase = p.fase + dt * p.pulsar
    p.x = p.x + p.vx * dt + math.sin(p.fase) * 12 * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt

    if p.vida <= 0 or p.y < -30 then
      table.remove(luciernagas, il)
    else
      il = il + 1
    end
  end

  -- Rayos verticales
  local ir = 1
  while ir <= #rayos do
    local r = rayos[ir]
    r.y = r.y + r.vy * dt
    r.vida = r.vida - dt
    if r.vida <= 0 or r.y + r.largo < 0 then
      table.remove(rayos, ir)
    else
      ir = ir + 1
    end
  end
  -- Spawn nuevos rayos periodicamente
  if math.random() < 0.55 then
    if #rayos < 22 then
      local r = crearRayo()
      r.maxVida = r.vida
      table.insert(rayos, r)
    end
  end

  -- Final
  if todasListas and not todoCayo then
    todoCayo = true
    delayFinal = 0
  end

  if todoCayo then
    delayFinal = delayFinal + dt
    if delayFinal > 0.6 then
      blinkTimer = blinkTimer + dt
    end
  end
end

-- ============================================================
-- DIBUJAR
-- ============================================================

local function dibujarFondo()
  -- Gradiente vertical: negro arriba -> azul profundo abajo
  local pasos = 48
  local hPaso = constantes.ALTO_VIRTUAL / pasos
  for i = 0, pasos - 1 do
    local t = i / (pasos - 1)
    -- Interpolacion cuadratica para que el azul se concentre abajo
    local tt = t * t
    local r = 0.02 + (AZUL_PROFUNDO[1] - 0.02) * tt
    local g = 0.03 + (AZUL_PROFUNDO[2] - 0.03) * tt
    local b = 0.06 + (AZUL_PROFUNDO[3] - 0.06) * tt
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, i * hPaso, constantes.ANCHO_VIRTUAL, hPaso + 1)
  end
end

local function dibujarLuzArcano()
  local cx = constantes.ANCHO_VIRTUAL / 2
  local cyBase = constantes.ALTO_VIRTUAL + 60
  local pulso = 0.5 + 0.5 * math.sin(tiempoTotal * 1.4)
  local pulso2 = 0.5 + 0.5 * math.sin(tiempoTotal * 2.1 + 1.3)

  -- Halos concentricos grandes
  for i = 6, 1, -1 do
    local r = i * 90
    local a = (0.06 + pulso * 0.04) * (7 - i) / 6
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.circle("fill", cx, cyBase, r)
  end

  -- Nucleo mas brillante
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.10 + pulso * 0.06)
  love.graphics.circle("fill", cx, cyBase, 200)
  love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.06 + pulso2 * 0.05)
  love.graphics.circle("fill", cx, cyBase, 130)

  -- Linea horizontal brillante en la base (horizonte magico)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.15 + pulso * 0.15)
  love.graphics.rectangle("fill", 0, constantes.ALTO_VIRTUAL - 3, constantes.ANCHO_VIRTUAL, 3)
  love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.35 + pulso2 * 0.25)
  love.graphics.rectangle("fill", 0, constantes.ALTO_VIRTUAL - 1, constantes.ANCHO_VIRTUAL, 1)
end

local function dibujarRayos()
  for _, r in ipairs(rayos) do
    local a = r.alpha * (r.vida / r.maxVida)
    -- Columna suave
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a * 0.5)
    love.graphics.rectangle("fill", r.x - r.ancho * 1.5, r.y, r.ancho * 3, r.largo)
    -- Nucleo mas brillante
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], a)
    love.graphics.rectangle("fill", r.x - r.ancho * 0.5, r.y, r.ancho, r.largo)
  end
end

local function dibujarLuciernagas()
  for _, p in ipairs(luciernagas) do
    local alpha
    if p.vida > p.maxVida - 0.8 then
      alpha = (p.maxVida - p.vida) / 0.8
    elseif p.vida < 1.0 then
      alpha = p.vida / 1.0
    else
      alpha = 1
    end
    alpha = math.max(0, math.min(1, alpha)) * p.brillo

    local pulso = 0.85 + 0.15 * math.sin(p.fase * 2)

    -- Halo exterior
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], alpha * 0.35 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 4)

    -- Halo intermedio
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], alpha * 0.55 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 2)

    -- Cuerpo
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio)

    -- Nucleo blanco
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.45)
  end
end

local function dibujarOndas()
  for _, o in ipairs(ondas) do
    local t = 1 - (o.vida / o.maxVida)
    local alpha = (1 - t) * 0.7
    local grosor = 3 - t * 2

    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], alpha)
    love.graphics.setLineWidth(grosor)
    love.graphics.ellipse("line", o.x, o.y, o.radio, o.radio * 0.4)
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], alpha * 0.9)
    love.graphics.setLineWidth(grosor * 0.4)
    love.graphics.ellipse("line", o.x, o.y, o.radio * 0.8, o.radio * 0.32)
    love.graphics.setLineWidth(1)
  end
end

local function dibujarLetras()
  for _, l in ipairs(letras) do
    if l.activa then
      -- Sombra profunda
      love.graphics.setColor(0, 0, 0, 0.65)
      love.graphics.print(l.c, l.x + 5, l.y + 5, 0, ESCALA, ESCALA)

      -- Sombra cercana
      love.graphics.setColor(0.02, 0.05, 0.15, 0.9)
      love.graphics.print(l.c, l.x + 2.5, l.y + 2.5, 0, ESCALA, ESCALA)

      -- Halo azul exterior
      love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.5)
      love.graphics.print(l.c, l.x - 2, l.y - 2, 0, ESCALA, ESCALA)
      love.graphics.print(l.c, l.x + 2, l.y - 2, 0, ESCALA, ESCALA)
      love.graphics.print(l.c, l.x - 2, l.y + 2, 0, ESCALA, ESCALA)
      love.graphics.print(l.c, l.x + 2, l.y + 2, 0, ESCALA, ESCALA)

      -- Brillo interior azul claro
      love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
      love.graphics.print(l.c, l.x - 1, l.y - 1, 0, ESCALA, ESCALA)

      -- Letra principal blanca
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(l.c, l.x, l.y, 0, ESCALA, ESCALA)

      -- Brillo superior blanco
      love.graphics.setColor(1, 1, 1, 0.5)
      love.graphics.print(l.c, l.x, l.y - 1.5, 0, ESCALA, ESCALA)
    end
  end
end

local function dibujarLineaYTextoFinal()
  if not (todoCayo and delayFinal > 0.6) then return end

  local cx = constantes.ANCHO_VIRTUAL / 2
  local ly = 175

  -- Aura pulsante bajo el titulo
  local pulsoAura = 0.5 + 0.5 * math.sin(blinkTimer * 2)
  for i = 4, 1, -1 do
    local r = i * 30
    local a = (0.04 + pulsoAura * 0.03) * (5 - i) / 4
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.circle("fill", cx, ly, 200 + r)
  end

  -- Linea decorativa expandiendose
  local anchoLinea = math.min(440, (delayFinal - 0.6) * 300)
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.7)
  love.graphics.rectangle("fill", cx - anchoLinea / 2, ly, anchoLinea, 1.5)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.95)
  love.graphics.rectangle("fill", cx - anchoLinea / 2, ly, anchoLinea, 0.6)

  -- Chispa en los extremos
  if anchoLinea > 20 then
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.95)
    love.graphics.circle("fill", cx - anchoLinea / 2, ly + 0.75, 2)
    love.graphics.circle("fill", cx + anchoLinea / 2, ly + 0.75, 2)
  end

  -- Texto "Pulsa para comenzar"
  local alpha = 0.5 + 0.5 * math.sin(blinkTimer * 4)
  local txt = "Pulsa para comenzar"
  local f = love.graphics.getFont()
  local escala = 1.3
  local tw = f:getWidth(txt) * escala
  local tx = (constantes.ANCHO_VIRTUAL - tw) / 2
  local ty = constantes.ALTO_VIRTUAL - 55

  -- Sombra
  love.graphics.setColor(0, 0, 0, alpha * 0.7)
  love.graphics.print(txt, tx + 2, ty + 2, 0, escala, escala)

  -- Aura azul
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], alpha * 0.7)
  love.graphics.print(txt, tx - 1, ty, 0, escala, escala)
  love.graphics.print(txt, tx + 1, ty, 0, escala, escala)
  love.graphics.print(txt, tx, ty - 1, 0, escala, escala)
  love.graphics.print(txt, tx, ty + 1, 0, escala, escala)

  -- Texto blanco
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.print(txt, tx, ty, 0, escala, escala)
end

function intro.dibujar()
  -- Fondo con gradiente
  dibujarFondo()

  -- Luz arcano inferior (detras de todo)
  dibujarLuzArcano()

  -- Rayos verticales subiendo
  dibujarRayos()

  -- Luciernagas (antes de las letras para que no las tapen)
  dibujarLuciernagas()

  -- Ondas expansivas de las letras
  dibujarOndas()

  -- Letras con shake
  love.graphics.push()
  love.graphics.translate(shakeX, shakeY)
  dibujarLetras()
  love.graphics.pop()

  -- Linea final y texto
  dibujarLineaYTextoFinal()

  -- Version tag
  love.graphics.setColor(0.5, 0.65, 0.85, 0.7)
  local f2 = love.graphics.getFont()
  love.graphics.print("v0.1", constantes.ANCHO_VIRTUAL - 40, constantes.ALTO_VIRTUAL - 20)
end

-- ============================================================
-- INPUT
-- ============================================================

function intro.touchpressed(id, x, y)
  if todoCayo and delayFinal > 0.6 then
    Estados.cambiar("menu")
  end
end

function intro.mousepressed(x, y, b)
  if todoCayo and delayFinal > 0.6 then
    Estados.cambiar("menu")
  end
end

function intro.keypressed(key)
  if todoCayo and delayFinal > 0.6 then
    Estados.cambiar("menu")
  end
end

return intro