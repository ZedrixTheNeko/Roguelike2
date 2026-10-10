local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Guardado   = require("src.datos.guardado")
local Shaders    = require("src.utils.shaders")

local t = constantes.TILE

-- ============================================================
-- PALETA
-- ============================================================
local AZUL_MEDIO        = {0.15, 0.35, 0.75}
local AZUL_CELESTE      = {0.55, 0.85, 1.00}
local AZUL_CELESTE_CLARO= {0.75, 0.95, 1.00}
local PIEDRA            = {0.55, 0.55, 0.58}
local PIEDRA_CLARA      = {0.70, 0.70, 0.72}
local PIEDRA_OSCURA     = {0.35, 0.35, 0.38}

-- ============================================================
-- SUELO Y PAREDES (con culling)
-- ============================================================

local function dibujarSueloParedes()
  local anchoVis = constantes.ANCHO_VIRTUAL / L.zoom
  local altoVis  = constantes.ALTO_VIRTUAL  / L.zoom

  local tileIniX = math.max(1, math.floor(L.camX / t) - 1)
  local tileFinX = math.min(L.anchoTiles, math.ceil((L.camX + anchoVis) / t) + 1)
  local tileIniY = math.max(1, math.floor(L.camY / t) - 1)
  local tileFinY = math.min(L.altoTiles, math.ceil((L.camY + altoVis) / t) + 1)

  for y = tileIniY, tileFinY do
    local filaZona = L.dentroZona[y]
    local filaMapa = L.mapa[y]
    for x = tileIniX, tileFinX do
      if filaZona[x] then
        local px, py = (x - 1) * t, (y - 1) * t
        local tile = filaMapa[x]

        if tile == "." or tile == "D" or tile == "X" then
          if (x + y) % 2 == 0 then
            love.graphics.setColor(0.14, 0.16, 0.24)
          else
            love.graphics.setColor(0.11, 0.13, 0.20)
          end
          love.graphics.rectangle("fill", px, py, t, t)

          love.graphics.setColor(0.20, 0.24, 0.35, 0.4)
          love.graphics.rectangle("line", px, py, t, t)

          love.graphics.setColor(0.30, 0.40, 0.60, 0.08)
          love.graphics.rectangle("fill", px, py, 1, 1)
          love.graphics.rectangle("fill", px + t - 1, py + t - 1, 1, 1)

          if tile == "D" then
            local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 3 + x + y)
            love.graphics.setColor(AZUL_CELESTE[1], AZUL_CELESTE[2], AZUL_CELESTE[3], 0.10 + pulso * 0.08)
            love.graphics.rectangle("fill", px, py, t, t)
          end

        elseif tile == "#" then
          love.graphics.setColor(0.22, 0.24, 0.34)
          love.graphics.rectangle("fill", px, py, t, t)
          love.graphics.setColor(0.32, 0.36, 0.48)
          love.graphics.rectangle("line", px, py, t, t)
          love.graphics.setColor(0.16, 0.18, 0.26)
          love.graphics.rectangle("fill", px + 1, py + 8, t - 2, 1)
          love.graphics.rectangle("fill", px + 8, py + 1, 1, 7)
          love.graphics.setColor(0.40, 0.55, 0.85, 0.15)
          love.graphics.rectangle("fill", px, py, t, 1)
        end
      end
    end
  end
end

-- ============================================================
-- RUNAS
-- ============================================================

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
      table.insert(p, math.cos(a) * tamano); table.insert(p, math.sin(a) * tamano)
    end
    love.graphics.polygon("line", p)
  elseif tipo == 5 then
    local p = {}
    for i = 0, 5 do
      local a = i * math.pi / 3 - math.pi / 6
      table.insert(p, math.cos(a) * tamano); table.insert(p, math.sin(a) * tamano)
    end
    love.graphics.polygon("line", p)
  elseif tipo == 6 then
    love.graphics.circle("line", 0, 0, tamano)
  elseif tipo == 7 then
    local p = {}
    for i = 0, 24 do
      local tt = i / 24
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
  for _, p in ipairs(L.runas) do
    local alpha
    if p.vida < 0.5 then alpha = p.vida / 0.5
    elseif p.vida > p.maxVida - 0.6 then alpha = (p.maxVida - p.vida) / 0.6
    else alpha = 1 end
    alpha = math.max(0, math.min(1, alpha))
    local pulso = 0.55 + 0.45 * math.sin(p.fase)
    local alphaFinal = math.min(1, alpha * pulso) * 0.4

    love.graphics.push()
    love.graphics.translate(p.x, p.y)
    love.graphics.rotate(p.rotacion)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alphaFinal)
    dibujarRunaForma(p.tipo, p.tamano)
    love.graphics.pop()
  end
end

-- ============================================================
-- AURAS GRANDES
-- ============================================================

