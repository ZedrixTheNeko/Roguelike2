local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local Biomas     = require("src.datos.biomas")

local function pal()
  return (J.salaActual and J.salaActual.bioma) or Biomas.lista[1]
end

local function hash(x, y)
  return (x * 73856093 + y * 19349663) % 997
end

-- ============================================================
-- SUELO
-- ============================================================
function J.dibujarSuelo(rx, ry)
  local t = constantes.TILE
  local B = pal()
  local tiempo = love.timer.getTime()
  local s1, s2, ln = B.suelo1, B.suelo2, B.linea
  local det = B.detalleSuelo

  for y = 1, J.salaActual.H do
    for x = 1, J.salaActual.W do
      local px = rx + (x - 1) * t
      local py = ry + (y - 1) * t

      if (x + y) % 2 == 0 then
        love.graphics.setColor(s1[1], s1[2], s1[3])
      else
        love.graphics.setColor(s2[1], s2[2], s2[3])
      end
      love.graphics.rectangle("fill", px, py, t, t)

      love.graphics.setColor(ln[1], ln[2], ln[3], det == "runas" and 0.9 or 0.6)
      love.graphics.rectangle("line", px, py, t, t)

      love.graphics.setColor(0.35, 0.40, 0.55, 0.06)
      love.graphics.rectangle("fill", px, py, 1, 1)
      love.graphics.rectangle("fill", px + t - 1, py + t - 1, 1, 1)

      local h = hash(x, y)

      if det == "grietas" then
        if h % 17 == 0 then
          love.graphics.setColor(0.08, 0.07, 0.11, 0.7)
          love.graphics.line(px + 3, py + 4, px + 8, py + 8, px + 12, py + 7)
        end

      elseif det == "hierba" then
        if h % 4 == 0 then
          love.graphics.setColor(0.22, 0.42, 0.18, 0.9)
          love.graphics.line(px + 4, py + 12, px + 3, py + 8)
          love.graphics.line(px + 6, py + 12, px + 7, py + 7)
          love.graphics.line(px + 8, py + 12, px + 10, py + 8)
        end
        if h % 23 == 0 then
          love.graphics.setColor(0.95, 0.85, 0.35, 0.9)
          love.graphics.circle("fill", px + 11, py + 5, 1)
        end

      elseif det == "lava" then
        if h % 14 == 0 then
          local a = 0.45 + 0.35 * math.sin(tiempo * 2 + h)
          love.graphics.setColor(1.0, 0.45, 0.10, a)
          love.graphics.line(px + 2, py + 12, px + 7, py + 8, px + 10, py + 9, px + 14, py + 4)
          love.graphics.setColor(1.0, 0.80, 0.30, a * 0.6)
          love.graphics.line(px + 7, py + 8, px + 10, py + 9)
        end

      elseif det == "hielo" then
        if h % 11 == 0 then
          love.graphics.setColor(0.90, 0.97, 1.0, 0.35)
          love.graphics.line(px + 3, py + 12, px + 8, py + 5)
          love.graphics.line(px + 6, py + 13, px + 9, py + 9)
        end
        if h % 29 == 0 then
          local a = 0.3 + 0.5 * math.max(0, math.sin(tiempo * 3 + h))
          love.graphics.setColor(1, 1, 1, a)
          love.graphics.rectangle("fill", px + 10, py + 4, 2, 2)
        end

      elseif det == "runas" then
        if h % 29 == 0 then
          local a = 0.25 + 0.30 * math.sin(tiempo * 1.5 + h)
          love.graphics.setColor(0.70, 0.35, 1.0, a)
          love.graphics.circle("line", px + 8, py + 8, 4)
          love.graphics.line(px + 8, py + 4, px + 8, py + 12)
          love.graphics.line(px + 4, py + 8, px + 12, py + 8)
        end
      end
    end
  end
end

-- ============================================================
-- HELPERS DE DIBUJO
-- ============================================================
local function sombra(px, py, w)
  love.graphics.setColor(0, 0, 0, 0.40)
  love.graphics.ellipse("fill", px + 8, py + 15, w or 8, 2.5)
end

-- ============================================================
-- ESTILOS DE OBSTACULOS POR BIOMA
-- ============================================================
local ESTILOS = {}

