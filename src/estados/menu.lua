local constantes = require("src.constantes")
local textos    = require("src.datos.textos")
local Boton     = require("src.ui.boton")
local Estados   = require("src.sistemas.estados")

local menu = {}

local AZUL_PROFUNDO = {0.05, 0.08, 0.20}
local AZUL_MEDIO    = {0.15, 0.35, 0.75}
local AZUL_BRILLO   = {0.55, 0.85, 1.00}
local AZUL_CLARO    = {0.85, 0.95, 1.00}
local DORADO        = {1.00, 0.80, 0.30}
local DORADO_CLARO  = {1.00, 0.95, 0.65}

local botones = {}
local tGlobal = 0
local indiceSeleccionado = 1
local usandoTeclado = false

local luciernagas = {}
local timerLuciernaga = 0
local MAX_LUCIERNAGAS = 60

local rayos = {}
local runas = {}
local timerRuna = 0
local MAX_RUNAS = 22
local toques = {}

local transicion = {
  activa = false, timer = 0, duracion = 0.85,
  destino = nil, origenX = 0, origenY = 0,
}

local glitch = { timer = 0, activo = 0, fuerza = 0 }

local function crearLuciernaga(interior)
  local y
  if interior then y = math.random() * constantes.ALTO_VIRTUAL
  else y = constantes.ALTO_VIRTUAL + 8 + math.random() * 30 end
  local p = {
    x = math.random() * constantes.ANCHO_VIRTUAL, y = y,
    vx = (math.random() - 0.5) * 14, vy = -16 - math.random() * 34,
    radio = 1 + math.random() * 2.2,
    vida = 4 + math.random() * 5, maxVida = 0,
    fase = math.random() * math.pi * 2,
    brillo = 0.55 + math.random() * 0.45,
    pulsar = 0.5 + math.random() * 0.8,
  }
  p.maxVida = p.vida
  return p
end

local function crearRayo()
  return {
    x = math.random() * constantes.ANCHO_VIRTUAL,
    ancho = 1 + math.random() * 3,
    largo = 80 + math.random() * 140,
    vy = -30 - math.random() * 60,
    y = constantes.ALTO_VIRTUAL + math.random() * 60,
    vida = 2 + math.random() * 3, maxVida = 0,
    alpha = 0.10 + math.random() * 0.20,
  }
end

local function crearRuna()
  local esDorada = math.random() < 0.14
  return {
    x = 40 + math.random() * (constantes.ANCHO_VIRTUAL - 80),
    y = 60 + math.random() * (constantes.ALTO_VIRTUAL - 140),
    tipo = math.random(1, 8),
    tamano = 8 + math.random() * 16,
    vida = 0, maxVida = 3 + math.random() * 3.5,
    fase = math.random() * math.pi * 2,
    velocidadPulso = 1 + math.random() * 2,
    color = esDorada and DORADO or AZUL_BRILLO,
    colorClaro = esDorada and DORADO_CLARO or AZUL_CLARO,
    rotacion = (math.random() - 0.5) * 0.4,
    boost = 0,
  }
end

local function crearToque(x, y)
  table.insert(toques, { x = x, y = y, vida = 0.6, maxVida = 0.6, radio = 0 })
end