local function dibujarAurasGrandes()
  love.graphics.setBlendMode("add")

  local pulsoPortal = 0.5 + 0.5 * math.sin(L.tGlobal * 3)
  local pulsoGeneral = 0.5 + 0.5 * math.sin(L.tGlobal * 1.8)

  for i = 3, 1, -1 do
    local r = i * 16
    local a = (0.10 + pulsoPortal * 0.05) * (4 - i) / 3
    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], a)
    love.graphics.circle("fill", L.portalX, L.portalY, r)
  end

  for _, p in ipairs(L.pilares) do
    local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 2 + p.fase)
    love.graphics.setColor(AZUL_CELESTE[1], AZUL_CELESTE[2], AZUL_CELESTE[3], 0.10 + pulso * 0.06)
    love.graphics.circle("fill", p.x, p.y - 4, 20 + pulso * 4)
  end

  local pulsoLibro = 0.5 + 0.5 * math.sin(L.tGlobal * 2.5)
  love.graphics.setColor(1, 0.75, 0.35, 0.08 + pulsoLibro * 0.04)
  love.graphics.circle("fill", L.libroX, L.libroY - 4, 24)

  love.graphics.setColor(0.35, 0.10, 0.55, 0.08 + pulsoGeneral * 0.05)
  love.graphics.circle("fill", L.soulMasterX, L.soulMasterY - 14, 30)

  love.graphics.setBlendMode("alpha")
end

-- ============================================================
-- PORTAL
-- ============================================================

local function dibujarPortalBase()
  local pulsar = 0.5 + 0.5 * math.sin(L.tGlobal * 3)
  local pulsoEscala = 1 + pulsar * 0.12

  love.graphics.setColor(0.15, 0.45, 0.85, 0.10 + pulsar * 0.08)
  love.graphics.circle("fill", L.portalX, L.portalY, 55 + pulsar * 8)

  love.graphics.setColor(0.20, 0.55, 0.95, 0.35 + pulsar * 0.15)
  love.graphics.ellipse("fill", L.portalX, L.portalY, 32 * pulsoEscala, 12 * pulsoEscala)
  love.graphics.setColor(0.35, 0.75, 1.0, 0.55)
  love.graphics.ellipse("line", L.portalX, L.portalY, 28 * pulsoEscala, 10 * pulsoEscala)

  love.graphics.setColor(0.55, 0.85, 1.0, 0.85)
  love.graphics.ellipse("fill", L.portalX, L.portalY, 20, 8)

  love.graphics.setColor(0.90, 0.98, 1.0, 0.95)
  love.graphics.ellipse("fill", L.portalX, L.portalY, 12 * (0.8 + pulsar * 0.2), 5)

  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.ellipse("fill", L.portalX, L.portalY, 6, 2.5)

  for _, p in ipairs(L.particulasPortal) do
    love.graphics.setColor(0.6, 0.9, 1.0, p.vida * 0.8)
    love.graphics.circle("fill", p.x, p.y, p.radio)
  end
end

-- ============================================================
-- PILARES
-- ============================================================

local function dibujarPilarBase(p)
  local cx, cy = p.x, p.y
  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 2 + p.fase)

  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", cx, cy + 12, 14, 4)

  love.graphics.setColor(PIEDRA_OSCURA)
  love.graphics.ellipse("fill", cx, cy + 10, 14, 5)
  love.graphics.setColor(PIEDRA)
  love.graphics.ellipse("fill", cx, cy + 6, 12, 4)
  love.graphics.setColor(PIEDRA_CLARA)
  love.graphics.ellipse("line", cx, cy + 6, 12, 4)

  love.graphics.setColor(PIEDRA)
  love.graphics.rectangle("fill", cx - 6, cy - 32, 12, 40, 2)
  love.graphics.setColor(PIEDRA_CLARA)
  love.graphics.rectangle("fill", cx - 6, cy - 32, 3, 40, 2)
  love.graphics.setColor(PIEDRA_OSCURA)
  love.graphics.rectangle("fill", cx + 3, cy - 32, 3, 40, 2)

  for i = 0, 3 do
    local ry = cy - 28 + i * 10
    love.graphics.setColor(AZUL_CELESTE[1], AZUL_CELESTE[2], AZUL_CELESTE[3], 0.6 + pulso * 0.4)
    love.graphics.rectangle("fill", cx - 2, ry, 4, 4)
    love.graphics.setColor(AZUL_CELESTE_CLARO[1], AZUL_CELESTE_CLARO[2], AZUL_CELESTE_CLARO[3], 0.8)
    love.graphics.rectangle("fill", cx - 1, ry + 1, 2, 2)
  end

  love.graphics.setColor(PIEDRA)
  love.graphics.rectangle("fill", cx - 8, cy - 38, 16, 6, 2)
  love.graphics.setColor(PIEDRA_CLARA)
  love.graphics.rectangle("fill", cx - 8, cy - 38, 16, 2, 2)
end

local function dibujarPilarBrillo(p)
  local cx, cy = p.x, p.y
  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 2 + p.fase)

  love.graphics.setColor(AZUL_CELESTE[1], AZUL_CELESTE[2], AZUL_CELESTE[3], 0.7 + pulso * 0.3)
  love.graphics.circle("fill", cx, cy - 44, 5 + pulso * 1.5)
  love.graphics.setColor(AZUL_CELESTE_CLARO[1], AZUL_CELESTE_CLARO[2], AZUL_CELESTE_CLARO[3], 0.95)
  love.graphics.circle("fill", cx, cy - 44, 2.5)
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.circle("fill", cx, cy - 44, 1)

  for i = 1, 2 do
    local ang = L.tGlobal * 2 + i * math.pi + p.fase
    local rx = cx + math.cos(ang) * 12
    local ry = cy - 20 + math.sin(ang) * 6
    love.graphics.setColor(AZUL_CELESTE_CLARO[1], AZUL_CELESTE_CLARO[2], AZUL_CELESTE_CLARO[3], 0.7)
    love.graphics.circle("fill", rx, ry, 1.5)
  end