-- ---------- Catacumbas (los originales, por letra) ----------
local PIEDRA = {}

PIEDRA.X = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", px + 8, py + 14, 7, 2)
  love.graphics.setColor(0.42, 0.28, 0.16)
  love.graphics.rectangle("fill", px + 1, py + 3, 14, 11, 1)
  love.graphics.setColor(0.58, 0.40, 0.22)
  love.graphics.rectangle("fill", px + 1, py + 3, 14, 3, 1)
  love.graphics.setColor(0.30, 0.18, 0.10)
  love.graphics.rectangle("line", px + 1, py + 3, 14, 11, 1)
  love.graphics.rectangle("fill", px + 7, py + 3, 2, 11)
  love.graphics.rectangle("fill", px + 1, py + 8, 14, 1)
  love.graphics.setColor(0.75, 0.65, 0.30)
  love.graphics.circle("fill", px + 4, py + 6, 0.8)
  love.graphics.circle("fill", px + 12, py + 6, 0.8)
end

PIEDRA.B = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", px + 8, py + 14, 7, 2)
  love.graphics.setColor(0.40, 0.28, 0.18)
  love.graphics.rectangle("fill", px + 2, py + 2, 12, 13, 3)
  love.graphics.setColor(0.55, 0.38, 0.22)
  love.graphics.ellipse("fill", px + 8, py + 3, 6, 2.5)
  love.graphics.ellipse("fill", px + 8, py + 14, 6, 2.5)
  love.graphics.setColor(0.28, 0.18, 0.10)
  love.graphics.ellipse("line", px + 8, py + 3, 6, 2.5)
  love.graphics.ellipse("line", px + 8, py + 14, 6, 2.5)
  love.graphics.setColor(0.55, 0.55, 0.60)
  love.graphics.rectangle("fill", px + 2, py + 5, 12, 1.5)
  love.graphics.rectangle("fill", px + 2, py + 11, 12, 1.5)
  love.graphics.setColor(0.70, 0.70, 0.75)
  love.graphics.rectangle("fill", px + 2, py + 5, 12, 0.5)
  love.graphics.rectangle("fill", px + 2, py + 11, 12, 0.5)
end

PIEDRA.P = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.40)
  love.graphics.ellipse("fill", px + 8, py + 15, 8, 2.5)
  love.graphics.setColor(0.28, 0.28, 0.34)
  love.graphics.rectangle("fill", px, py + 12, 16, 4)
  love.graphics.setColor(0.40, 0.40, 0.48)
  love.graphics.rectangle("fill", px + 1, py + 11, 14, 2)
  love.graphics.setColor(0.42, 0.42, 0.50)
  love.graphics.rectangle("fill", px + 2, py - 2, 12, 14)
  love.graphics.setColor(0.55, 0.55, 0.62)
  love.graphics.rectangle("fill", px + 3, py - 2, 3, 14)
  love.graphics.setColor(0.25, 0.25, 0.32)
  love.graphics.rectangle("fill", px + 10, py - 2, 3, 14)
  love.graphics.setColor(0.35, 0.35, 0.42)
  love.graphics.rectangle("fill", px + 2, py + 2, 12, 1)
  love.graphics.rectangle("fill", px + 2, py + 7, 12, 1)
  love.graphics.setColor(0.40, 0.40, 0.48)
  love.graphics.rectangle("fill", px, py - 4, 16, 3)
  love.graphics.setColor(0.55, 0.55, 0.62)
  love.graphics.rectangle("fill", px, py - 4, 16, 1)
end

PIEDRA.C = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.40)
  love.graphics.ellipse("fill", px + 8, py + 15, 8, 2.5)
  love.graphics.setColor(0.28, 0.28, 0.34)
  love.graphics.rectangle("fill", px, py + 12, 16, 4)
  love.graphics.setColor(0.42, 0.42, 0.50)
  love.graphics.rectangle("fill", px + 2, py + 4, 12, 9)
  love.graphics.setColor(0.55, 0.55, 0.62)
  love.graphics.rectangle("fill", px + 3, py + 4, 3, 9)
  love.graphics.setColor(0.25, 0.25, 0.32)
  love.graphics.rectangle("fill", px + 10, py + 4, 3, 9)
  love.graphics.setColor(0.42, 0.42, 0.50)
  love.graphics.polygon("fill", px + 2, py + 4, px + 5, py + 1, px + 8, py + 3, px + 11, py + 1, px + 14, py + 4)