local function dibujarRunaForma(tipo, tamano)
  if tipo == 1 then
    love.graphics.polygon("line", 0, -tamano, tamano * 0.87, tamano * 0.5, -tamano * 0.87, tamano * 0.5)
    love.graphics.circle("line", 0, tamano * 0.15, tamano * 0.35)
  elseif tipo == 2 then
    love.graphics.polygon("line", 0, -tamano, tamano * 0.7, 0, 0, tamano, -tamano * 0.7, 0)
    love.graphics.circle("fill", 0, 0, 1.5)
    love.graphics.circle("line", 0, 0, tamano * 0.3)
  elseif tipo == 3 then
    love.graphics.line(-tamano, 0, tamano, 0)
    love.graphics.line(0, -tamano, 0, tamano)
    love.graphics.circle("line", -tamano * 0.7, 0, tamano * 0.25)
    love.graphics.circle("line",  tamano * 0.7, 0, tamano * 0.25)
    love.graphics.circle("line", 0, -tamano * 0.7, tamano * 0.25)
    love.graphics.circle("line", 0,  tamano * 0.7, tamano * 0.25)
  elseif tipo == 4 then
    local p = {}
    for i = 0, 4 do
      local ang = -math.pi / 2 + i * (math.pi * 4 / 5)
      table.insert(p, math.cos(ang) * tamano)
      table.insert(p, math.sin(ang) * tamano)
    end
    love.graphics.polygon("line", p)
    love.graphics.circle("line", 0, 0, tamano * 0.35)
  elseif tipo == 5 then
    local p = {}
    for i = 0, 5 do
      local ang = i * math.pi / 3 - math.pi / 6
      table.insert(p, math.cos(ang) * tamano)
      table.insert(p, math.sin(ang) * tamano)
    end
    love.graphics.polygon("line", p)
    love.graphics.circle("fill", 0, 0, tamano * 0.15)
  elseif tipo == 6 then
    love.graphics.circle("line", 0, 0, tamano)
    love.graphics.line(-tamano * 0.5, -tamano * 0.5, tamano * 0.5, tamano * 0.5)
    love.graphics.line(-tamano * 0.5, tamano * 0.5, tamano * 0.5, -tamano * 0.5)
  elseif tipo == 7 then
    local p = {}
    for i = 0, 24 do
      local tt = i / 24
      local ang = tt * math.pi * 2.6
      local r = tamano * tt
      table.insert(p, math.cos(ang) * r)
      table.insert(p, math.sin(ang) * r)
    end
    love.graphics.line(p)
  elseif tipo == 8 then
    love.graphics.circle("line", 0, 0, tamano * 0.4)
    love.graphics.circle("line", 0, 0, tamano * 0.7)
    love.graphics.circle("line", 0, 0, tamano)
    love.graphics.line(0, -tamano, 0, -tamano * 0.4)
    love.graphics.line(0, tamano, 0, tamano * 0.4)
  end
end

local function calcularAlphaRuna(p)
  local alpha
  if p.vida < 0.5 then alpha = p.vida / 0.5
  elseif p.vida > p.maxVida - 0.6 then alpha = (p.maxVida - p.vida) / 0.6
  else alpha = 1 end
  return math.max(0, math.min(1, alpha))
end

local function dibujarRuna(p)
  local alphaBase = calcularAlphaRuna(p)
  local pulso = 0.55 + 0.45 * math.sin(p.fase)
  local boost = p.boost or 0
  local alphaFinal = math.min(1, alphaBase * (pulso + boost))
  love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal * 0.10)
  love.graphics.circle("fill", p.x, p.y, p.tamano * 2.6)
  love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal * 0.18)
  love.graphics.circle("fill", p.x, p.y, p.tamano * 1.7)
  love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal * 0.28)
  love.graphics.circle("fill", p.x, p.y, p.tamano * 1.15)
  if boost > 0.05 then
    love.graphics.setColor(p.colorClaro[1], p.colorClaro[2], p.colorClaro[3], boost * 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", p.x, p.y, p.tamano * (1.4 + (1 - boost) * 0.5))
    love.graphics.setLineWidth(1)
  end
  love.graphics.push()
  love.graphics.translate(p.x, p.y)
  love.graphics.rotate(p.rotacion + math.sin(p.fase * 0.3) * 0.05)
  love.graphics.setLineWidth(1.4)
  love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal * 0.35)
  dibujarRunaForma(p.tipo, p.tamano + 1.5)
  love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal * 0.85)
  love.graphics.setLineWidth(1.2)
  dibujarRunaForma(p.tipo, p.tamano)
  love.graphics.setColor(p.colorClaro[1], p.colorClaro[2], p.colorClaro[3], alphaFinal)
  love.graphics.setLineWidth(0.6)
  dibujarRunaForma(p.tipo, p.tamano)
  love.graphics.setLineWidth(1)
  love.graphics.pop()
end

local DIST_CONEXION_MAX = 150
local DIST_CONEXION_MIN = 40

