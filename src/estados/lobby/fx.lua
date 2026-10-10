-- ============================================================
-- LOBBY FX: iluminacion, antorchas, sombras de profundidad, runas del
-- portal, haces de luz, niebla, banner de zona, insignia de personaje,
-- indicador de interaccion y brujula hacia el portal.
-- Todo se ejecuta dentro de pcall (L.fxSeguro): si algo falla se apaga
-- el efecto y el lobby sigue funcionando.
-- ============================================================
local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Shaders    = require("src.utils.shaders")
local Personajes = require("src.datos.personajes")

local t = constantes.TILE
local PI = math.pi

L.fxT = 0
L.fxZona = nil
L.fxBanner = nil
L.fxLookX, L.fxLookY = 0, 0
L.fxAntorchas = nil
L.fxApagado = false

function L.fxSeguro(f, ...)
  if L.fxApagado then return end
  local ok, err = pcall(f, ...)
  if not ok then
    L.fxApagado = true
    love.graphics.setBlendMode("alpha")
    pcall(love.graphics.setShader)
    print("[LOBBY FX] desactivado por error: " .. tostring(err))
  end
end

function L.fxReset()
  L.fxAntorchas = nil
  L.fxZona = nil
  L.fxBanner = nil
  L.fxLookX, L.fxLookY = 0, 0
end

local function hash(x, y)
  return (x * 73856093 + y * 19349663) % 997
end

local function zonaDe(px, py)
  if px > 23 * t and px < 57 * t and py > 1 * t and py < 21 * t then return "Sala del Portal"
  elseif px > 35 * t and px < 45 * t and py > 19 * t and py < 31 * t then return "Pasillo"
  elseif px > 55 * t and px < 79 * t and py > 31 * t and py < 51 * t then return "Selector de Personajes"
  elseif px > 1 * t and px < 25 * t and py > 19 * t and py < 35 * t then return "Invocacion de Mascotas"
  elseif px > 1 * t and px < 25 * t and py > 33 * t and py < 53 * t then return "Tiendas de Variados"
  end
  return "Lobby"
end

-- ------------------------------------------------------------
-- ACTUALIZACION
-- ------------------------------------------------------------
function L.fxActualizar(dt)
  if L.fxApagado or not L.robin then return end
  L.fxT = L.fxT + dt

  local z = zonaDe(L.robin.x, L.robin.y)
  if z ~= L.fxZona then
    L.fxZona = z
    L.fxBanner = { texto = z, t = 0, dur = 2.6 }
  end
  if L.fxBanner then
    L.fxBanner.t = L.fxBanner.t + dt
    if L.fxBanner.t >= L.fxBanner.dur then L.fxBanner = nil end
  end

  -- adelanto de camara en la direccion de movimiento
  local tx, ty = 0, 0
  if L.joyMover and L.joyMover.activo and L.estado == "explorando" then
    tx = L.joyMover.dx * L.joyMover.magnitud * 20
    ty = L.joyMover.dy * L.joyMover.magnitud * 14
  end
  local k = math.min(1, dt * 2.5)
  L.fxLookX = L.fxLookX + (tx - L.fxLookX) * k
  L.fxLookY = L.fxLookY + (ty - L.fxLookY) * k
end

-- ------------------------------------------------------------
-- ANTORCHAS (se colocan en las paredes que dan a suelo)
-- ------------------------------------------------------------
local function prepararAntorchas()
  L.fxAntorchas = {}
  for y = 2, L.altoTiles - 1 do
    for x = 2, L.anchoTiles - 1 do
      if L.dentroZona[y][x] and L.mapa[y][x] == "#" then
        local abajo = L.mapa[y + 1] and L.mapa[y + 1][x]
        if abajo == "." and L.dentroZona[y + 1] and L.dentroZona[y + 1][x]
           and (x * 7 + y * 3) % 9 == 0 and #L.fxAntorchas < 48 then
          table.insert(L.fxAntorchas, {
            x = (x - 1) * t + 8, y = (y - 1) * t + 3, fase = (x * 1.7 + y * 0.9),
          })
        end
      end
    end
  end
end

local function visible(x, y, margen)
  local anchoVis = constantes.ANCHO_VIRTUAL / L.zoom
  local altoVis = constantes.ALTO_VIRTUAL / L.zoom
  return x > L.camX - margen and x < L.camX + anchoVis + margen
     and y > L.camY - margen and y < L.camY + altoVis + margen