end

-- ============================================================
-- NPCs Y OBJETOS
-- ============================================================

local function dibujarMesaJoy(cx, cy)
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.ellipse("fill", cx, cy + 12, 24, 5)

  love.graphics.setColor(0.60, 0.42, 0.28)
  love.graphics.rectangle("fill", cx - 22, cy - 4, 44, 14, 3)
  love.graphics.setColor(0.78, 0.58, 0.40)
  love.graphics.rectangle("fill", cx - 22, cy - 4, 44, 3, 3)
  love.graphics.setColor(0.35, 0.22, 0.12)
  love.graphics.rectangle("line", cx - 22, cy - 4, 44, 14, 3)

  love.graphics.setColor(0.85, 0.30, 0.35, 0.8)
  love.graphics.rectangle("fill", cx - 16, cy - 14, 8, 10, 2)
  love.graphics.setColor(0.70, 0.70, 0.78)
  love.graphics.rectangle("fill", cx - 15, cy - 18, 6, 5)
  love.graphics.setColor(0.60, 0.42, 0.25)
  love.graphics.rectangle("fill", cx - 15, cy - 19, 6, 2)

  love.graphics.setColor(0.85, 0.82, 0.72)
  love.graphics.rectangle("fill", cx + 2, cy - 12, 14, 9, 1)
  love.graphics.setColor(0.35, 0.20, 0.12)
  love.graphics.rectangle("line", cx + 2, cy - 12, 14, 9, 1)
end

local function dibujarJoy(cx, cy)
  love.graphics.push()
  love.graphics.translate(cx, cy)

  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.ellipse("fill", 0, 22, 16, 4)

  love.graphics.setColor(0.95, 0.95, 0.98)
  love.graphics.polygon("fill", -12, -4, 12, -4, 14, 20, -14, 20)

  love.graphics.setColor(0.90, 0.25, 0.30)
  love.graphics.rectangle("fill", -6, 0, 12, 3)
  love.graphics.rectangle("fill", -1.5, -5, 3, 12)

  love.graphics.setColor(1, 0.85, 0.75)
  love.graphics.circle("fill", 0, -14, 9)

  love.graphics.setColor(0.95, 0.55, 0.75)
  love.graphics.arc("fill", 0, -18, 10, math.pi, math.pi * 2)
  love.graphics.rectangle("fill", -10, -18, 20, 4)
  love.graphics.circle("fill", -9, -12, 3)
  love.graphics.circle("fill", 9, -12, 3)

  love.graphics.setColor(0.15, 0.10, 0.15)
  love.graphics.circle("fill", -3, -14, 1.5)
  love.graphics.circle("fill", 3, -14, 1.5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", -3.4, -14.4, 0.5)
  love.graphics.circle("fill", 2.6, -14.4, 0.5)

  love.graphics.setColor(0.55, 0.20, 0.20)
  love.graphics.arc("line", "open", 0, -11, 2.5, 0.2, math.pi - 0.2)

  love.graphics.setColor(0.95, 0.95, 0.98)
  love.graphics.rectangle("fill", -9, -25, 18, 4)
  love.graphics.setColor(0.90, 0.25, 0.30)
  love.graphics.rectangle("fill", -1.5, -25, 3, 4)
  love.graphics.rectangle("fill", -4, -23.5, 8, 1.5)

  love.graphics.pop()
end

local function dibujarSoulMaster(cx, cy)
  love.graphics.push()
  love.graphics.translate(cx, cy)

  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.ellipse("fill", 0, 24, 18, 5)

  love.graphics.setColor(0.08, 0.06, 0.15)
  love.graphics.polygon("fill", -16, -4, 16, -4, 20, 22, -20, 22)

  love.graphics.setColor(0.15, 0.10, 0.25)
  love.graphics.polygon("fill", -12, -2, -8, -2, -10, 22, -16, 22)
  love.graphics.polygon("fill", 8, -2, 12, -2, 16, 22, 10, 22)

  love.graphics.setColor(0.45, 0.12, 0.15)
  love.graphics.polygon("fill", -8, -4, 8, -4, 8, 8, -8, 8)

  love.graphics.setColor(0.25, 0.25, 0.30)
  love.graphics.polygon("fill", -5, -10, 5, -10, 4, -6, -4, -6)
  love.graphics.setColor(0.50, 0.50, 0.55)
  love.graphics.circle("fill", 0, -8, 1.3)

  love.graphics.setColor(0.65, 0.65, 0.70)
  love.graphics.circle("fill", 0, -2, 1)
  love.graphics.circle("fill", 0, 2, 1)
  love.graphics.circle("fill", 0, 6, 1)

  love.graphics.setColor(0.05, 0.03, 0.10)
  love.graphics.polygon("fill", -12, -18, 12, -18, 8, -32, -8, -32)
  love.graphics.circle("fill", 0, -22, 9)

  love.graphics.setColor(0.02, 0.01, 0.05)
  love.graphics.ellipse("fill", 0, -22, 7, 8)

  love.graphics.setColor(0.95, 0.55, 1.0)
  love.graphics.circle("fill", -2.5, -22, 1.8)
  love.graphics.circle("fill", 2.5, -22, 1.8)

  love.graphics.setColor(0.85, 0.85, 0.90)
  love.graphics.circle("fill", -18, 2 + math.sin(L.tGlobal * 1.5) * 1, 3)
  love.graphics.circle("fill", 18, 2 + math.sin(L.tGlobal * 1.5 + 1) * 1, 3)

  love.graphics.pop()
end

local function dibujarLibro(cx, cy)
  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 2.5)

  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", cx, cy + 10, 20, 5)

  love.graphics.setColor(PIEDRA_OSCURA)
  love.graphics.rectangle("fill", cx - 14, cy + 2, 28, 8)
  love.graphics.setColor(PIEDRA)
  love.graphics.rectangle("fill", cx - 12, cy - 2, 24, 6)
  love.graphics.setColor(PIEDRA_CLARA)
  love.graphics.rectangle("fill", cx - 12, cy - 2, 24, 2)

  love.graphics.setColor(0.35, 0.10, 0.20)
  love.graphics.rectangle("fill", cx - 14, cy - 18, 28, 18, 2)
  love.graphics.setColor(0.55, 0.15, 0.30)
  love.graphics.rectangle("fill", cx - 14, cy - 18, 28, 3, 2)
  love.graphics.setColor(0.20, 0.05, 0.12)
  love.graphics.rectangle("line", cx - 14, cy - 18, 28, 18, 2)

  love.graphics.setColor(0.95, 0.80, 0.40)
  love.graphics.rectangle("fill", cx - 15, cy - 18, 3, 18)
  love.graphics.setColor(1, 0.95, 0.65)
  love.graphics.rectangle("fill", cx - 15, cy - 18, 3, 2)

  love.graphics.setColor(1, 0.85, 0.40, 0.85 + pulso * 0.15)
  love.graphics.polygon("fill",
    cx, cy - 12,
    cx + 4, cy - 8,
    cx, cy - 4,
    cx - 4, cy - 8)
  love.graphics.setColor(1, 0.95, 0.70, 0.95)
  love.graphics.circle("fill", cx - 1, cy - 9, 1)