local function dibujarConexionesRunas()
  local n = #runas
  for i = 1, n - 1 do
    local a = runas[i]
    local alphaA = calcularAlphaRuna(a)
    if alphaA > 0.5 then
      for j = i + 1, n do
        local b = runas[j]
        local alphaB = calcularAlphaRuna(b)
        if alphaB > 0.5 then
          local dx, dy = b.x - a.x, b.y - a.y
          local d2 = dx * dx + dy * dy
          if d2 < DIST_CONEXION_MAX * DIST_CONEXION_MAX and d2 > DIST_CONEXION_MIN * DIST_CONEXION_MIN then
            local d = math.sqrt(d2)
            local inten = 1 - (d - DIST_CONEXION_MIN) / (DIST_CONEXION_MAX - DIST_CONEXION_MIN)
            inten = math.max(0, math.min(1, inten))
            local alpha = alphaA * alphaB * inten * 0.35
            local pulso = 0.6 + 0.4 * math.sin(tGlobal * 1.8 + a.fase + b.fase)
            local r = (a.color[1] + b.color[1]) * 0.5
            local g = (a.color[2] + b.color[2]) * 0.5
            local bl = (a.color[3] + b.color[3]) * 0.5
            love.graphics.setColor(r, g, bl, alpha * pulso)
            love.graphics.setLineWidth(1)
            love.graphics.line(a.x, a.y, b.x, b.y)
            love.graphics.setColor(r, g, bl, alpha * pulso * 1.5)
            love.graphics.circle("fill", (a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 1.5)
          end
        end
      end
    end
  end
end

local function dibujarFondo()
  local pasos = 48
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

local function dibujarLuzArcano()
  local cx = constantes.ANCHO_VIRTUAL / 2
  local cyBase = constantes.ALTO_VIRTUAL + 60
  local pulso = 0.5 + 0.5 * math.sin(tGlobal * 1.4)
  local pulso2 = 0.5 + 0.5 * math.sin(tGlobal * 2.1 + 1.3)
  for i = 6, 1, -1 do
    local r = i * 90
    local a = (0.06 + pulso * 0.04) * (7 - i) / 6
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.circle("fill", cx, cyBase, r)
  end
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.10 + pulso * 0.06)
  love.graphics.circle("fill", cx, cyBase, 200)
  love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.06 + pulso2 * 0.05)
  love.graphics.circle("fill", cx, cyBase, 130)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.15 + pulso * 0.15)
  love.graphics.rectangle("fill", 0, constantes.ALTO_VIRTUAL - 3, constantes.ANCHO_VIRTUAL, 3)
  love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.35 + pulso2 * 0.25)
  love.graphics.rectangle("fill", 0, constantes.ALTO_VIRTUAL - 1, constantes.ANCHO_VIRTUAL, 1)
end

local function dibujarRayos()
  for _, r in ipairs(rayos) do
    local a = r.alpha * (r.vida / r.maxVida)
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a * 0.5)
    love.graphics.rectangle("fill", r.x - r.ancho * 1.5, r.y, r.ancho * 3, r.largo)
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], a)
    love.graphics.rectangle("fill", r.x - r.ancho * 0.5, r.y, r.ancho, r.largo)
  end
end

local function dibujarLuciernagas()
  for _, p in ipairs(luciernagas) do
    local alpha
    if p.vida > p.maxVida - 0.8 then alpha = (p.maxVida - p.vida) / 0.8
    elseif p.vida < 1.0 then alpha = p.vida / 1.0
    else alpha = 1 end
    alpha = math.max(0, math.min(1, alpha)) * p.brillo
    local pulso = 0.85 + 0.15 * math.sin(p.fase * 2)
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], alpha * 0.35 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 4)
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], alpha * 0.55 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 2)
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.45)
  end
end

local function dibujarToques()
  for _, tg in ipairs(toques) do
    local t = tg.vida / tg.maxVida
    local a = t * 0.7
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], a)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", tg.x, tg.y, tg.radio)
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], a * 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", tg.x, tg.y, tg.radio * 0.6)
  end
end