end

-- ------------------------------------------------------------
-- SUELO Y PAREDES: profundidad, grietas, runas tenues, antorchas
-- ------------------------------------------------------------
function L.fxSuelo()
  if not L.fxAntorchas then prepararAntorchas() end
  local anchoVis = constantes.ANCHO_VIRTUAL / L.zoom
  local altoVis = constantes.ALTO_VIRTUAL / L.zoom
  local x0 = math.max(2, math.floor(L.camX / t) - 1)
  local x1 = math.min(L.anchoTiles - 1, math.ceil((L.camX + anchoVis) / t) + 1)
  local y0 = math.max(2, math.floor(L.camY / t) - 1)
  local y1 = math.min(L.altoTiles - 1, math.ceil((L.camY + altoVis) / t) + 1)
  local tg = L.tGlobal

  for y = y0, y1 do
    local fila = L.mapa[y]
    local arriba = L.mapa[y - 1]
    local zona = L.dentroZona[y]
    for x = x0, x1 do
      if zona[x] then
        local tile = fila[x]
        local px, py = (x - 1) * t, (y - 1) * t
        if tile == "." or tile == "D" or tile == "X" then
          -- sombras de profundidad junto a las paredes
          if arriba[x] == "#" then
            love.graphics.setColor(0, 0, 0, 0.40)
            love.graphics.rectangle("fill", px, py, t, 4)
            love.graphics.setColor(0, 0, 0, 0.20)
            love.graphics.rectangle("fill", px, py + 4, t, 5)
          end
          if fila[x - 1] == "#" then
            love.graphics.setColor(0, 0, 0, 0.26)
            love.graphics.rectangle("fill", px, py, 3, t)
          end
          if fila[x + 1] == "#" then
            love.graphics.setColor(0, 0, 0, 0.26)
            love.graphics.rectangle("fill", px + t - 3, py, 3, t)
          end

          local h = hash(x, y)
          if h % 19 == 0 then
            love.graphics.setColor(0.04, 0.05, 0.10, 0.55)
            love.graphics.line(px + 3, py + 4, px + 8, py + 8, px + 12, py + 7)
          elseif h % 31 == 0 then
            love.graphics.setColor(0.30, 0.34, 0.48, 0.55)
            love.graphics.circle("fill", px + 5 + (h % 5), py + 10, 1.1)
          elseif h % 53 == 0 then
            local a = 0.15 + 0.2 * math.sin(tg * 1.6 + h)
            love.graphics.setColor(0.45, 0.80, 1.0, a)
            love.graphics.circle("line", px + 8, py + 8, 4)
            love.graphics.line(px + 8, py + 4, px + 8, py + 12)
          end
        elseif tile == "#" then
          local h = hash(x, y)
          if h % 5 == 0 then
            love.graphics.setColor(0.55, 0.65, 0.95, 0.06)
            love.graphics.rectangle("fill", px + 1, py + 1, t - 2, 6)
          end
          local abajo = L.mapa[y + 1] and L.mapa[y + 1][x]
          if abajo == "." then
            -- cara frontal iluminada de la pared
            love.graphics.setColor(0.45, 0.60, 0.95, 0.22)
            love.graphics.rectangle("fill", px, py + t - 2, t, 2)
            love.graphics.setColor(0, 0, 0, 0.25)
            love.graphics.rectangle("fill", px, py + t - 6, t, 3)
          end
          if h % 23 == 0 and abajo == "." then
            local a = 0.25 + 0.25 * math.sin(tg * 2 + h)
            love.graphics.setColor(0.45, 0.85, 1.0, a)
            love.graphics.line(px + 4, py + 4, px + 8, py + 9, px + 12, py + 4)
          end
        end
      end
    end
  end

  -- antorchas
  for _, a in ipairs(L.fxAntorchas) do
    if visible(a.x, a.y, 40) then
      L.dibujarAntorcha(a.x, a.y, a.fase)
    end
  end
end

