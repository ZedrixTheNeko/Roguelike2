local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local textos     = require("src.datos.textos")
local Config     = require("src.datos.config")
local HUD        = require("src.ui.hud")
local Minimapa   = require("src.ui.minimapa")
local Juice      = require("src.sistemas.juice")
local Sangre     = require("src.sistemas.sangre")
local FX         = require("src.sistemas.fx_habilidades")

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
-- HELPERS DE UI
-- ============================================================

local function esquina(x, y, ox, oy, color, alpha, s)
  s = s or 8
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(2)
  love.graphics.line(x, y, x + s * ox, y)
  love.graphics.line(x, y, x, y + s * oy)
  love.graphics.setLineWidth(1)
end

local function dibujarBotonArcano(b, esHover, colorBase)
  local x, y, w, h = b.x, b.y, b.w, b.h

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
  local texto = b.texto or ""
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
-- MENU DE PAUSA ARCANO
-- ============================================================

local function dibujarMenuPausa()
  local cx = constantes.ANCHO_VIRTUAL / 2

  -- Fondo oscuro
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  -- Panel central decorado
  local pw = 340
  local ph = 320
  local px = cx - pw / 2
  local py = (constantes.ALTO_VIRTUAL - ph) / 2 + 10

  love.graphics.setColor(0.05, 0.08, 0.18, 0.98)
  love.graphics.rectangle("fill", px, py, pw, ph, 10)
  love.graphics.setColor(0.10, 0.15, 0.30, 0.6)
  love.graphics.rectangle("fill", px + 4, py + 4, pw - 8, ph * 0.4, 8)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", px, py, pw, ph, 10)
  love.graphics.setLineWidth(1)

  esquina(px + 6, py + 6, 1, 1, DORADO, 1.0, 12)
  esquina(px + pw - 6, py + 6, -1, 1, DORADO, 1.0, 12)
  esquina(px + 6, py + ph - 6, 1, -1, DORADO, 1.0, 12)
  esquina(px + pw - 6, py + ph - 6, -1, -1, DORADO, 1.0, 12)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.5)
  love.graphics.rectangle("fill", px + 30, py + 6, pw - 60, 1)

  -- Titulo
  local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 1.5)
  local titulo = "PAUSA"
  local f = love.graphics.getFont()
  local escalaTitulo = 1.8
  local twTitulo = f:getWidth(titulo) * escalaTitulo
  local txTitulo = cx - twTitulo / 2
  local tyTitulo = py + 24

  love.graphics.setColor(AZUL_MEDIO[1], AZUL_MEDIO[2], AZUL_MEDIO[3], 0.4 + pulso * 0.15)
  love.graphics.circle("fill", cx, tyTitulo + 14, 60 + pulso * 4)

  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(titulo, txTitulo + 3, tyTitulo + 3, 0, escalaTitulo, escalaTitulo)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.7 + pulso * 0.2)
  love.graphics.print(titulo, txTitulo - 2, tyTitulo, 0, escalaTitulo, escalaTitulo)
  love.graphics.print(titulo, txTitulo + 2, tyTitulo, 0, escalaTitulo, escalaTitulo)
  love.graphics.print(titulo, txTitulo, tyTitulo - 2, 0, escalaTitulo, escalaTitulo)
  love.graphics.print(titulo, txTitulo, tyTitulo + 2, 0, escalaTitulo, escalaTitulo)

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(titulo, txTitulo, tyTitulo, 0, escalaTitulo, escalaTitulo)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.5)
  love.graphics.rectangle("fill", px + 40, tyTitulo + 40, pw - 80, 1)
  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.9)
  love.graphics.circle("fill", px + 40, tyTitulo + 40.5, 3)
  love.graphics.circle("fill", px + pw - 40, tyTitulo + 40.5, 3)

  -- Botones
  local botones = {
    J.botonReanudar,
    J.botonAjustesPausa,
    J.botonMenuPausa,
    J.botonGuardarSalir,
  }
  for _, b in ipairs(botones) do
    dibujarBotonArcano(b, b.presionado, AZUL_BRILLO)
  end
end