local function dibujarTitulo()
  local cx = constantes.ANCHO_VIRTUAL / 2
  local titulo = textos.juego.titulo
  local f = love.graphics.getFont()
  local escala = 2.4
  local tw = f:getWidth(titulo) * escala
  local tx = cx - tw / 2
  local ty = 24
  local pulso = 0.5 + 0.5 * math.sin(tGlobal * 1.5)
  for i = 5, 1, -1 do
    local a = 0.03 * (6 - i) * (0.7 + pulso * 0.3)
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.rectangle("fill", tx - i * 6, ty - i * 6, tw + i * 12, 40 + i * 12)
  end
  local gx, gy = 0, 0
  if glitch.activo > 0 then
    gx = (math.random() - 0.5) * 6 * glitch.fuerza
    gy = (math.random() - 0.5) * 3 * glitch.fuerza
  end
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(titulo, tx + 5, ty + 5, 0, escala, escala)
  love.graphics.setColor(0.02, 0.05, 0.15, 0.95)
  love.graphics.print(titulo, tx + 2.5, ty + 2.5, 0, escala, escala)
  if glitch.activo > 0 then
    local gmag = 3 * glitch.fuerza
    love.graphics.setColor(1, 0.2, 0.3, 0.7 * glitch.fuerza)
    love.graphics.print(titulo, tx + gx - gmag, ty + gy, 0, escala, escala)
    love.graphics.setColor(0.3, 0.9, 1, 0.7 * glitch.fuerza)
    love.graphics.print(titulo, tx + gx + gmag, ty + gy, 0, escala, escala)
  end
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.55 + pulso * 0.2)
  love.graphics.print(titulo, tx + gx - 2, ty + gy, 0, escala, escala)
  love.graphics.print(titulo, tx + gx + 2, ty + gy, 0, escala, escala)
  love.graphics.print(titulo, tx + gx, ty + gy - 2, 0, escala, escala)
  love.graphics.print(titulo, tx + gx, ty + gy + 2, 0, escala, escala)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
  love.graphics.print(titulo, tx + gx - 1, ty + gy - 1, 0, escala, escala)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(titulo, tx + gx, ty + gy, 0, escala, escala)
end

local function dibujarSubtitulo()
  local cx = constantes.ANCHO_VIRTUAL / 2
  local sub = "Aventura en el multiverso"
  local f = love.graphics.getFont()
  local tw = f:getWidth(sub)
  local y = 104
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(sub, cx - tw / 2 + 1, y + 1)
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.8)
  love.graphics.print(sub, cx - tw / 2 - 1, y)
  love.graphics.print(sub, cx - tw / 2 + 1, y)
  love.graphics.setColor(0.85, 0.92, 1.0, 0.9)
  love.graphics.print(sub, cx - tw / 2, y)
end