end

PIEDRA.S = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.ellipse("fill", px + 8, py + 15, 8, 2.5)
  love.graphics.setColor(0.30, 0.30, 0.36)
  love.graphics.rectangle("fill", px + 1, py + 12, 14, 3)
  love.graphics.setColor(0.45, 0.45, 0.52)
  love.graphics.rectangle("fill", px + 2, py + 11, 12, 1.5)
  love.graphics.setColor(0.45, 0.45, 0.52)
  love.graphics.rectangle("fill", px + 4, py + 4, 8, 8, 1)
  love.graphics.setColor(0.55, 0.55, 0.62)
  love.graphics.rectangle("fill", px + 4, py + 4, 8, 2)
  love.graphics.setColor(0.50, 0.50, 0.58)
  love.graphics.circle("fill", px + 8, py + 1, 3.5)
  love.graphics.setColor(0.65, 0.65, 0.72)
  love.graphics.circle("fill", px + 7, py, 1)
  love.graphics.setColor(0.75, 0.75, 0.80)
  love.graphics.rectangle("fill", px + 12, py - 3, 1.5, 12)
  love.graphics.setColor(0.55, 0.45, 0.30)
  love.graphics.rectangle("fill", px + 11, py + 6, 4, 2)
end

-- ---------- Bosque ----------
ESTILOS.arbol = function(px, py)
  sombra(px, py, 9)
  love.graphics.setColor(0.30, 0.20, 0.12)
  love.graphics.rectangle("fill", px + 5, py + 4, 6, 11)
  love.graphics.setColor(0.42, 0.29, 0.17)
  love.graphics.rectangle("fill", px + 5, py + 4, 2, 11)
  love.graphics.setColor(0.16, 0.12, 0.07)
  love.graphics.rectangle("fill", px + 9, py + 5, 2, 10)
  love.graphics.setColor(0.10, 0.28, 0.12)
  love.graphics.circle("fill", px + 8, py - 4, 9)
  love.graphics.setColor(0.16, 0.38, 0.16)
  love.graphics.circle("fill", px + 4, py - 1, 6)
  love.graphics.circle("fill", px + 12, py - 1, 6)
  love.graphics.setColor(0.24, 0.50, 0.22)
  love.graphics.circle("fill", px + 6, py - 6, 4)
  love.graphics.setColor(0.45, 0.75, 0.35, 0.6)
  love.graphics.circle("fill", px + 5, py - 7, 1.8)
end

ESTILOS.tocon = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.30, 0.20, 0.12)
  love.graphics.rectangle("fill", px + 2, py + 6, 12, 8, 2)
  love.graphics.setColor(0.52, 0.38, 0.22)
  love.graphics.ellipse("fill", px + 8, py + 6, 6, 3)
  love.graphics.setColor(0.38, 0.26, 0.14)
  love.graphics.ellipse("line", px + 8, py + 6, 3.5, 1.7)
  love.graphics.setColor(0.28, 0.55, 0.22)
  love.graphics.circle("fill", px + 3, py + 9, 1.6)
  love.graphics.circle("fill", px + 13, py + 11, 1.2)
end

ESTILOS.hongo = function(px, py)
  sombra(px, py, 6)
  local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 2 + px)
  love.graphics.setColor(0.85, 0.82, 0.70)
  love.graphics.rectangle("fill", px + 6, py + 7, 4, 8)
  love.graphics.setColor(0.60, 0.20, 0.55)
  love.graphics.ellipse("fill", px + 8, py + 6, 8, 5)
  love.graphics.setColor(0.80, 0.35, 0.75)
  love.graphics.ellipse("fill", px + 7, py + 4, 6, 3)
  love.graphics.setColor(0.95, 0.90, 0.60, 0.5 + pulso * 0.4)
  love.graphics.circle("fill", px + 5, py + 5, 1.2)
  love.graphics.circle("fill", px + 10, py + 4, 1)
  love.graphics.setColor(0.7, 1.0, 0.5, 0.10 + pulso * 0.08)
  love.graphics.circle("fill", px + 8, py + 8, 13)