-- ============================================================
-- DIBUJO PRINCIPAL
-- ============================================================

function J.dibujar()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  local rx, ry = J.salaWorldPos(J.salaActual)
  local Z = Config.get("zoom") or constantes.ZOOM
  local anchoVis = constantes.ANCHO_VIRTUAL / Z
  local altoVis  = constantes.ALTO_VIRTUAL  / Z

  local camX = J.robin.x - anchoVis / 2
  local camY = J.robin.y - altoVis  / 2

  local maxX = rx + J.RW - anchoVis
  local maxY = ry + J.RH - altoVis

  if maxX < rx then
    camX = rx + (J.RW - anchoVis) / 2
  else
    camX = math.max(rx, math.min(camX, maxX))
  end
  if maxY < ry then
    camY = ry + (J.RH - altoVis) / 2
  else
    camY = math.max(ry, math.min(camY, maxY))
  end

  -- Sacudida de camara
  local shx, shy = Juice.offsetCamara()
  camX = camX + shx
  camY = camY + shy

  J.camXActual, J.camYActual, J.zoomActual = camX, camY, Z

  love.graphics.push()
  love.graphics.scale(Z, Z)
  love.graphics.translate(-camX, -camY)

  -- ============================================================
  -- PASADA 1: suelo, efectos, ambiente, decoraciones
  -- ============================================================
  J.dibujarSuelo(rx, ry)
  pcall(Sangre.dibujarSuelo, rx, ry)
  J.dibujarEfectosMundo()
  Juice.dibujarAmbiente()
  J.dibujarDecoracionesSuelo(rx, ry)

  -- ============================================================
  -- PASADA 2: NPCs, objetos
  -- ============================================================
  if J.salaActual.joy then J.salaActual.joy:dibujar() end

  if J.salaActual.portalSalida then
    local p = J.salaActual.portalSalida
    local pulso = 0.5 + 0.5 * math.sin(p.timer * 4)
    love.graphics.setColor(0.20, 0.55, 0.95, 0.35 + pulso * 0.25)
    love.graphics.ellipse("fill", p.x, p.y, 30 * (1 + pulso * 0.1), 12 * (1 + pulso * 0.1))
    love.graphics.setColor(0.60, 0.90, 1.0, 0.85)
    love.graphics.ellipse("line", p.x, p.y, 26, 10)
    love.graphics.setColor(0.90, 0.98, 1.0, 0.95)
    love.graphics.ellipse("fill", p.x, p.y, 14, 6)
  end

  -- ============================================================
  -- PASADA 3: drops, proyectiles, jefe, enemigos, cortes, jugador
  -- ============================================================
  for _, d in ipairs(J.drops) do d:dibujar() end
  for p in J.poolFlechas:iterarActivos() do p:dibujar() end
  for p in J.poolFlechasEnemigas:iterarActivos() do p:dibujar() end

  if J.salaActual.jefe then J.salaActual.jefe:dibujar() end
  for _, e in ipairs(J.salaActual.enemigos) do e:dibujar() end

  for _, c in ipairs(J.cortes) do J.dibujarCorte(c) end

  -- Extras (torretas, granadas, escudos, parry) - Rex/Thorin/Sable
  if J.dibujarExtrasMundo then J.dibujarExtrasMundo() end

  J.robin:dibujar()
  
  -- ============================================================