local function dibujarSimbolo(indice, x, y, color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(1.3)
  if indice == 1 then
    love.graphics.polygon("line", x, y - 5, x + 3, y, x, y + 5, x - 3, y)
    love.graphics.circle("fill", x, y, 1)
  elseif indice == 2 then
    love.graphics.circle("line", x - 4, y, 3)
    love.graphics.circle("line", x + 4, y, 3)
    love.graphics.line(x - 1, y, x + 1, y)
  elseif indice == 3 then
    love.graphics.circle("line", x, y, 4)
    love.graphics.circle("line", x, y, 2)
    for i = 0, 5 do
      local ang = i * math.pi / 3
      love.graphics.line(
        x + math.cos(ang) * 4, y + math.sin(ang) * 4,
        x + math.cos(ang) * 6, y + math.sin(ang) * 6)
    end
  elseif indice == 4 then
    love.graphics.ellipse("line", x, y, 6, 3.5)
    love.graphics.circle("line", x, y, 2)
    love.graphics.circle("fill", x, y, 0.8)
  elseif indice == 5 then
    love.graphics.arc("line", "open", x, y + 2, 4, math.pi, math.pi * 2)
    love.graphics.line(x - 4, y + 2, x - 4, y + 5)
    love.graphics.line(x + 4, y + 2, x + 4, y + 5)
    love.graphics.line(x, y + 5, x, y - 1)
  end
  love.graphics.setLineWidth(1)
end

local function dibujarBotonArcano(b, indice, esHover, esSeleccionado)
  local t = love.timer.getTime()
  local resaltado = esHover or esSeleccionado

  love.graphics.setColor(0.08, 0.12, 0.24, 0.88)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4)
  love.graphics.setColor(0.20, 0.32, 0.58, 0.45)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h * 0.5, 4)
  love.graphics.setColor(0.35, 0.50, 0.75, 0.25)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h * 0.25, 4)
  love.graphics.setColor(0.02, 0.04, 0.10, 0.5)
  love.graphics.rectangle("fill", b.x, b.y + b.h * 0.6, b.w, b.h * 0.4, 4)

  if resaltado then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.95)
  else
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.55)
  end
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4)

  if resaltado then
    love.graphics.setColor(DORADO_CLARO[1], DORADO_CLARO[2], DORADO_CLARO[3], 0.9)
  else
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.7)
  end
  love.graphics.rectangle("fill", b.x + 14, b.y + 1.5, b.w - 28, 1.5)

  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.55)
  love.graphics.rectangle("fill", b.x + 14, b.y + b.h - 3, b.w - 28, 1)

  local colEsq = resaltado and DORADO or AZUL_BRILLO
  local aEsq = resaltado and 1.0 or 0.8
  local s = 7
  love.graphics.setColor(colEsq[1], colEsq[2], colEsq[3], aEsq)
  love.graphics.setLineWidth(1.8)
  love.graphics.line(b.x + 2, b.y + 2, b.x + 2 + s, b.y + 2)
  love.graphics.line(b.x + 2, b.y + 2, b.x + 2, b.y + 2 + s)
  love.graphics.line(b.x + b.w - 2, b.y + 2, b.x + b.w - 2 - s, b.y + 2)
  love.graphics.line(b.x + b.w - 2, b.y + 2, b.x + b.w - 2, b.y + 2 + s)
  love.graphics.line(b.x + 2, b.y + b.h - 2, b.x + 2 + s, b.y + b.h - 2)
  love.graphics.line(b.x + 2, b.y + b.h - 2, b.x + 2, b.y + b.h - 2 - s)
  love.graphics.line(b.x + b.w - 2, b.y + b.h - 2, b.x + b.w - 2 - s, b.y + b.h - 2)
  love.graphics.line(b.x + b.w - 2, b.y + b.h - 2, b.x + b.w - 2, b.y + b.h - 2 - s)
  love.graphics.setLineWidth(1)

  if esSeleccionado and usandoTeclado then
    local pulso = 0.5 + 0.5 * math.sin(t * 6)
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.8 + pulso * 0.2)
    love.graphics.polygon("fill",
      b.x - 10, b.y + b.h / 2,
      b.x - 4, b.y + b.h / 2 - 6,
      b.x - 4, b.y + b.h / 2 + 6)
  end

  local colSimbolo = resaltado and DORADO_CLARO or AZUL_BRILLO
  local aSimbolo = resaltado and 1.0 or 0.75
  dibujarSimbolo(indice, b.x + 28, b.y + b.h / 2, colSimbolo, aSimbolo)
  dibujarSimbolo(indice, b.x + b.w - 28, b.y + b.h / 2, colSimbolo, aSimbolo)

  local f = love.graphics.getFont()
  local texto = b.texto
  local tw = f:getWidth(texto)
  local th = f:getHeight()
  local ttx = b.x + (b.w - tw) / 2
  local tty = b.y + (b.h - th) / 2

  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.print(texto, ttx + 1, tty + 1)
  if resaltado then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.55)
  else
    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.45)
  end
  love.graphics.print(texto, ttx - 1, tty)
  love.graphics.print(texto, ttx + 1, tty)
  love.graphics.print(texto, ttx, tty - 1)
  love.graphics.print(texto, ttx, tty + 1)
  if resaltado then
    love.graphics.setColor(1, 0.95, 0.75, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.print(texto, ttx, tty)
end

local function dibujarTransicion()
  if not transicion.activa then return end
  local t = transicion.timer / transicion.duracion
  local intensidad = math.min(1, t * 1.4)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], intensidad * 0.55)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  for i = 6, 1, -1 do
    local r = i * 120 * (1 - t * 1.2)
    if r > 0 then
      local a = (0.15 + t * 0.4) * (7 - i) / 6
      love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], a)
      love.graphics.setLineWidth(3)
      love.graphics.circle("line", transicion.origenX, transicion.origenY, r)
      love.graphics.setLineWidth(1)
    end
  end
  if t > 0.5 then
    local fadeT = (t - 0.5) / 0.5
    love.graphics.setColor(0, 0, 0, fadeT * fadeT)
    love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  end
end

local function iniciarTransicion(destino, x, y)
  if transicion.activa then return end
  transicion.activa = true
  transicion.timer = 0
  transicion.destino = destino
  transicion.origenX = x or (constantes.ANCHO_VIRTUAL / 2)
  transicion.origenY = y or (constantes.ALTO_VIRTUAL / 2)
end

local function irALobby(x, y)   iniciarTransicion("lobby", x, y) end
local function irAAjustes(x, y) iniciarTransicion("ajustes", x, y) end
local function irABeta(x, y)    iniciarTransicion("beta", x, y) end
local function irAMP(x, y)      iniciarTransicion("mp_lobby", x, y) end