end

local function dibujarCapsula(cx, cy)
  local t2 = L.tGlobal
  local pulso = 0.5 + 0.5 * math.sin(t2 * 2)

  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.ellipse("fill", cx, cy + 18, 24, 5)

  love.graphics.setColor(0.25, 0.28, 0.35)
  love.graphics.ellipse("fill", cx, cy + 14, 22, 6)
  love.graphics.setColor(0.35, 0.40, 0.50)
  love.graphics.ellipse("fill", cx, cy + 12, 22, 6)

  love.graphics.setColor(0.40, 0.75, 1.00, 0.7 + pulso * 0.3)
  love.graphics.setLineWidth(2)
  love.graphics.ellipse("line", cx, cy + 14, 20, 5)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.15, 0.30, 0.55, 0.5)
  love.graphics.rectangle("fill", cx - 16, cy - 40, 32, 54, 4)

  love.graphics.setColor(0.40, 0.75, 1.00, 0.35 + pulso * 0.15)
  love.graphics.rectangle("fill", cx - 14, cy - 38, 28, 50, 3)
  love.graphics.setColor(0.65, 0.90, 1.00, 0.25 + pulso * 0.10)
  love.graphics.rectangle("fill", cx - 10, cy - 35, 20, 44, 3)

  love.graphics.setColor(0.80, 0.95, 1.00, 0.3)
  love.graphics.rectangle("fill", cx - 12, cy - 36, 2, 46)

  love.graphics.setColor(0.55, 0.85, 1.00, 0.85)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", cx - 16, cy - 40, 32, 54, 4)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.30, 0.35, 0.45)
  love.graphics.ellipse("fill", cx, cy - 40, 16, 6)
  love.graphics.setColor(0.45, 0.50, 0.60)
  love.graphics.ellipse("fill", cx, cy - 42, 16, 6)

  for i = -1, 1 do
    local fase = t2 * 3 + i
    local encendido = 0.5 + 0.5 * math.sin(fase)
    love.graphics.setColor(0.40 + encendido * 0.6, 0.85, 1.00, 0.5 + encendido * 0.5)
    love.graphics.circle("fill", cx + i * 6, cy - 42, 1.8)
  end
end