-- MP: dibujar jugador remoto (host) o enemigos del host (cliente)
-- ============================================================
local Red = require("src.red")
if Red.activo then
  -- Jugador remoto
  if J.remotos then
    for _, r in pairs(J.remotos) do
      local color = {1.00, 0.65, 0.35}
      if r.vivo == false then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
      else
        love.graphics.setColor(color)
      end
      love.graphics.circle("fill", r.x, r.y, 6)
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle("line", r.x, r.y, 8)
      -- Nombre
      love.graphics.setColor(0, 0, 0, 0.7)
      love.graphics.print("Host", r.x - 12, r.y - 22)
      love.graphics.setColor(color)
      love.graphics.print("Host", r.x - 13, r.y - 23)
    end
  end

  -- Si soy cliente, dibujar enemigos/proyectiles del host
  if not Red.esHost then
    -- Enemigos remotos
    if J.remotosEnemigos then
      for _, e in pairs(J.remotosEnemigos) do
        love.graphics.setColor(0.90, 0.25, 0.30)
        love.graphics.circle("fill", e.x, e.y, 10)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("line", e.x, e.y, 11)
        -- HP bar
        if e.hp and e.hpMax and e.hpMax > 0 then
          local frac = math.max(0, math.min(1, e.hp / e.hpMax))
          love.graphics.setColor(0.1, 0.05, 0.05)
          love.graphics.rectangle("fill", e.x - 13, e.y - 16, 26, 3)
          love.graphics.setColor(0.95, 0.3, 0.35)
          love.graphics.rectangle("fill", e.x - 13, e.y - 16, 26 * frac, 3)
        end
      end
    end

    -- Proyectiles del host
    if J.remotosProyectiles then
      for _, p in pairs(J.remotosProyectiles) do
        love.graphics.setColor(0.55, 0.85, 1.00)
        love.graphics.circle("fill", p.x, p.y, 3)
      end
    end

    -- Proyectiles enemigos
    if J.remotosEProyectiles then
      for _, p in pairs(J.remotosEProyectiles) do
        love.graphics.setColor(0.85, 0.55, 1.0)
        love.graphics.circle("fill", p.x, p.y, 4)
      end
    end

    -- Drops del host
    if J.remotosDrops then
      for _, d in pairs(J.remotosDrops) do
        love.graphics.setColor(1.00, 0.85, 0.30)
        love.graphics.circle("fill", d.x, d.y, 4)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", d.x - 1, d.y - 1, 1.5)
      end
    end

    -- Jefe remoto
    if J.remotosJefe then
      local jf = J.remotosJefe
      love.graphics.setColor(0.85, 0.20, 0.25)
      love.graphics.circle("fill", jf.x, jf.y, 22)
      love.graphics.setColor(1, 1, 1, 0.6)
      love.graphics.circle("line", jf.x, jf.y, 24)
    end
  end
