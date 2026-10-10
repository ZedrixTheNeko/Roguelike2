local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local Config     = require("src.datos.config")
local Boton      = require("src.ui.boton")
local Consola    = require("src.utils.consola")
local Shaders     = require("src.utils.shaders")

local ajustes = {}

-- ============================================================
-- PALETA
-- ============================================================
local AZUL_PROFUNDO = {0.05, 0.08, 0.20}
local AZUL_MEDIO    = {0.15, 0.35, 0.75}
local AZUL_BRILLO   = {0.55, 0.85, 1.00}
local AZUL_CLARO    = {0.85, 0.95, 1.00}
local DORADO        = {1.00, 0.80, 0.30}
local DORADO_CLARO  = {1.00, 0.95, 0.65}

-- ============================================================
-- ESTADO
-- ============================================================
local botones = {}
local filas = {}
local tGlobal = 0

-- Scroll
local scrollY = 0
local scrollObjetivo = 0
local scrollMax = 0
local arrastrando = false
local arrastreInicialY = 0
local scrollInicial = 0
local touchId = nil
local ultimoDeltaY = 0

-- Area del contenido (se calcula al entrar)
local panelTop = 70
local panelBot = 0
local areaTop = 0
local areaBot = 0

-- Luciernagas
local luciernagas = {}
local timerLuciernaga = 0

-- Runas
local runas = {}
local timerRuna = 0

-- ============================================================
-- CREAR PARTICULAS
-- ============================================================

local function crearLuciernaga(interior)
  local y
  if interior then
    y = math.random() * constantes.ALTO_VIRTUAL
  else
    y = constantes.ALTO_VIRTUAL + 8 + math.random() * 30
  end

  return {
    x = math.random() * constantes.ANCHO_VIRTUAL,
    y = y,
    vx = (math.random() - 0.5) * 14,
    vy = -10 - math.random() * 22,
    radio = 1 + math.random() * 2,
    vida = 4 + math.random() * 4,
    maxVida = 4 + math.random() * 4,
    fase = math.random() * math.pi * 2,
    brillo = 0.55 + math.random() * 0.45,
  }
end

local function crearRuna()
  return {
    x = 40 + math.random() * (constantes.ANCHO_VIRTUAL - 80),
    y = 60 + math.random() * (constantes.ALTO_VIRTUAL - 120),
    tipo = math.random(1, 8),
    tamano = 6 + math.random() * 10,
    vida = 0,
    maxVida = 4 + math.random() * 4,
    fase = math.random() * math.pi * 2,
    velocidadPulso = 0.8 + math.random() * 1.6,
    rotacion = (math.random() - 0.5) * 0.4,
  }
end

-- ============================================================
-- HELPERS
-- ============================================================

local function crearFila(y, etiqueta, min, max, paso, clave, formato)
  return {
    y = y,
    etiqueta = etiqueta,
    min = min,
    max = max,
    paso = paso,
    clave = clave,
    formato = formato or "porcentaje",
  }
end

local function volver()
  local destino = Estados.nombreAnterior or "menu"
  if destino == "juego" then
    Estados.cambiar("juego", nil, nil, true)
  else
    Estados.cambiar(destino)
  end
end

-- Devuelve la Y real de un boton con el scroll aplicado
local function botonYReal(b)
  return b.y + areaTop - scrollY
end

-- ============================================================
-- DIBUJO FONDO
-- ============================================================

local function dibujarFondo()
  local pasos = 40
  local hPaso = constantes.ALTO_VIRTUAL / pasos
  for i = 0, pasos - 1 do
    local t = i / (pasos - 1)
    local tt = t * t
    local r = 0.02 + (AZUL_PROFUNDO[1] - 0.02) * tt
    local g = 0.03 + (AZUL_PROFUNDO[2] - 0.03) * tt
    local b = 0.06 + (AZUL_PROFUNDO[3] - 0.06) * tt
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, i * hPaso, constantes.ANCHO_VIRTUAL, hPaso + 1)
  end