local function activarBotonSeleccionado()
  local b = botones[indiceSeleccionado]
  if b and b.alPulsar then b.alPulsar() end
end

function menu.entrar()
  local Red = require("src.red")
  if Red.activo then Red.detener() end

  botones = {}
  luciernagas = {}
  rayos = {}
  runas = {}
  toques = {}
  tGlobal = 0
  timerLuciernaga = 0
  timerRuna = 0
  indiceSeleccionado = 1
  usandoTeclado = false

  transicion.activa = false
  transicion.timer = 0
  transicion.destino = nil

  glitch.timer = 3 + math.random() * 4
  glitch.activo = 0
  glitch.fuerza = 0

  for i = 1, 30 do
    table.insert(luciernagas, crearLuciernaga(true))
  end
  for i = 1, 10 do
    local r = crearRayo()
    r.y = math.random() * constantes.ALTO_VIRTUAL
    r.maxVida = r.vida
    table.insert(rayos, r)
  end
  for i = 1, 14 do
    local r = crearRuna()
    r.vida = math.random() * r.maxVida
    table.insert(runas, r)
  end

  local bw, bh = 240, 28
  local cx = constantes.ANCHO_VIRTUAL / 2 - bw / 2
  local y0 = 125
  local sp = 5

  local bJugar = Boton.nuevo(cx, y0, bw, bh, textos.menu.jugar, function()
    irALobby(cx + bw / 2, y0 + bh / 2)
  end)
  local bMP = Boton.nuevo(cx, y0 + (bh + sp), bw, bh, "Multijugador", function()
    irAMP(cx + bw / 2, y0 + bh + sp + bh / 2)
  end)
  local bOpc = Boton.nuevo(cx, y0 + (bh + sp) * 2, bw, bh, textos.menu.opciones, function()
    irAAjustes(cx + bw / 2, y0 + (bh + sp) * 2 + bh / 2)
  end)
  local bBeta = Boton.nuevo(cx, y0 + (bh + sp) * 3, bw, bh, "Beta", function()
    irABeta(cx + bw / 2, y0 + (bh + sp) * 3 + bh / 2)
  end)
  local bSalir = Boton.nuevo(cx, y0 + (bh + sp) * 4, bw, bh, textos.menu.salir, function()
    love.event.quit()
  end)

  table.insert(botones, bJugar)
  table.insert(botones, bMP)
  table.insert(botones, bOpc)
  table.insert(botones, bBeta)
  table.insert(botones, bSalir)
end

function menu.actualizar(dt)
  if transicion.activa then
    transicion.timer = transicion.timer + dt
    if transicion.timer >= transicion.duracion then
      local destino = transicion.destino
      transicion.activa = false
      if destino then Estados.cambiar(destino) end
    end
    return
  end

  tGlobal = tGlobal + dt

  if glitch.activo > 0 then
    glitch.activo = glitch.activo - dt
    glitch.fuerza = math.max(0, glitch.activo / 0.18)
  else
    glitch.timer = glitch.timer - dt
    if glitch.timer <= 0 then
      glitch.timer = 4 + math.random() * 5
      glitch.activo = 0.18
      glitch.fuerza = 1
    end
  end

  local it = 1
  while it <= #toques do
    local tg = toques[it]
    tg.vida = tg.vida - dt
    tg.radio = tg.radio + 120 * dt
    if tg.vida <= 0 then table.remove(toques, it) else it = it + 1 end
  end

  timerLuciernaga = timerLuciernaga - dt
  if timerLuciernaga <= 0 then
    timerLuciernaga = 0.08 + math.random() * 0.16
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
    if p.vida <= 0 or p.y < -30 then table.remove(luciernagas, il) else il = il + 1 end
  end

  local ir = 1
  while ir <= #rayos do
    local r = rayos[ir]
    r.y = r.y + r.vy * dt
    r.vida = r.vida - dt
    if r.vida <= 0 or r.y + r.largo < 0 then table.remove(rayos, ir) else ir = ir + 1 end
  end
  if math.random() < 0.5 and #rayos < 20 then
    local r = crearRayo()
    r.maxVida = r.vida
    table.insert(rayos, r)
  end

  timerRuna = timerRuna - dt
  if timerRuna <= 0 then
    timerRuna = 0.4 + math.random() * 0.7
    if #runas < MAX_RUNAS then table.insert(runas, crearRuna()) end
  end

  local iru = 1
  while iru <= #runas do
    local r = runas[iru]
    r.vida = r.vida + dt
    r.fase = r.fase + dt * r.velocidadPulso
    if r.boost and r.boost > 0 then r.boost = math.max(0, r.boost - dt * 2.5) end
    if r.vida >= r.maxVida then table.remove(runas, iru) else iru = iru + 1 end
  end