end

  -- ============================================================
  -- PASADA 4: paredes por encima (para efecto de profundidad)
  -- ============================================================
  J.dibujarParedes(rx, ry)

  -- ============================================================
  -- PASADA 5: Juice (particulas, numeros) por encima del mundo
  -- ============================================================
  pcall(Sangre.dibujarAire)
  pcall(FX.dibujar)
  Juice.dibujarMundo()
  J.dibujarNotificaciones()

  love.graphics.pop()

  -- Oscuridad ambiental con luces dinamicas (shader)
  if J.dibujarIluminacion then pcall(J.dibujarIluminacion) end

  -- ============================================================
  -- Tinte de bioma, vineta, banners, flashes
  -- ============================================================
  Juice.dibujarPantalla(constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL, J.salaActual.bioma)

  -- ============================================================
  -- UI
  -- ============================================================
  J.joyMover:dibujar()
  J.joyApuntar:dibujar()

  -- Botones de habilidad con cooldown circular
  for i, b in ipairs(J.botonesHabilidad or {}) do
    b:dibujar()
    local cd = J.cooldownsHabilidad[i] or 0
    if cd > 0 then
      local h = J.robin.personaje.habilidades[i]
      if h then
        local frac = cd / h.cooldown
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.arc("fill", b.cx, b.cy, b.radio - 2,
          -math.pi / 2, -math.pi / 2 + math.pi * 2 * frac)
        love.graphics.setColor(1, 1, 1, 0.9)
        local f = love.graphics.getFont()
        local txt = string.format("%.1f", cd)
        local tw = f:getWidth(txt)
        love.graphics.print(txt, b.cx - tw / 2, b.cy + b.radio + 2, 0, 0.7, 0.7)
      end
    end
  end

  -- Botones extra (roll, frasco)
  if J.dibujarBotonesExtra then J.dibujarBotonesExtra() end

  J.botonPausa:dibujar()
  HUD.dibujar(J.robin, J.nivel)
  if J.dibujarBarraJefe then J.dibujarBarraJefe() end
  Minimapa.dibujar(J.nivel, 15)

  if J.puedeInteractuar then J.botonInteractuar:dibujar() end

  -- ============================================================
  -- DIALOGO CON JOY
  -- ============================================================
  if J.dialogoJoy then
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill",
      constantes.ANCHO_VIRTUAL / 2 - 100, constantes.ALTO_VIRTUAL / 2 - 40, 200, 95, 4)
    love.graphics.setColor(0.9, 0.55, 0.75)
    love.graphics.rectangle("line",
      constantes.ANCHO_VIRTUAL / 2 - 100, constantes.ALTO_VIRTUAL / 2 - 40, 200, 95, 4)
    love.graphics.setColor(1, 1, 1)
    local txt = "Joy: Te curo por 15 monedas?"
    local f = love.graphics.getFont()
    local tw = f:getWidth(txt)
    love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, constantes.ALTO_VIRTUAL / 2 - 25)
    love.graphics.setColor(0.85, 0.85, 0.85)
    local txt2 = "Monedas: " .. J.robin.monedas .. "  HP: " .. J.robin.hp .. "/" .. J.robin.hpMax
    local tw2 = f:getWidth(txt2)
    love.graphics.print(txt2, (constantes.ANCHO_VIRTUAL - tw2) / 2, constantes.ALTO_VIRTUAL / 2 - 5)
    J.botonCuraSi:dibujar()
    J.botonCuraNo:dibujar()
  end

  -- ============================================================
  -- MUERTE
  -- ============================================================
  local MuerteUI = require("src.estados.juego.muerte_ui")
  MuerteUI.dibujar()

  -- ============================================================
  -- TEXTO DEL PORTAL
  -- ============================================================
  if J.salaActual.portalSalida then
    love.graphics.setColor(1, 0.9, 0.3)
    local f = love.graphics.getFont()
    local txt = "Entra al portal para continuar"
    local tw = f:getWidth(txt)
    love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, 70)
  end

  -- ============================================================
  -- MENU DE PAUSA
  -- ============================================================
  if J.pausado then
    dibujarMenuPausa()
  end
end

-- ============================================================
-- BARRA DE VIDA DEL JEFE (arriba al centro)
-- ============================================================
function J.dibujarBarraJefe()
  local jf = J.salaActual and J.salaActual.jefe
  if not jf or not jf.vivo or not jf.barraSuperior then return end
  if jf.estado == "intro" then return end

  local w, h = 260, 9
  local x = (constantes.ANCHO_VIRTUAL - w) / 2
  local y = 30
  local frac = math.max(0, jf.hp / jf.hpMax)

  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6, 3)
  love.graphics.setColor(0.22, 0.08, 0.10)
  love.graphics.rectangle("fill", x, y, w, h)

  local c = jf.colorFase or {0.85, 0.20, 0.25}
  love.graphics.setColor(0.85, 0.18, 0.22)
  love.graphics.rectangle("fill", x, y, w * frac, h)
  love.graphics.setColor(1, 1, 1, 0.25)
  love.graphics.rectangle("fill", x, y, w * frac, h * 0.4)

  -- Marcas de fase
  love.graphics.setColor(1, 1, 1, 0.55)
  for _, u in ipairs(jf.umbrales or {}) do
    love.graphics.rectangle("fill", x + w * u - 0.5, y - 2, 1, h + 4)
  end
  love.graphics.setColor(1, 0.85, 0.40, 0.9)
  love.graphics.rectangle("line", x - 3, y - 3, w + 6, h + 6, 3)

  local f = love.graphics.getFont()
  local txt = jf.nombre or "Jefe"
  local tw = f:getWidth(txt)
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2 + 1, y - 17)
  love.graphics.setColor(1, 0.92, 0.75)
  love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, y - 18)

  if jf.invulnerableT and jf.invulnerableT > 0 then
    love.graphics.setColor(0.7, 0.9, 1.0, 0.8)
    local t2 = "INVULNERABLE"
    love.graphics.print(t2, (constantes.ANCHO_VIRTUAL - f:getWidth(t2)) / 2, y + 12)
  end
end

return J