-- ------------------------------------------------------------
-- RUNAS GIRATORIAS ALREDEDOR DEL PORTAL (aditivo, perspectiva plana)
-- ------------------------------------------------------------
function L.fxRunasPortal()
  love.graphics.setBlendMode("add")
  local cx, cy = L.portalX, L.portalY
  local rot = L.fxT * 0.35
  local pulso = 0.5 + 0.5 * math.sin(L.fxT * 2.2)

  for anillo = 1, 3 do
    local R = (anillo == 1) and 66 or ((anillo == 2) and 52 or 40)
    local segs = (anillo == 1) and 32 or ((anillo == 2) and 20 or 12)
    local dir = (anillo == 2) and -1 or 1
    for i = 0, segs - 1 do
      if i % 2 == 0 then
        local a1 = rot * dir + i * PI * 2 / segs
        local a2 = a1 + PI * 2 / segs * 0.7
        local c1, s1 = math.cos(a1), math.sin(a1)
        local c2, s2 = math.cos(a2), math.sin(a2)
        love.graphics.setColor(0.35, 0.75, 1.0, 0.18 + 0.20 * pulso)
        love.graphics.line(cx + c1 * R, cy + s1 * R * 0.38, cx + c2 * R, cy + s2 * R * 0.38)
      end
    end
  end

  -- glifos
  for i = 0, 5 do
    local a = -rot * 1.4 + i * PI / 3
    local gx = cx + math.cos(a) * 59
    local gy = cy + math.sin(a) * 59 * 0.38
    love.graphics.setColor(0.75, 0.95, 1.0, 0.35 + 0.3 * pulso)
    love.graphics.polygon("line", gx, gy - 3, gx + 2.5, gy, gx, gy + 3, gx - 2.5, gy)
  end
  love.graphics.setBlendMode("alpha")
end

-- ------------------------------------------------------------
-- LUCES
-- ------------------------------------------------------------
function L.fxLuces()
  local tg = L.fxT
  local pP = 0.5 + 0.5 * math.sin(tg * 3)

  -- portal
  Shaders.luz(L.portalX, L.portalY - 6, 120, 0.20, 0.50, 1.0, 0.45 + 0.15 * pP)

  -- pilares
  for i, p in ipairs(L.pilares) do
    local pu = 0.5 + 0.5 * math.sin(tg * 2 + p.fase)
    Shaders.luz(p.x, p.y - 4, 52, 0.45, 0.85, 1.0, 0.28 + 0.12 * pu)
  end

  Shaders.luz(L.joyX, L.joyY - 6, 54, 1.0, 0.78, 0.45, 0.30)
  Shaders.luz(L.soulMasterX, L.soulMasterY - 12, 64, 0.60, 0.25, 0.95, 0.32 + 0.08 * math.sin(tg * 1.8))
  Shaders.luz(L.libroX, L.libroY - 4, 48, 1.0, 0.75, 0.35, 0.30 + 0.1 * math.sin(tg * 2.5))
  Shaders.luz(L.computadoraX, L.computadoraY - 6, 52, 0.30, 0.90, 1.0, 0.26)
  Shaders.luz(L.capsulaX, L.capsulaY - 6, 58, 0.30, 1.0, 0.80, 0.26)

  -- antorchas (con parpadeo)
  if L.fxAntorchas then
    for _, a in ipairs(L.fxAntorchas) do
      if visible(a.x, a.y, 90) then
        local fl = 0.5 + 0.5 * math.sin(tg * 9 + a.fase) * 0.5 + 0.25 * math.sin(tg * 5.3 + a.fase * 2)
        Shaders.luz(a.x, a.y + 4, 70, 0.45, 0.62, 1.0, 0.22 + 0.10 * fl)
      end
    end
  end

  -- aura calida alrededor del jugador
  if L.robin then
    Shaders.luz(L.robin.x, L.robin.y, 40, 1.0, 0.95, 0.85, 0.10)
  end
end