local function dibujarComputadora(cx, cy)
  local t2 = L.tGlobal
  local pulso = 0.5 + 0.5 * math.sin(t2 * 4)

  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.ellipse("fill", cx, cy + 14, 16, 4)

  love.graphics.setColor(0.20, 0.22, 0.30)
  love.graphics.rectangle("fill", cx - 12, cy + 8, 24, 6, 2)
  love.graphics.setColor(0.30, 0.35, 0.45)
  love.graphics.rectangle("fill", cx - 12, cy + 8, 24, 2, 2)

  love.graphics.setColor(0.25, 0.30, 0.40)
  love.graphics.rectangle("fill", cx - 3, cy - 4, 6, 14)

  love.graphics.setColor(0.15, 0.18, 0.26)
  love.graphics.rectangle("fill", cx - 16, cy - 22, 32, 22, 3)
  love.graphics.setColor(0.30, 0.35, 0.48)
  love.graphics.rectangle("line", cx - 16, cy - 22, 32, 22, 3)

  love.graphics.setColor(0.20, 0.60, 0.90)
  love.graphics.rectangle("fill", cx - 13, cy - 19, 26, 16, 2)

  love.graphics.setColor(0.65, 0.95, 1.00, 0.85)
  for i = 0, 4 do
    local ancho = 4 + ((i * 7 + math.floor(t2 * 4)) % 12)
    love.graphics.rectangle("fill", cx - 11, cy - 17 + i * 3, ancho, 1)
  end

  if pulso > 0.5 then
    love.graphics.setColor(0.65, 0.95, 1.00)
    love.graphics.rectangle("fill", cx - 11, cy - 5, 3, 1.5)
  end

  for i = 0, 2 do
    local enc = 0.5 + 0.5 * math.sin(t2 * 5 + i * 1.5)
    local colors = {{0.3, 0.9, 0.4}, {1.0, 0.7, 0.2}, {0.4, 0.7, 1.0}}
    love.graphics.setColor(colors[i+1][1], colors[i+1][2], colors[i+1][3], 0.4 + enc * 0.6)
    love.graphics.circle("fill", cx + 14, cy - 12 + i * 4, 1.2)
  end

  love.graphics.setColor(0.18, 0.20, 0.28)
  love.graphics.rectangle("fill", cx - 14, cy + 2, 28, 4, 1)
  love.graphics.setColor(0.30, 0.35, 0.48)
  for i = 0, 6 do
    love.graphics.rectangle("fill", cx - 12 + i * 4, cy + 3, 2, 2)
  end
end

-- ============================================================
-- PARTICULAS
-- ============================================================

local function dibujarLuciernagas()
  for _, p in ipairs(L.particulasMagicas) do
    local alpha
    if p.vida > p.maxVida - 0.6 then alpha = (p.maxVida - p.vida) / 0.6
    elseif p.vida < 0.6 then alpha = p.vida / 0.6
    else alpha = 1 end
    alpha = math.max(0, math.min(1, alpha)) * p.brillo

    local pulso = 0.85 + 0.15 * math.sin(p.fase + L.tGlobal * 3)

    love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], alpha * 0.35 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio * 2.5)

    love.graphics.setColor(AZUL_CELESTE[1], AZUL_CELESTE[2], AZUL_CELESTE[3], alpha * 0.7 * pulso)
    love.graphics.circle("fill", p.x, p.y, p.radio)

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.4)
  end
end

local function dibujarAmbiente()
  for _, p in ipairs(L.particulasAmbiente) do
    local a = math.min(1, p.vida / p.maxVida) * 0.55
    if p.tipo == 1 then
      love.graphics.setColor(0.55, 0.75, 1.0, a)
    elseif p.tipo == 2 then
      love.graphics.setColor(0.85, 0.75, 1.0, a)
    else
      love.graphics.setColor(1.0, 0.85, 0.55, a)
    end
    love.graphics.circle("fill", p.x, p.y, p.radio)
  end
end

local function dibujarParticulasCambio(lista)
  for _, p in ipairs(lista) do
    local alpha = p.vida / p.maxVida
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.4)
    love.graphics.circle("fill", p.x, p.y, p.radio * 3)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.4)
  end
end

-- ============================================================
-- BRILLOS PEQUENOS
-- ============================================================

local function dibujarBrillosPequenos()
  love.graphics.setBlendMode("add")

  local pulsoLibro = 0.5 + 0.5 * math.sin(L.tGlobal * 2.5)

  for _, p in ipairs(L.pilares) do
    dibujarPilarBrillo(p)
  end

  for i = 1, 4 do
    local ang = L.tGlobal * 1.2 + i * math.pi / 2
    local fx = L.libroX + math.cos(ang) * 20
    local fy = L.libroY - 25 + math.sin(ang) * 6
    love.graphics.setColor(1, 0.85, 0.50, 0.6 + pulsoLibro * 0.3)
    love.graphics.circle("fill", fx, fy, 2)
  end

  local pulsoCompu = 0.5 + 0.5 * math.sin(L.tGlobal * 4)
  love.graphics.setColor(0.15, 0.55, 0.85, 0.25 + pulsoCompu * 0.10)
  love.graphics.rectangle("fill", L.computadoraX - 13, L.computadoraY - 29, 26, 16, 2)

  local pulsoCaps = 0.5 + 0.5 * math.sin(L.tGlobal * 2)
  love.graphics.setColor(0.40, 0.80, 1.00, 0.15 + pulsoCaps * 0.10)
  love.graphics.rectangle("fill", L.capsulaX - 14, L.capsulaY - 46, 28, 50, 3)

  love.graphics.setBlendMode("alpha")
end

-- ============================================================
-- HUD ARCANO
-- ============================================================