end

ESTILOS.tronco = function(px, py)
  sombra(px, py, 8)
  love.graphics.setColor(0.32, 0.21, 0.12)
  love.graphics.rectangle("fill", px + 1, py + 6, 14, 8, 3)
  love.graphics.setColor(0.44, 0.30, 0.17)
  love.graphics.rectangle("fill", px + 1, py + 6, 14, 3, 3)
  love.graphics.setColor(0.52, 0.38, 0.22)
  love.graphics.ellipse("fill", px + 2, py + 10, 2, 3.5)
  love.graphics.setColor(0.25, 0.50, 0.20)
  love.graphics.rectangle("fill", px + 6, py + 5, 6, 2)
end

-- ---------- Magma ----------
ESTILOS.basalto = function(px, py)
  sombra(px, py, 8)
  love.graphics.setColor(0.16, 0.12, 0.13)
  love.graphics.polygon("fill", px + 2, py + 14, px + 3, py - 3, px + 8, py - 5, px + 13, py - 3, px + 14, py + 14)
  love.graphics.setColor(0.26, 0.19, 0.19)
  love.graphics.polygon("fill", px + 3, py + 14, px + 3, py - 3, px + 7, py - 4, px + 7, py + 14)
  local a = 0.5 + 0.4 * math.sin(love.timer.getTime() * 2.5 + px * 0.3)
  love.graphics.setColor(1.0, 0.45, 0.10, a)
  love.graphics.line(px + 9, py - 2, px + 10, py + 3, px + 8, py + 7, px + 10, py + 12)
end

ESTILOS.roca_ardiente = function(px, py)
  sombra(px, py, 8)
  love.graphics.setColor(0.22, 0.15, 0.14)
  love.graphics.polygon("fill", px + 1, py + 14, px + 3, py + 5, px + 8, py + 2, px + 13, py + 5, px + 15, py + 14)
  love.graphics.setColor(0.34, 0.24, 0.22)
  love.graphics.polygon("fill", px + 3, py + 5, px + 8, py + 2, px + 9, py + 8, px + 4, py + 9)
  local a = 0.45 + 0.35 * math.sin(love.timer.getTime() * 3 + py)
  love.graphics.setColor(1.0, 0.50, 0.12, a)
  love.graphics.line(px + 5, py + 12, px + 8, py + 9, px + 12, py + 11)
  love.graphics.setColor(1.0, 0.55, 0.15, a * 0.15)
  love.graphics.circle("fill", px + 8, py + 9, 13)
end

ESTILOS.obelisco = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.18, 0.12, 0.13)
  love.graphics.polygon("fill", px + 3, py + 14, px + 5, py - 6, px + 8, py - 9, px + 11, py - 6, px + 13, py + 14)
  love.graphics.setColor(0.30, 0.20, 0.20)
  love.graphics.polygon("fill", px + 5, py - 6, px + 8, py - 9, px + 8, py + 14, px + 3, py + 14)
  local a = 0.6 + 0.4 * math.sin(love.timer.getTime() * 2)
  love.graphics.setColor(1.0, 0.40, 0.10, a)
  love.graphics.circle("fill", px + 8, py - 1, 2.6)
  love.graphics.setColor(1.0, 0.85, 0.40, a)
  love.graphics.circle("fill", px + 8, py - 1, 1.2)
end

ESTILOS.obsidiana = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.10, 0.08, 0.14)
  love.graphics.rectangle("fill", px + 2, py + 3, 12, 11, 1)
  love.graphics.setColor(0.22, 0.18, 0.30)
  love.graphics.polygon("fill", px + 2, py + 3, px + 14, py + 3, px + 11, py + 6, px + 5, py + 6)
  love.graphics.setColor(0.55, 0.40, 0.75, 0.6)
  love.graphics.line(px + 4, py + 8, px + 6, py + 12)
end