end

function menu.dibujar()
  dibujarFondo()
  dibujarLuzArcano()
  dibujarRayos()
  dibujarConexionesRunas()
  for _, r in ipairs(runas) do dibujarRuna(r) end
  dibujarLuciernagas()
  dibujarToques()

  local cx = constantes.ANCHO_VIRTUAL / 2
  local pulso = 0.5 + 0.5 * math.sin(tGlobal * 1.5)
  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.35 + pulso * 0.25)
  love.graphics.rectangle("fill", cx - 240, 62, 480, 1)
  love.graphics.rectangle("fill", cx - 240, 92, 480, 1)

  dibujarTitulo()
  dibujarSubtitulo()

  for i, b in ipairs(botones) do
    local esSel = (usandoTeclado and i == indiceSeleccionado)
    dibujarBotonArcano(b, i, b.presionado, esSel)
  end

  if love.system.getOS() ~= "Android" then
    local f = love.graphics.getFont()
    love.graphics.setColor(0.5, 0.6, 0.75, 0.7)
    local hint = "Flechas para navegar  -  Enter para seleccionar"
    love.graphics.print(hint, cx - f:getWidth(hint) / 2, constantes.ALTO_VIRTUAL - 36)
  end

  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.30)
  love.graphics.rectangle("fill", cx - 240, constantes.ALTO_VIRTUAL - 32, 480, 1)

  love.graphics.setColor(0.5, 0.65, 0.85, 0.7)
  love.graphics.print("v0.1", constantes.ANCHO_VIRTUAL - 40, constantes.ALTO_VIRTUAL - 20)

  dibujarTransicion()
end

local function sobreBoton(x, y)
  for i, b in ipairs(botones) do
    if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
      return i
    end
  end
  return nil
end

local function activarRunasCercanas(x, y)
  for _, r in ipairs(runas) do
    local dx, dy = r.x - x, r.y - y
    if dx * dx + dy * dy < 90 * 90 then r.boost = 1 end
  end
end

function menu.touchpressed(id, x, y)
  if transicion.activa then return end
  local idx = sobreBoton(x, y)
  if idx then
    indiceSeleccionado = idx
    usandoTeclado = false
    botones[idx]:touchpressed(id, x, y)
    return
  end
  crearToque(x, y)
  activarRunasCercanas(x, y)
end

function menu.touchreleased(id, x, y)
  if transicion.activa then return end
  for _, b in ipairs(botones) do
    if b:touchreleased(id, x, y) then return end
  end
end

function menu.mousepressed(x, y, bt)
  if transicion.activa then return end
  local idx = sobreBoton(x, y)
  if idx then
    indiceSeleccionado = idx
    usandoTeclado = false
    botones[idx]:mousepressed(x, y, bt)
    return
  end
  crearToque(x, y)
  activarRunasCercanas(x, y)
end

function menu.mousereleased(x, y, bt)
  if transicion.activa then return end
  for _, b in ipairs(botones) do
    if b:mousereleased(x, y, bt) then return end
  end
end

function menu.mousemoved(x, y)
  if transicion.activa then return end
  local idx = sobreBoton(x, y)
  if idx then
    indiceSeleccionado = idx
    usandoTeclado = false
  end
end

function menu.keypressed(key)
  if transicion.activa then return end

  if key == "up" or key == "w" then
    usandoTeclado = true
    indiceSeleccionado = indiceSeleccionado - 1
    if indiceSeleccionado < 1 then indiceSeleccionado = #botones end
  elseif key == "down" or key == "s" then
    usandoTeclado = true
    indiceSeleccionado = indiceSeleccionado + 1
    if indiceSeleccionado > #botones then indiceSeleccionado = 1 end
  elseif key == "return" or key == "kpenter" or key == "space" then
    activarBotonSeleccionado()
  elseif key == "escape" then
    love.event.quit()
  end
end

function menu.keyreleased(key) end
function menu.textinput(t) end

return menu