-- Boton estilo menu (con esquinas decoradas)
local function dibujarBotonArcano(b, colorBase, esHover)
  local x, y, w, h = b.x, b.y, b.w, b.h

  -- Fondo
  love.graphics.setColor(0.08, 0.12, 0.24, 0.92)
  love.graphics.rectangle("fill", x, y, w, h, 4)
  love.graphics.setColor(0.20, 0.32, 0.58, 0.45)
  love.graphics.rectangle("fill", x, y, w, h * 0.5, 4)
  love.graphics.setColor(0.02, 0.04, 0.10, 0.5)
  love.graphics.rectangle("fill", x, y + h * 0.6, w, h * 0.4, 4)

  -- Borde
  if esHover then
    love.graphics.setColor(1.0, 0.80, 0.30, 0.95)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.7)
  end
  love.graphics.rectangle("line", x, y, w, h, 4)

  -- Linea superior brillante
  if esHover then
    love.graphics.setColor(1.0, 0.95, 0.65, 0.9)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.7)
  end
  love.graphics.rectangle("fill", x + 10, y + 1.5, w - 20, 1.5)

  -- Esquinas en L
  local colEsq = esHover and {1.0, 0.85, 0.35} or colorBase
  local aEsq = esHover and 1.0 or 0.8
  local s = 6
  love.graphics.setColor(colEsq[1], colEsq[2], colEsq[3], aEsq)
  love.graphics.setLineWidth(1.8)
  love.graphics.line(x + 2, y + 2, x + 2 + s, y + 2)
  love.graphics.line(x + 2, y + 2, x + 2, y + 2 + s)
  love.graphics.line(x + w - 2, y + 2, x + w - 2 - s, y + 2)
  love.graphics.line(x + w - 2, y + 2, x + w - 2, y + 2 + s)
  love.graphics.line(x + 2, y + h - 2, x + 2 + s, y + h - 2)
  love.graphics.line(x + 2, y + h - 2, x + 2, y + h - 2 - s)
  love.graphics.line(x + w - 2, y + h - 2, x + w - 2 - s, y + h - 2)
  love.graphics.line(x + w - 2, y + h - 2, x + w - 2, y + h - 2 - s)
  love.graphics.setLineWidth(1)

  -- Texto
  local f = love.graphics.getFont()
  local tw = f:getWidth(b.texto)
  local th = f:getHeight()
  local tx = x + (w - tw) / 2
  local ty = y + (h - th) / 2

  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.print(b.texto, tx + 1, ty + 1)

  if esHover then
    love.graphics.setColor(1.0, 0.85, 0.35, 0.7)
    love.graphics.print(b.texto, tx - 1, ty)
    love.graphics.print(b.texto, tx + 1, ty)
    love.graphics.print(b.texto, tx, ty - 1)
    love.graphics.print(b.texto, tx, ty + 1)
    love.graphics.setColor(1, 0.98, 0.85)
  else
    love.graphics.setColor(colorBase[1] + 0.35, colorBase[2] + 0.35, colorBase[3] + 0.35, 0.85)
    love.graphics.print(b.texto, tx - 1, ty)
    love.graphics.print(b.texto, tx + 1, ty)
    love.graphics.print(b.texto, tx, ty - 1)
    love.graphics.print(b.texto, tx, ty + 1)
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.print(b.texto, tx, ty)
end