ESTILOS.geiser = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.20, 0.13, 0.12)
  love.graphics.polygon("fill", px + 1, py + 14, px + 4, py + 7, px + 12, py + 7, px + 15, py + 14)
  love.graphics.setColor(0.05, 0.02, 0.02)
  love.graphics.ellipse("fill", px + 8, py + 7, 4, 1.8)
  local t = love.timer.getTime()
  local a = 0.5 + 0.5 * math.sin(t * 4 + px)
  love.graphics.setColor(1.0, 0.45, 0.10, 0.35 + a * 0.4)
  love.graphics.circle("fill", px + 8, py + 5 - a * 3, 2.4)
  love.graphics.setColor(1.0, 0.85, 0.40, 0.5 * a)
  love.graphics.circle("fill", px + 7, py + 1 - a * 4, 1.2)
end

-- ---------- Glaciar ----------
ESTILOS.cristal = function(px, py)
  sombra(px, py, 8)
  love.graphics.setColor(0.40, 0.65, 0.85, 0.9)
  love.graphics.polygon("fill", px + 3, py + 14, px + 5, py + 1, px + 8, py - 7, px + 11, py + 1, px + 13, py + 14)
  love.graphics.setColor(0.70, 0.90, 1.0, 0.9)
  love.graphics.polygon("fill", px + 5, py + 1, px + 8, py - 7, px + 8, py + 14, px + 3, py + 14)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.line(px + 6, py + 2, px + 6, py + 11)
  love.graphics.setColor(0.45, 0.75, 1.0, 0.45)
  love.graphics.polygon("fill", px + 11, py + 14, px + 13, py + 6, px + 16, py + 14)
  local a = 0.1 + 0.08 * math.sin(love.timer.getTime() * 2 + px)
  love.graphics.setColor(0.6, 0.9, 1.0, a)
  love.graphics.circle("fill", px + 8, py + 4, 13)
end

ESTILOS.bloque_hielo = function(px, py)
  sombra(px, py, 8)
  love.graphics.setColor(0.55, 0.75, 0.92)
  love.graphics.rectangle("fill", px + 1, py + 4, 14, 10, 2)
  love.graphics.setColor(0.80, 0.93, 1.0)
  love.graphics.rectangle("fill", px + 1, py + 4, 14, 3, 2)
  love.graphics.setColor(0.35, 0.55, 0.78)
  love.graphics.rectangle("line", px + 1, py + 4, 14, 10, 2)
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.line(px + 4, py + 9, px + 7, py + 12)
end

ESTILOS.estatua_hielo = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.50, 0.70, 0.88, 0.95)
  love.graphics.rectangle("fill", px + 4, py + 2, 8, 12, 2)
  love.graphics.circle("fill", px + 8, py - 1, 3.5)
  love.graphics.setColor(0.85, 0.95, 1.0, 0.8)
  love.graphics.rectangle("fill", px + 4, py + 2, 3, 12, 2)
  love.graphics.setColor(0.30, 0.50, 0.75)
  love.graphics.rectangle("line", px + 4, py + 2, 8, 12, 2)
  love.graphics.setColor(0.75, 0.90, 1.0)
  love.graphics.polygon("fill", px + 12, py + 14, px + 14, py + 8, px + 16, py + 14)
end

ESTILOS.nieve = function(px, py)
  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.ellipse("fill", px + 8, py + 14, 7, 2)
  love.graphics.setColor(0.88, 0.94, 1.0)
  love.graphics.ellipse("fill", px + 8, py + 10, 7, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.ellipse("fill", px + 7, py + 8, 5, 3)
  love.graphics.setColor(0.65, 0.78, 0.92, 0.8)
  love.graphics.ellipse("line", px + 8, py + 10, 7, 5)
end

ESTILOS.barril_hielo = function(px, py)
  PIEDRA.B(px, py)
  love.graphics.setColor(0.80, 0.93, 1.0, 0.55)
  love.graphics.rectangle("fill", px + 2, py + 2, 12, 13, 3)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.rectangle("fill", px + 3, py + 3, 2, 8)
end

-- ---------- Vacio ----------
ESTILOS.monolito = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.10, 0.06, 0.16)
  love.graphics.polygon("fill", px + 3, py + 14, px + 4, py - 8, px + 12, py - 8, px + 13, py + 14)
  love.graphics.setColor(0.20, 0.12, 0.30)
  love.graphics.polygon("fill", px + 4, py - 8, px + 8, py - 8, px + 8, py + 14, px + 3, py + 14)
  local a = 0.5 + 0.5 * math.sin(love.timer.getTime() * 1.8 + px)
  love.graphics.setColor(0.75, 0.40, 1.0, 0.4 + a * 0.5)
  love.graphics.line(px + 9, py - 4, px + 11, py - 4)
  love.graphics.line(px + 9, py + 1, px + 11, py + 1)
  love.graphics.line(px + 9, py + 6, px + 11, py + 6)
  love.graphics.setColor(0.60, 0.30, 0.90, 0.08 + a * 0.06)
  love.graphics.circle("fill", px + 8, py + 2, 14)