end

local function dibujarRunaForma(tipo, tamano)
  if tipo == 1 then
    love.graphics.polygon("line", 0, -tamano, tamano * 0.87, tamano * 0.5, -tamano * 0.87, tamano * 0.5)
  elseif tipo == 2 then
    love.graphics.polygon("line", 0, -tamano, tamano * 0.7, 0, 0, tamano, -tamano * 0.7, 0)
  elseif tipo == 3 then
    love.graphics.line(-tamano, 0, tamano, 0)
    love.graphics.line(0, -tamano, 0, tamano)
  elseif tipo == 4 then
    local p = {}
    for i = 0, 4 do
      local a = -math.pi / 2 + i * (math.pi * 4 / 5)
      table.insert(p, math.cos(a) * tamano)
      table.insert(p, math.sin(a) * tamano)
    end
    love.graphics.polygon("line", p)
  elseif tipo == 5 then
    local p = {}
    for i = 0, 5 do
      local a = i * math.pi / 3 - math.pi / 6
      table.insert(p, math.cos(a) * tamano)
      table.insert(p, math.sin(a) * tamano)
    end
    love.graphics.polygon("line", p)
  elseif tipo == 6 then
    love.graphics.circle("line", 0, 0, tamano)
  elseif tipo == 7 then
    local p = {}
    for i = 0, 20 do
      local tt = i / 20
      table.insert(p, math.cos(tt * math.pi * 2.6) * tamano * tt)
      table.insert(p, math.sin(tt * math.pi * 2.6) * tamano * tt)
    end
    love.graphics.line(p)
  elseif tipo == 8 then
    love.graphics.circle("line", 0, 0, tamano * 0.5)
    love.graphics.circle("line", 0, 0, tamano)
  end
end

local function dibujarRunasFondo()
  for _, r in ipairs(runas) do
    local alpha
    if r.vida < 0.5 then alpha = r.vida / 0.5
    elseif r.vida > r.maxVida - 0.6 then alpha = (r.maxVida - r.vida) / 0.6
    else alpha = 1 end
    alpha = math.max(0, math.min(1, alpha))

    local pulso = 0.55 + 0.45 * math.sin(r.fase)
    local alphaFinal = math.min(1, alpha * pulso) * 0.35

    love.graphics.push()
    love.graphics.translate(r.x, r.y)
    love.graphics.rotate(r.rotacion)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], alphaFinal)
    dibujarRunaForma(r.tipo, r.tamano)
    love.graphics.pop()
  end
end

local function dibujarLuciernagas()
  for _, p in ipairs(luciernagas) do
    local alpha
    if p.vida > p.maxVida - 0.6 then alpha = (p.maxVida - p.vida) / 0.6
    elseif p.vida < 0.6 then alpha = p.vida / 0.6
    else alpha = 1 end
    alpha = math.max(0, math.min(1, alpha)) * p.brillo

    local pulso = 0.85 + 0.15 * math.sin(p.fase + tGlobal * 3)

    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], alpha * 0.35 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 2.5)
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], alpha * 0.7 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.4)
  end
end

local function esquina(x, y, ox, oy, color, alpha, s)
  s = s or 8
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(2)
  love.graphics.line(x, y, x + s * ox, y)
  love.graphics.line(x, y, x, y + s * oy)
  love.graphics.setLineWidth(1)
end