-- ------------------------------------------------------------
-- HACES DE LUZ DESDE EL TECHO (sala del portal)
-- ------------------------------------------------------------
function L.fxHaces()
  love.graphics.setBlendMode("add")
  local tg = L.fxT
  local base = { -150, -75, 85, 160 }
  for i, dx in ipairs(base) do
    local sway = math.sin(tg * 0.4 + i * 1.7) * 10
    local ancho = 16 + 6 * math.sin(tg * 0.6 + i)
    local xTop = L.portalX + dx + sway
    local xBot = xTop - 26
    local yTop = L.portalY - 170
    local yBot = L.portalY + 30
    if visible(xTop, (yTop + yBot) / 2, 140) then
      local rebanadas = 7
      for s = 0, rebanadas - 1 do
        local k0 = s / rebanadas
        local k1 = (s + 1) / rebanadas
        local ya, yb = yTop + (yBot - yTop) * k0, yTop + (yBot - yTop) * k1
        local xa, xb = xTop + (xBot - xTop) * k0, xTop + (xBot - xTop) * k1
        local wa, wb = ancho * (1 + k0 * 0.8), ancho * (1 + k1 * 0.8)
        local alfa = 0.040 * (1 - k0) * (0.8 + 0.2 * math.sin(tg * 0.9 + i))
        love.graphics.setColor(0.55, 0.78, 1.0, alfa)
        love.graphics.polygon("fill", xa - wa, ya, xa + wa, ya, xb + wb, yb, xb - wb, yb)
      end
    end
  end
  love.graphics.setBlendMode("alpha")
end

-- ------------------------------------------------------------
-- NIEBLA (shader) anclada al mundo
-- ------------------------------------------------------------
function L.fxNiebla()
  if not Shaders.activo then return end
  local anchoVis = constantes.ANCHO_VIRTUAL / L.zoom
  local altoVis = constantes.ALTO_VIRTUAL / L.zoom
  local esc = 3.0
  Shaders.niebla(L.camX, L.camY, anchoVis, altoVis, {
    color = { 0.45, 0.62, 1.0 }, alpha = 0.13, escala = esc,
    vel = { 0.018, -0.006 }, densidad = 0.8, corte = 0.40,
    offset = { L.camX / anchoVis * esc, L.camY / altoVis * esc },
  })
end

-- ------------------------------------------------------------
-- VORTICE DEL PORTAL (shader)
-- ------------------------------------------------------------
function L.fxVortice()
  if not Shaders.activo then return end
  love.graphics.setBlendMode("add")
  Shaders.portal(L.portalX, L.portalY, 72, 28)
  love.graphics.setBlendMode("alpha")
end

-- ------------------------------------------------------------
-- UI: banner de zona, insignia, indicador y brujula
-- ------------------------------------------------------------
local NOMBRES = {
  portal = "Portal", joy = "Joy", soul_master = "Maestro de Almas",
  libro = "Libro Antiguo", computadora = "Terminal", capsula = "Capsula",
}

local function panel(x, y, w, h, colorBorde)
  love.graphics.setColor(0.04, 0.06, 0.12, 0.82)
  love.graphics.rectangle("fill", x, y, w, h, 5)
  love.graphics.setColor(colorBorde[1], colorBorde[2], colorBorde[3], 0.65)
  love.graphics.rectangle("line", x, y, w, h, 5)
  love.graphics.setColor(1, 1, 1, 0.05)
  love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h * 0.4, 4)
end

local function bannerDeZona()
  local b = L.fxBanner
  if not b or L.estado ~= "explorando" then return end
  local k
  if b.t < 0.5 then k = b.t / 0.5
  elseif b.t > b.dur - 0.8 then k = math.max(0, (b.dur - b.t) / 0.8)
  else k = 1 end
  local W = constantes.ANCHO_VIRTUAL
  local y = 96 - (1 - k) * 8
  local f = love.graphics.getFont()
  local esc = 1.7
  local tw = f:getWidth(b.texto) * esc

  love.graphics.setColor(0, 0, 0, 0.35 * k)
  love.graphics.rectangle("fill", W / 2 - tw / 2 - 60, y - 10, tw + 120, 44)
  love.graphics.setColor(1.0, 0.82, 0.35, 0.8 * k)
  love.graphics.rectangle("fill", W / 2 - tw / 2 - 50, y - 10, tw + 100, 1)
  love.graphics.rectangle("fill", W / 2 - tw / 2 - 50, y + 33, tw + 100, 1)
  -- rombos decorativos
  love.graphics.polygon("fill", W / 2 - tw / 2 - 56, y + 11, W / 2 - tw / 2 - 50, y + 6, W / 2 - tw / 2 - 44, y + 11, W / 2 - tw / 2 - 50, y + 16)
  love.graphics.polygon("fill", W / 2 + tw / 2 + 56, y + 11, W / 2 + tw / 2 + 50, y + 6, W / 2 + tw / 2 + 44, y + 11, W / 2 + tw / 2 + 50, y + 16)
  love.graphics.setColor(0, 0, 0, k)
  love.graphics.print(b.texto, W / 2 - tw / 2 + 2, y + 2, 0, esc, esc)
  love.graphics.setColor(1.0, 0.92, 0.70, k)
  love.graphics.print(b.texto, W / 2 - tw / 2, y, 0, esc, esc)