local function dibujarHUD()
  local COLOR_AZUL = {0.55, 0.85, 1.00}
  local COLOR_DORADO = {1.00, 0.80, 0.30}

  -- Boton interactuar
  if not L.botonInteractuar.oculto then
    dibujarBotonArcano(L.botonInteractuar, COLOR_AZUL, L.botonInteractuar.presionado)
  end

  -- Gemas (panel arcano)
  local gemas = Guardado.get("gemas") or 0
  local f = love.graphics.getFont()
  local gw, gh = 140, 40
  local gx = constantes.ANCHO_VIRTUAL - gw - 12
  local gy = 12

  love.graphics.setColor(0.05, 0.08, 0.15, 0.85)
  love.graphics.rectangle("fill", gx, gy, gw, gh, 6)
  love.graphics.setColor(COLOR_AZUL[1], COLOR_AZUL[2], COLOR_AZUL[3], 0.7)
  love.graphics.rectangle("line", gx, gy, gw, gh, 6)

  -- Esquinas
  local s = 6
  love.graphics.setColor(COLOR_DORADO[1], COLOR_DORADO[2], COLOR_DORADO[3], 0.9)
  love.graphics.setLineWidth(2)
  love.graphics.line(gx + 3, gy + 3, gx + 3 + s, gy + 3)
  love.graphics.line(gx + 3, gy + 3, gx + 3, gy + 3 + s)
  love.graphics.line(gx + gw - 3, gy + 3, gx + gw - 3 - s, gy + 3)
  love.graphics.line(gx + gw - 3, gy + 3, gx + gw - 3, gy + 3 + s)
  love.graphics.line(gx + 3, gy + gh - 3, gx + 3 + s, gy + gh - 3)
  love.graphics.line(gx + 3, gy + gh - 3, gx + 3, gy + gh - 3 - s)
  love.graphics.line(gx + gw - 3, gy + gh - 3, gx + gw - 3 - s, gy + gh - 3)
  love.graphics.line(gx + gw - 3, gy + gh - 3, gx + gw - 3, gy + gh - 3 - s)
  love.graphics.setLineWidth(1)

  -- Icono gema
  love.graphics.setColor(COLOR_AZUL[1], COLOR_AZUL[2], COLOR_AZUL[3])
  love.graphics.polygon("fill",
    gx + 24, gy + 12,
    gx + 32, gy + 20,
    gx + 24, gy + 28,
    gx + 16, gy + 20)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.polygon("line",
    gx + 24, gy + 12,
    gx + 32, gy + 20,
    gx + 24, gy + 28,
    gx + 16, gy + 20)

  love.graphics.setColor(0.95, 0.95, 1.00)
  love.graphics.print("Gemas", gx + 44, gy + 6, 0, 0.85, 0.85)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(tostring(gemas), gx + 44, gy + 20, 0, 1.1, 1.1)

  -- Panel de zona (arriba izquierda, arcano)
  local zona = "Lobby"
  local px, py = L.robin.x, L.robin.y
  if px > 23 * t and px < 57 * t and py > 1 * t and py < 21 * t then
    zona = "Sala del Portal"
  elseif px > 35 * t and px < 45 * t and py > 19 * t and py < 31 * t then
    zona = "Pasillo"
  elseif px > 55 * t and px < 79 * t and py > 31 * t and py < 51 * t then
    zona = "Selector de Personajes"
  elseif px > 1 * t and px < 25 * t and py > 19 * t and py < 35 * t then
    zona = "Invocacion de Mascotas"
  elseif px > 1 * t and px < 25 * t and py > 33 * t and py < 53 * t then
    zona = "Tiendas de Variados"
  end

  local zw, zh = 200, 30
  local zx, zy = 12, 12

  love.graphics.setColor(0.05, 0.08, 0.15, 0.85)
  love.graphics.rectangle("fill", zx, zy, zw, zh, 5)
  love.graphics.setColor(COLOR_DORADO[1], COLOR_DORADO[2], COLOR_DORADO[3], 0.7)
  love.graphics.rectangle("line", zx, zy, zw, zh, 5)

  love.graphics.setColor(COLOR_DORADO[1], COLOR_DORADO[2], COLOR_DORADO[3], 0.85)
  love.graphics.setLineWidth(2)
  love.graphics.line(zx + 2, zy + 2, zx + 2 + s, zy + 2)
  love.graphics.line(zx + 2, zy + 2, zx + 2, zy + 2 + s)
  love.graphics.line(zx + zw - 2, zy + 2, zx + zw - 2 - s, zy + 2)
  love.graphics.line(zx + zw - 2, zy + 2, zx + zw - 2, zy + 2 + s)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.95, 0.88, 0.70)
  love.graphics.print(zona, zx + 16, zy + 8)
end

-- ============================================================
-- DIBUJO PRINCIPAL
-- ============================================================