local function dibujarBotonArcanoEn(x, y, w, h, texto, esHover, colorBase)
  love.graphics.setColor(0.08, 0.12, 0.24, 0.92)
  love.graphics.rectangle("fill", x, y, w, h, 4)
  love.graphics.setColor(0.20, 0.32, 0.58, 0.45)
  love.graphics.rectangle("fill", x, y, w, h * 0.5, 4)
  love.graphics.setColor(0.02, 0.04, 0.10, 0.5)
  love.graphics.rectangle("fill", x, y + h * 0.6, w, h * 0.4, 4)

  if esHover then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.95)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.75)
  end
  love.graphics.rectangle("line", x, y, w, h, 4)

  if esHover then
    love.graphics.setColor(DORADO_CLARO[1], DORADO_CLARO[2], DORADO_CLARO[3], 0.9)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.7)
  end
  love.graphics.rectangle("fill", x + 10, y + 1.5, w - 20, 1.5)

  local colEsq = esHover and DORADO or colorBase
  local aEsq = esHover and 1.0 or 0.75
  esquina(x + 3, y + 3, 1, 1, colEsq, aEsq, 6)
  esquina(x + w - 3, y + 3, -1, 1, colEsq, aEsq, 6)
  esquina(x + 3, y + h - 3, 1, -1, colEsq, aEsq, 6)
  esquina(x + w - 3, y + h - 3, -1, -1, colEsq, aEsq, 6)

  local f = love.graphics.getFont()
  local tw = f:getWidth(texto)
  local th = f:getHeight()
  local tx = x + (w - tw) / 2
  local ty = y + (h - th) / 2

  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.print(texto, tx + 1, ty + 1)

  if esHover then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.7)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.55)
  end
  love.graphics.print(texto, tx - 1, ty)
  love.graphics.print(texto, tx + 1, ty)
  love.graphics.print(texto, tx, ty - 1)
  love.graphics.print(texto, tx, ty + 1)

  if esHover then
    love.graphics.setColor(1, 0.98, 0.85)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.print(texto, tx, ty)
end

-- ============================================================
-- ENTRAR
-- ============================================================

function ajustes.entrar()
  botones = {}
  filas = {}
  luciernagas = {}
  runas = {}
  tGlobal = 0
  scrollY = 0
  scrollObjetivo = 0
  arrastrando = false
  touchId = nil

  -- Areas de la pantalla
  panelTop = 70
  panelBot = constantes.ALTO_VIRTUAL - 30
  areaTop = panelTop + 4
  areaBot = panelBot - 4

  for i = 1, 18 do
    local l = crearLuciernaga(true)
    l.maxVida = l.vida
    table.insert(luciernagas, l)
  end

  for i = 1, 6 do
    local r = crearRuna()
    r.vida = math.random() * r.maxVida
    table.insert(runas, r)
  end

  -- ============================================================
  -- Contenido (coordenadas logicas empezando desde 0)
  -- ============================================================
  local y0 = 20
  local saltoY = 46

  table.insert(filas, crearFila(y0,               "Volumen",    0,   1,   0.1, "volumen",         "porcentaje"))
  table.insert(filas, crearFila(y0 + saltoY,      "Zoom",       1.0, 2.5, 0.1, "zoom",            "escala"))
  table.insert(filas, crearFila(y0 + saltoY * 2,  "Escala HUD", 0.8, 2.0, 0.1, "escalaHUD",       "porcentaje"))
  table.insert(filas, crearFila(y0 + saltoY * 3,  "Controles",  0.7, 1.5, 0.1, "escalaControles", "porcentaje"))

  local bW, bH = 42, 30
  local xMenos = constantes.ANCHO_VIRTUAL / 2 + 60
  local xMas   = constantes.ANCHO_VIRTUAL / 2 + 110

  for _, f in ipairs(filas) do
    table.insert(botones, Boton.nuevo(xMenos, f.y - 4, bW, bH, "-", function()
      local v = Config.get(f.clave) or f.min
      v = math.max(f.min, v - f.paso)
      Config.set(f.clave, v)
    end))
    table.insert(botones, Boton.nuevo(xMas, f.y - 4, bW, bH, "+", function()
      local v = Config.get(f.clave) or f.min
      v = math.min(f.max, v + f.paso)
      Config.set(f.clave, v)
    end))
  end

  local yToggles = y0 + saltoY * 4 + 20

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 100, yToggles,
                                    200, 32, "Auto-aim", function()
    Config.set("autoAim", not Config.get("autoAim"))
  end))

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 100, yToggles + 42,
                                    200, 32, "Efectos", function()
    Config.set("efectosVisuales", not Config.get("efectosVisuales"))
  end))

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 100, yToggles + 84,
                                    200, 32, "Debug", function()
    local nuevo = not Config.get("debugConsola")
    Config.set("debugConsola", nuevo)
    if nuevo then
      print("[DEBUG] Consola activada")
    else
      print("[DEBUG] Consola desactivada")
      Consola.limpiar()
    end
  end))

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 100, yToggles + 126,
                                    200, 32, "Shaders", function()
    Shaders.ciclarAjuste()
    Config.guardar()
  end))

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 100, yToggles + 168,
                                    200, 32, "Sangre", function()
    Config.set("sangre", not (Config.get("sangre") ~= false))
  end))

  table.insert(botones, Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 90,
                                    yToggles + 168 + 54,
                                    180, 36, "Volver", volver))

  -- ============================================================
  -- Calcular scroll maximo
  -- ============================================================
  local ultimoY = yToggles + 84 + 54 + 36 + 20
  local areaAlto = areaBot - areaTop
  scrollMax = math.max(0, ultimoY - areaAlto)
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================