end

ESTILOS.fragmento = function(px, py)
  local t = love.timer.getTime()
  local fl = math.sin(t * 1.5 + px) * 2
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", px + 8, py + 15, 6 - fl * 0.3, 2)
  love.graphics.setColor(0.28, 0.14, 0.42)
  love.graphics.polygon("fill", px + 8, py + 1 + fl, px + 14, py + 8 + fl, px + 8, py + 13 + fl, px + 2, py + 8 + fl)
  love.graphics.setColor(0.50, 0.28, 0.75)
  love.graphics.polygon("fill", px + 8, py + 1 + fl, px + 14, py + 8 + fl, px + 8, py + 8 + fl)
  love.graphics.setColor(0.85, 0.65, 1.0, 0.6)
  love.graphics.line(px + 8, py + 1 + fl, px + 8, py + 13 + fl)
end

ESTILOS.ojo_piedra = function(px, py)
  PIEDRA.S(px, py)
  local a = 0.5 + 0.5 * math.sin(love.timer.getTime() * 2 + px)
  love.graphics.setColor(0.10, 0.05, 0.15)
  love.graphics.ellipse("fill", px + 8, py + 7, 4, 2.5)
  love.graphics.setColor(0.80, 0.40, 1.0, 0.5 + a * 0.5)
  love.graphics.circle("fill", px + 8, py + 7, 1.6)
end

ESTILOS.cubo_vacio = function(px, py)
  sombra(px, py, 7)
  love.graphics.setColor(0.12, 0.07, 0.20)
  love.graphics.rectangle("fill", px + 2, py + 3, 12, 11, 1)
  love.graphics.setColor(0.30, 0.16, 0.48)
  love.graphics.rectangle("fill", px + 2, py + 3, 12, 3, 1)
  local a = 0.4 + 0.4 * math.sin(love.timer.getTime() * 2.2 + py)
  love.graphics.setColor(0.80, 0.50, 1.0, a)
  love.graphics.rectangle("line", px + 2, py + 3, 12, 11, 1)
  love.graphics.circle("fill", px + 8, py + 9, 1.5)
end

ESTILOS.orbe_cautivo = function(px, py)
  sombra(px, py, 6)
  love.graphics.setColor(0.18, 0.10, 0.28)
  love.graphics.rectangle("fill", px + 4, py + 11, 8, 4)
  local t = love.timer.getTime()
  local a = 0.5 + 0.5 * math.sin(t * 2.5 + px)
  love.graphics.setColor(0.55, 0.25, 0.90, 0.6)
  love.graphics.circle("fill", px + 8, py + 6, 5.5)
  love.graphics.setColor(0.85, 0.65, 1.0, 0.4 + a * 0.5)
  love.graphics.circle("fill", px + 7, py + 5, 2.5)
  love.graphics.setColor(0.80, 0.50, 1.0, 0.8)
  love.graphics.circle("line", px + 8, py + 6, 6)
end

-- ============================================================
-- DECORACIONES (objetos solidos y escombros)
-- ============================================================
function J.dibujarDecoracionesSuelo(rx, ry)
  local t = constantes.TILE
  local B = pal()
  local estilos = B.estilos

  for y = 1, J.salaActual.H do
    for x = 1, J.salaActual.W do
      local tile = J.salaActual.mapa[y][x]
      local px = rx + (x - 1) * t
      local py = ry + (y - 1) * t

      if tile == "R" then
        love.graphics.setColor(0.30, 0.28, 0.32)
        love.graphics.circle("fill", px + 5, py + 6, 1.5)
        love.graphics.circle("fill", px + 11, py + 10, 1)
        love.graphics.setColor(0.40, 0.38, 0.42)
        love.graphics.circle("fill", px + 8, py + 12, 0.8)
      elseif tile == "X" or tile == "B" or tile == "P" or tile == "C" or tile == "S" then
        local estilo = estilos[tile]
        local f = ESTILOS[estilo]
        if estilo == "piedra" or not f then
          PIEDRA[tile](px, py)
        else
          f(px, py)
        end
      end
    end
  end