function L.dibujar()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  love.graphics.push()
  love.graphics.scale(L.zoom, L.zoom)
  love.graphics.translate(-L.camX, -L.camY)

  -- ============================================================
  -- PASADA 1: suelo, paredes, runas (alpha)
  -- ============================================================
  dibujarSueloParedes()
  L.fxSeguro(L.fxSuelo)
  dibujarRunasFondo()

  -- ============================================================
  -- PASADA 2: auras grandes (aditivo)
  -- ============================================================
  dibujarAurasGrandes()
  L.fxSeguro(L.fxRunasPortal)

  -- ============================================================
  -- PASADA 3: objetos y personajes (alpha)
  -- ============================================================
  dibujarPortalBase()
  L.fxSeguro(L.fxVortice)

  for _, p in ipairs(L.pilares) do
    dibujarPilarBase(p)
  end

  dibujarMesaJoy(L.joyX, L.joyY + 6)
  dibujarJoy(L.joyX, L.joyY - 8)
  dibujarSoulMaster(L.soulMasterX, L.soulMasterY)
  dibujarLibro(L.libroX, L.libroY)
  dibujarComputadora(L.computadoraX, L.computadoraY)
  dibujarCapsula(L.capsulaX, L.capsulaY)

  dibujarAmbiente()
  dibujarLuciernagas()

  -- Robin (o partículas si esta en cambio)
  local cp = L.cambioPersonaje
  local mostrarRobin = true
  if cp.activo then
    if cp.fase == "esperando" then
      mostrarRobin = false
    elseif cp.fase == "apareciendo" and not cp.movido then
      mostrarRobin = false
    end
  end

  if mostrarRobin and L.escalaRobin > 0.01 then
    love.graphics.push()
    love.graphics.translate(L.robin.x, L.robin.y)
    love.graphics.scale(L.escalaRobin, L.escalaRobin)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.ellipse("fill", 0, 9, 8, 3)
    L.robin:dibujarSinArma(0, 0, 1)
    love.graphics.pop()
  end

  -- Partículas del cambio (por encima de Robin)
  if cp.activo then
    dibujarParticulasCambio(cp.particulasViejas)
    dibujarParticulasCambio(cp.particulasNuevas)
  end

  -- Luces suaves, haces de luz y niebla (shaders con respaldo)
  L.fxSeguro(L.fxLuces)
  L.fxSeguro(L.fxHaces)
  L.fxSeguro(L.fxNiebla)

  -- ============================================================
  -- PASADA 4: brillos pequeños (aditivo)
  -- ============================================================
  dibujarBrillosPequenos()

  love.graphics.pop()

  -- ============================================================
  -- UI (fuera de la camara)
  -- ============================================================
  if L.estado == "explorando" and not L.cambioPersonaje.activo then
    L.joyMover:dibujar()
  end

  dibujarHUD()
  L.fxSeguro(L.fxUI)

  -- Dialogo
  if L.estado == "dialogo" then
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

    local pw, ph = 460, 300
    local dpx = (constantes.ANCHO_VIRTUAL - pw) / 2
    local dpy = (constantes.ALTO_VIRTUAL - ph) / 2

    love.graphics.setColor(0.08, 0.10, 0.18, 0.98)
    love.graphics.rectangle("fill", dpx, dpy, pw, ph, 8)
    love.graphics.setColor(0.55, 0.85, 1.00)
    love.graphics.rectangle("line", dpx, dpy, pw, ph, 8)

    -- Esquinas
    local s = 8
    love.graphics.setColor(1.0, 0.80, 0.30, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.line(dpx + 4, dpy + 4, dpx + 4 + s, dpy + 4)
    love.graphics.line(dpx + 4, dpy + 4, dpx + 4, dpy + 4 + s)
    love.graphics.line(dpx + pw - 4, dpy + 4, dpx + pw - 4 - s, dpy + 4)
    love.graphics.line(dpx + pw - 4, dpy + 4, dpx + pw - 4, dpy + 4 + s)
    love.graphics.line(dpx + 4, dpy + ph - 4, dpx + 4 + s, dpy + ph - 4)
    love.graphics.line(dpx + 4, dpy + ph - 4, dpx + 4, dpy + ph - 4 - s)
    love.graphics.line(dpx + pw - 4, dpy + ph - 4, dpx + pw - 4 - s, dpy + ph - 4)
    love.graphics.line(dpx + pw - 4, dpy + ph - 4, dpx + pw - 4, dpy + ph - 4 - s)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.45, 0.65, 0.95)
    love.graphics.rectangle("fill", dpx + 20, dpy + 42, pw - 40, 1)

    love.graphics.setColor(1.0, 0.85, 0.40)
    local f2 = love.graphics.getFont()
    local tw2 = f2:getWidth(L.dialogoTitulo or "") * 1.1
    love.graphics.print(L.dialogoTitulo or "", (constantes.ANCHO_VIRTUAL - tw2) / 2, dpy + 16, 0, 1.1, 1.1)

    love.graphics.setColor(0.90, 0.92, 0.98)
    for i, linea in ipairs(L.dialogoTexto or {}) do
      love.graphics.print(linea, dpx + 24, dpy + 60 + (i - 1) * 18)
    end

    dibujarBotonArcano(L.botonCerrar, {0.55, 0.85, 1.00}, L.botonCerrar.presionado)
  end

  -- Confirmacion del portal
  if L.estado == "preguntando" then
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

    local pw, ph = 300, 140
    local dpx = (constantes.ANCHO_VIRTUAL - pw) / 2
    local dpy = (constantes.ALTO_VIRTUAL - ph) / 2

    love.graphics.setColor(0.08, 0.10, 0.18, 0.98)
    love.graphics.rectangle("fill", dpx, dpy, pw, ph, 8)
    love.graphics.setColor(0.55, 0.85, 1.00)
    love.graphics.rectangle("line", dpx, dpy, pw, ph, 8)

    local s = 8
    love.graphics.setColor(1.0, 0.80, 0.30, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.line(dpx + 4, dpy + 4, dpx + 4 + s, dpy + 4)
    love.graphics.line(dpx + 4, dpy + 4, dpx + 4, dpy + 4 + s)
    love.graphics.line(dpx + pw - 4, dpy + 4, dpx + pw - 4 - s, dpy + 4)
    love.graphics.line(dpx + pw - 4, dpy + 4, dpx + pw - 4, dpy + 4 + s)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    local f3 = love.graphics.getFont()
    local txt = "Entrar a la mazmorra?"
    local tw3 = f3:getWidth(txt)
    love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw3) / 2, dpy + 30)

    love.graphics.setColor(0.75, 0.85, 0.95)
    local txt2 = "Nivel 1 - Castillo de piedra"
    local tw4 = f3:getWidth(txt2) * 0.9
    love.graphics.print(txt2, (constantes.ANCHO_VIRTUAL - tw4) / 2, dpy + 52, 0, 0.9, 0.9)

    dibujarBotonArcano(L.botonSi, {0.55, 1.00, 0.65}, L.botonSi.presionado)
    dibujarBotonArcano(L.botonNo, {1.00, 0.55, 0.55}, L.botonNo.presionado)
  end

  if L.estado == "seleccion" then
    L.dibujarSelector()
  end

  if L.fadeAlpha > 0 then
    love.graphics.setColor(0, 0, 0, L.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  end
end

return L