end

local function insignia()
  local p = Personajes.lista and Personajes.lista[Personajes.actual]
  if not p then return end
  local x, y, w, h = 12, 48, 200, 30
  panel(x, y, w, h, { 0.55, 0.85, 1.0 })
  local c = p.colorTunica or { 0.5, 0.5, 0.6 }
  local pulso = 0.5 + 0.5 * math.sin(L.fxT * 2)
  love.graphics.setColor(c[1], c[2], c[3], 0.25 + pulso * 0.15)
  love.graphics.circle("fill", x + 17, y + h / 2, 12)
  love.graphics.setColor(c[1], c[2], c[3])
  love.graphics.circle("fill", x + 17, y + h / 2, 8)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.circle("line", x + 17, y + h / 2, 8)
  local cp = p.colorPelo or { 0.8, 0.8, 0.8 }
  love.graphics.setColor(cp[1], cp[2], cp[3])
  love.graphics.circle("fill", x + 17, y + h / 2 - 3, 3.5)
  love.graphics.setColor(0.95, 0.95, 1.0)
  love.graphics.print(p.nombre or "", x + 36, y + 3, 0, 0.95, 0.95)
  love.graphics.setColor(0.65, 0.80, 0.95)
  love.graphics.print(p.tipo or "", x + 36, y + 15, 0, 0.75, 0.75)
end

local function indicador()
  local it = L.interactuableCercano
  if not it or L.estado ~= "explorando" then return end
  local nombre = NOMBRES[it.tipo]
  if not nombre and it.tipo and it.tipo:find("^pilar_") then nombre = "Pilar" end
  nombre = nombre or ""
  local sx = (it.x - L.camX) * L.zoom
  local sy = (it.y - L.camY) * L.zoom - 52 + math.sin(L.fxT * 4) * 3
  local f = love.graphics.getFont()
  local tw = f:getWidth(nombre) * 0.9
  love.graphics.setColor(0.04, 0.06, 0.12, 0.8)
  love.graphics.rectangle("fill", sx - tw / 2 - 6, sy - 16, tw + 12, 16, 4)
  love.graphics.setColor(1.0, 0.82, 0.35, 0.85)
  love.graphics.rectangle("line", sx - tw / 2 - 6, sy - 16, tw + 12, 16, 4)
  love.graphics.setColor(1, 0.95, 0.8)
  love.graphics.print(nombre, sx - tw / 2, sy - 14, 0, 0.9, 0.9)
  love.graphics.setColor(1.0, 0.82, 0.35, 0.95)
  love.graphics.polygon("fill", sx - 5, sy + 2, sx + 5, sy + 2, sx, sy + 9)
end

local function brujula()
  if L.estado ~= "explorando" or not L.robin then return end
  local dx, dy = L.portalX - L.robin.x, L.portalY - L.robin.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 230 then return end
  local W, H = constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL
  local a = math.atan2(dy, dx)
  local cx, cy = W / 2, H / 2
  local rx, ry = W / 2 - 34, H / 2 - 34
  local px = cx + math.cos(a) * rx
  local py = cy + math.sin(a) * ry
  local pulso = 0.6 + 0.4 * math.sin(L.fxT * 4)
  love.graphics.push()
  love.graphics.translate(px, py)
  love.graphics.rotate(a)
  love.graphics.setColor(0.35, 0.75, 1.0, 0.25 * pulso)
  love.graphics.circle("fill", 0, 0, 14)
  love.graphics.setColor(0.55, 0.88, 1.0, 0.9)
  love.graphics.polygon("fill", 9, 0, -5, -7, -2, 0, -5, 7)
  love.graphics.pop()
  local f = love.graphics.getFont()
  love.graphics.setColor(0.8, 0.95, 1.0, 0.85)
  love.graphics.print("Portal", px - f:getWidth("Portal") * 0.4, py + 12, 0, 0.8, 0.8)
end

function L.fxUI()
  insignia()
  indicador()
  brujula()
  bannerDeZona()
end

return L