function ajustes.actualizar(dt)
  tGlobal = tGlobal + dt

  local factor = math.min(1, dt * 14)
  scrollY = scrollY + (scrollObjetivo - scrollY) * factor

  if scrollObjetivo < 0 then scrollObjetivo = 0 end
  if scrollObjetivo > scrollMax then scrollObjetivo = scrollMax end
  if scrollY < 0 then scrollY = 0 end
  if scrollY > scrollMax then scrollY = scrollMax end

  timerLuciernaga = timerLuciernaga - dt
  if timerLuciernaga <= 0 then
    timerLuciernaga = 0.4 + math.random() * 0.5
    if #luciernagas < 20 then
      table.insert(luciernagas, crearLuciernaga(false))
    end
  end

  local i = 1
  while i <= #luciernagas do
    local p = luciernagas[i]
    p.fase = p.fase + dt * 1.5
    p.x = p.x + p.vx * dt + math.sin(p.fase) * 12 * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 or p.y < -20 then
      table.remove(luciernagas, i)
    else
      i = i + 1
    end
  end

  timerRuna = timerRuna - dt
  if timerRuna <= 0 then
    timerRuna = 1.5 + math.random() * 1.5
    if #runas < 8 then
      table.insert(runas, crearRuna())
    end
  end

  local ir = 1
  while ir <= #runas do
    local r = runas[ir]
    r.vida = r.vida + dt
    r.fase = r.fase + dt * r.velocidadPulso
    if r.vida >= r.maxVida then
      table.remove(runas, ir)
    else
      ir = ir + 1
    end
  end
end

-- ============================================================
-- DIBUJAR
-- ============================================================