end

-- ============================================================
-- PAREDES
-- ============================================================
function J.dibujarParedes(rx, ry)
  local t = constantes.TILE
  local B = pal()
  local pa, pl, pb, mu = B.pared, B.paredLinea, B.paredLuz, B.musgo
  local ll = B.llama
  local tiempo = love.timer.getTime()

  for y = 1, J.salaActual.H do
    for x = 1, J.salaActual.W do
      local tile = J.salaActual.mapa[y][x]
      local px = rx + (x - 1) * t
      local py = ry + (y - 1) * t

      if tile == "#" or tile == "T" then
        love.graphics.setColor(pa[1], pa[2], pa[3])
        love.graphics.rectangle("fill", px, py, t, t)

        love.graphics.setColor(pl[1], pl[2], pl[3])
        love.graphics.rectangle("fill", px, py + 7, t, 1)
        love.graphics.rectangle("fill", px + 8, py, 1, 7)
        love.graphics.rectangle("fill", px + 4, py + 8, 1, 8)

        love.graphics.setColor(pb[1], pb[2], pb[3], 0.5)
        love.graphics.rectangle("fill", px, py, t, 1)

        love.graphics.setColor(pl[1] * 0.8, pl[2] * 0.8, pl[3] * 0.8, 0.6)
        love.graphics.rectangle("fill", px, py + t - 1, t, 1)

        if tile == "#" and (x * 7 + y * 13) % 11 == 0 then
          love.graphics.setColor(mu[1], mu[2], mu[3], 0.7)
          love.graphics.circle("fill", px + 4, py + 11, 2)
          love.graphics.circle("fill", px + 9, py + 13, 1.5)
        end

        if tile == "T" then
          love.graphics.setColor(0.30, 0.25, 0.18)
          love.graphics.rectangle("fill", px + 7, py + 6, 2, 6)
          love.graphics.setColor(0.50, 0.40, 0.22)
          love.graphics.rectangle("fill", px + 5, py + 11, 6, 2)

          local pulso1 = 0.5 + 0.5 * math.sin(tiempo * 8 + x * 1.3 + y * 0.7)
          local pulso2 = 0.5 + 0.5 * math.sin(tiempo * 6 + y * 1.7)

          love.graphics.setColor(ll[1][1], ll[1][2], ll[1][3], 0.65)
          love.graphics.ellipse("fill", px + 8, py + 2, 4 + pulso1 * 1.5, 5 + pulso2)
          love.graphics.setColor(ll[2][1], ll[2][2], ll[2][3], 0.9)
          love.graphics.ellipse("fill", px + 8, py + 2, 2.5, 3.5)
          love.graphics.setColor(ll[3][1], ll[3][2], ll[3][3], 0.95)
          love.graphics.ellipse("fill", px + 8, py + 2, 1.2, 1.8)

          love.graphics.setColor(ll[1][1], ll[1][2], ll[1][3], 0.08 + pulso1 * 0.06)
          love.graphics.circle("fill", px + 8, py + 3, 18 + pulso1 * 4)
        end

      elseif tile == "D" then
        local c = ll[2]
        love.graphics.setColor(c[1] * 0.5, c[2] * 0.6, c[3] * 0.9, 0.5)
        love.graphics.rectangle("fill", px, py, t, t)
        love.graphics.setColor(c[1], c[2], c[3], 0.75)
        love.graphics.rectangle("line", px + 1, py + 1, t - 2, t - 2)
        love.graphics.setColor(0.90, 0.95, 1.0, 0.5)
        love.graphics.rectangle("fill", px + 3, py + 3, t - 6, t - 6)
      end
    end
  end
end

return J