function ajustes.dibujar()
  dibujarFondo()
  dibujarRunasFondo()
  dibujarLuciernagas()

  local cx = constantes.ANCHO_VIRTUAL / 2

  -- ============================================================
  -- Panel de fondo principal
  -- ============================================================
  love.graphics.setColor(0.05, 0.08, 0.15, 0.7)
  love.graphics.rectangle("fill", 30, panelTop, constantes.ANCHO_VIRTUAL - 60, panelBot - panelTop, 8)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.4)
  love.graphics.rectangle("line", 30, panelTop, constantes.ANCHO_VIRTUAL - 60, panelBot - panelTop, 8)

  esquina(34, panelTop + 4, 1, 1, AZUL_BRILLO, 0.7, 8)
  esquina(constantes.ANCHO_VIRTUAL - 34, panelTop + 4, -1, 1, AZUL_BRILLO, 0.7, 8)
  esquina(34, panelBot - 4, 1, -1, AZUL_BRILLO, 0.7, 8)
  esquina(constantes.ANCHO_VIRTUAL - 34, panelBot - 4, -1, -1, AZUL_BRILLO, 0.7, 8)

  -- ============================================================
  -- TITULO (fijo, no scrollea)
  -- ============================================================
  local titulo = "AJUSTES"
  local f = love.graphics.getFont()
  local escala = 2.0
  local twTitulo = f:getWidth(titulo) * escala
  local txTitulo = cx - twTitulo / 2
  local tyTitulo = 25

  local pulso = 0.5 + 0.5 * math.sin(tGlobal * 1.5)

  for i = 5, 1, -1 do
    local a = 0.03 * (6 - i) * (0.7 + pulso * 0.3)
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.rectangle("fill", txTitulo - i * 6, tyTitulo - i * 6,
                            twTitulo + i * 12, 40 + i * 12)
  end

  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(titulo, txTitulo + 3, tyTitulo + 3, 0, escala, escala)

  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.6 + pulso * 0.2)
  love.graphics.print(titulo, txTitulo - 2, tyTitulo, 0, escala, escala)
  love.graphics.print(titulo, txTitulo + 2, tyTitulo, 0, escala, escala)
  love.graphics.print(titulo, txTitulo, tyTitulo - 2, 0, escala, escala)
  love.graphics.print(titulo, txTitulo, tyTitulo + 2, 0, escala, escala)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
  love.graphics.print(titulo, txTitulo - 1, tyTitulo - 1, 0, escala, escala)

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(titulo, txTitulo, tyTitulo, 0, escala, escala)

  local anchoLinea = 300
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.6)
  love.graphics.rectangle("fill", cx - anchoLinea / 2, tyTitulo + 42, anchoLinea, 1)
  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.9)
  love.graphics.circle("fill", cx - anchoLinea / 2, tyTitulo + 42.5, 3)
  love.graphics.circle("fill", cx + anchoLinea / 2, tyTitulo + 42.5, 3)

  -- ============================================================
  -- SCISSOR
  -- ============================================================
  love.graphics.setScissor(35, areaTop,
                           constantes.ANCHO_VIRTUAL - 70,
                           areaBot - areaTop)

  -- ============================================================
  -- FILAS
  -- ============================================================
  for _, fila in ipairs(filas) do
    local fy = areaTop + fila.y - scrollY

    love.graphics.setColor(0.05, 0.08, 0.15, 0.75)
    love.graphics.rectangle("fill", cx - 240, fy - 8, 480, 38, 5)
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.4)
    love.graphics.rectangle("line", cx - 240, fy - 8, 480, 38, 5)

    esquina(cx - 238, fy - 6, 1, 1, AZUL_BRILLO, 0.6, 6)
    esquina(cx + 238, fy - 6, -1, 1, AZUL_BRILLO, 0.6, 6)
    esquina(cx - 238, fy + 28, 1, -1, AZUL_BRILLO, 0.6, 6)
    esquina(cx + 238, fy + 28, -1, -1, AZUL_BRILLO, 0.6, 6)

    love.graphics.setColor(0.90, 0.92, 0.98)
    love.graphics.print(fila.etiqueta, cx - 220, fy + 6)

    local valor = Config.get(fila.clave) or 0
    local textoValor
    if fila.formato == "porcentaje" then
      textoValor = string.format("%d%%", math.floor(valor * 100))
    else
      textoValor = string.format("%.1fx", valor)
    end

    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3])
    local twV = f:getWidth(textoValor)
    love.graphics.print(textoValor, cx + 32 - twV, fy + 6)
  end

  -- ============================================================
  -- BOTONES (con scroll aplicado al dibujar)
  -- ============================================================
  for i, b in ipairs(botones) do
    local yReal = areaTop + b.y - scrollY
    local textoOriginal = b.texto

    if b.texto == "Auto-aim" then
      b.texto = "Auto-aim: " .. (Config.get("autoAim") and "ON" or "OFF")
    elseif b.texto == "Efectos" then
      b.texto = "Efectos: " .. (Config.get("efectosVisuales") and "ON" or "OFF")
    elseif b.texto == "Debug" then
      b.texto = "Debug: " .. (Config.get("debugConsola") and "ON" or "OFF")
    elseif b.texto == "Sangre" then
      b.texto = "Sangre: " .. ((Config.get("sangre") ~= false) and "ON" or "OFF")
    elseif b.texto == "Shaders" then
      b.texto = "Shaders: " .. Shaders.textoAjuste()
    end

    if yReal + b.h > areaTop and yReal < areaBot then
      dibujarBotonArcanoEn(b.x, yReal, b.w, b.h, b.texto, b.presionado, AZUL_BRILLO)
    end

    b.texto = textoOriginal
  end

  love.graphics.setScissor()

  -- ============================================================
  -- Barra de scroll
  -- ============================================================
  if scrollMax > 0 then
    local barX = constantes.ANCHO_VIRTUAL - 22
    local barY = areaTop
    local barH = areaBot - areaTop

    love.graphics.setColor(0.10, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", barX, barY, 6, barH, 3)

    local thumbH = math.max(30, barH * (barH / (barH + scrollMax)))
    local thumbY = barY + (scrollY / scrollMax) * (barH - thumbH)

    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
    love.graphics.rectangle("fill", barX, thumbY, 6, thumbH, 3)
  end

  love.graphics.setColor(0.5, 0.65, 0.85, 0.7)
  love.graphics.print("v0.1", constantes.ANCHO_VIRTUAL - 40, constantes.ALTO_VIRTUAL - 20)
end

-- ============================================================
-- INPUT
-- ============================================================

-- Detecta que boton esta bajo (x, y) teniendo en cuenta el scroll
local function botonBajo(x, y)
  for _, b in ipairs(botones) do
    local by = areaTop + b.y - scrollY
    if x >= b.x and x <= b.x + b.w and y >= by and y <= by + b.h then
      return b
    end
  end
  return nil
end

function ajustes.touchpressed(id, x, y)
  -- Solo procesar toques dentro del area visible del panel
  if y < areaTop or y > areaBot then
    -- Fuera del area: iniciar arrastre de todos modos por si quiere salir
    arrastrando = true
    touchId = id
    arrastreInicialY = y
    scrollInicial = scrollObjetivo
    ultimoDeltaY = 0
    return
  end

  local b = botonBajo(x, y)
  if b then
    -- Aplicar offset al touchpressed para que el boton sepa que fue tocado
    local by = areaTop + b.y - scrollY
    local oy = b.y
    b.y = by
    b:touchpressed(id, x, y)
    b.y = oy
    arrastrando = false
    return
  end

  arrastrando = true
  touchId = id
  arrastreInicialY = y
  scrollInicial = scrollObjetivo
  ultimoDeltaY = 0
end

function ajustes.touchmoved(id, x, y)
  if not arrastrando or id ~= touchId then return end

  local dy = y - arrastreInicialY
  ultimoDeltaY = dy

  scrollObjetivo = scrollInicial - dy
  if scrollObjetivo < 0 then scrollObjetivo = 0 end
  if scrollObjetivo > scrollMax then scrollObjetivo = scrollMax end
end

function ajustes.touchreleased(id, x, y)
  if arrastrando and id == touchId then
    arrastrando = false
    touchId = nil
    return
  end

  -- Liberar botones (con offset aplicado)
  for _, b in ipairs(botones) do
    local by = areaTop + b.y - scrollY
    local oy = b.y
    b.y = by
    b:touchreleased(id, x, y)
    b.y = oy
  end
end

function ajustes.mousepressed(x, y, btn) ajustes.touchpressed(-1, x, y) end
function ajustes.mousereleased(x, y, btn) ajustes.touchreleased(-1, x, y) end

function ajustes.keypressed(key)
  if key == "escape" then volver() end
end

return ajustes