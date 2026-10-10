local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local Personajes = require("src.datos.personajes")
local Guardado   = require("src.datos.guardado")

local MuerteUI = {}

-- Fase 1: mensaje con tinte rojo
local function dibujarMensaje()
  local m = J.muerte
  local ancho = constantes.ANCHO_VIRTUAL
  local alto  = constantes.ALTO_VIRTUAL
  local t = love.timer.getTime()

  -- Tinte rojo pulsante
  local intensidadBase = math.max(0.35, 1 - m.timer * 0.15)
  local pulso = 0.5 + 0.5 * math.sin(t * 3)
  local alpha = 0.45 * intensidadBase + 0.15 * pulso * intensidadBase

  love.graphics.setColor(0.55, 0.02, 0.02, alpha)
  love.graphics.rectangle("fill", 0, 0, ancho, alto)

  -- Vineta roja radial
  for i = 8, 1, -1 do
    local r = i * 60
    local a = 0.04 * (9 - i) * intensidadBase
    love.graphics.setColor(0.6, 0.0, 0.0, a)
    love.graphics.circle("line", ancho / 2, alto / 2, r)
  end

  -- Texto principal
  local texto = "Y asi otra alma mas fue tomada..."
  local f = love.graphics.getFont()
  local escala = 1.1
  local tw = f:getWidth(texto) * escala
  local tx = (ancho - tw) / 2
  local ty = alto / 2 - 15

  local aparece = math.min(1, m.timer / 1.2)

  love.graphics.setColor(0, 0, 0, 0.85 * aparece)
  love.graphics.print(texto, tx + 3, ty + 3, 0, escala, escala)

  love.graphics.setColor(0.15, 0.0, 0.0, 0.9 * aparece)
  love.graphics.print(texto, tx + 1.5, ty + 1.5, 0, escala, escala)

  love.graphics.setColor(0.95, 0.75, 0.75, aparece)
  love.graphics.print(texto, tx, ty, 0, escala, escala)

  love.graphics.setColor(1, 0.9, 0.9, 0.35 * aparece)
  love.graphics.print(texto, tx, ty - 1, 0, escala, escala)

  -- Linea decorativa
  if m.timer > 1.0 then
    local lineaAlpha = math.min(1, (m.timer - 1.0) / 0.5)
    local anchoLinea = math.min(360, (m.timer - 1.0) * 300)
    love.graphics.setColor(0.7, 0.2, 0.2, 0.7 * lineaAlpha)
    love.graphics.rectangle("fill", (ancho - anchoLinea) / 2, ty + 40, anchoLinea, 1.5)
  end

  -- Texto inferior parpadeante
  if m.puedeAvanzar then
    local blink = 0.5 + 0.5 * math.sin(t * 4)
    love.graphics.setColor(1, 1, 1, 0.5 + blink * 0.5)
    local txt2 = "Toca para continuar"
    local tw2 = f:getWidth(txt2)
    love.graphics.print(txt2, (ancho - tw2) / 2, alto - 60)
  end
end

-- Fase 2: lapida con estadisticas
local function dibujarLapida()
  local m = J.muerte
  local ancho = constantes.ANCHO_VIRTUAL
  local alto  = constantes.ALTO_VIRTUAL
  local f = love.graphics.getFont()

  -- Fondo oscuro
  love.graphics.setColor(0.05, 0.03, 0.03, 1)
  love.graphics.rectangle("fill", 0, 0, ancho, alto)

  -- Vineta roja tenue
  local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 1.5)
  for i = 8, 1, -1 do
    local r = i * 70
    love.graphics.setColor(0.4, 0.0, 0.0, 0.025 * (9 - i) * (0.7 + pulso * 0.3))
    love.graphics.circle("fill", ancho / 2, alto / 2, r)
  end

  -- Shake al caer
  local shakeX, shakeY = 0, 0
  if m.shakeTimer > 0 then
    shakeX = (math.random() - 0.5) * m.shakeMag * 2 * (m.shakeTimer / 0.35)
    shakeY = (math.random() - 0.5) * m.shakeMag * 2 * (m.shakeTimer / 0.35)
  end

  -- Particulas de polvo
  for _, p in ipairs(m.particulas) do
    local a = math.min(1, p.vida)
    love.graphics.setColor(0.45, 0.40, 0.38, a * 0.8)
    love.graphics.circle("fill", p.x, p.y, p.radio)
  end

  -- Lapida (cae desde arriba)
  love.graphics.push()
  love.graphics.translate(ancho / 2 + shakeX, alto / 2 + m.lapidaY + shakeY)

  local lw = 260
  local lh = 200

  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.ellipse("fill", 0, lh / 2 + 10, lw / 2 + 4, 8)

  love.graphics.setColor(0.15, 0.13, 0.13)
  love.graphics.rectangle("fill", -lw/2 + 3, -lh/2 + 3, lw, lh, 8)

  love.graphics.setColor(0.40, 0.38, 0.38)
  love.graphics.rectangle("fill", -lw/2, -lh/2, lw, lh, 8)

  love.graphics.setColor(0.45, 0.42, 0.42)
  love.graphics.polygon("fill",
    -lw/2, -lh/2 + 30,
    -lw/2 + 30, -lh/2,
    lw/2 - 30, -lh/2,
    lw/2, -lh/2 + 30,
    lw/2, lh/2,
    -lw/2, lh/2)

  love.graphics.setColor(0.55, 0.52, 0.52)
  love.graphics.rectangle("fill", -lw/2 + 2, -lh/2 + 2, lw - 4, 3)
  love.graphics.rectangle("fill", -lw/2 + 2, -lh/2 + 2, 3, lh - 4)

  love.graphics.setColor(0.22, 0.20, 0.20)
  love.graphics.rectangle("fill", -lw/2 + 2, lh/2 - 5, lw - 4, 3)
  love.graphics.rectangle("fill", lw/2 - 5, -lh/2 + 2, 3, lh - 4)

  love.graphics.setColor(0.25, 0.22, 0.22)
  love.graphics.setLineWidth(1)
  love.graphics.line(-lw/2 + 15, -lh/2 + 40, -lw/2 + 30, -lh/2 + 60, -lw/2 + 25, -lh/2 + 80)
  love.graphics.line(lw/2 - 20, lh/2 - 50, lw/2 - 35, lh/2 - 40, lw/2 - 30, lh/2 - 25)

  -- Contenido
  local personaje = Personajes.actualData()

  love.graphics.setColor(0.15, 0.12, 0.12)
  love.graphics.rectangle("fill", -2, -lh/2 + 18, 4, 20)
  love.graphics.rectangle("fill", -8, -lh/2 + 24, 16, 4)

  local nombre = personaje.nombre
  love.graphics.setColor(0.15, 0.12, 0.12, 0.9)
  local twN = f:getWidth(nombre) * 1.15
  love.graphics.print(nombre, -twN/2 + 1, -lh/2 + 48 + 1, 0, 1.15, 1.15)
  love.graphics.setColor(0.60, 0.55, 0.50)
  love.graphics.print(nombre, -twN/2, -lh/2 + 48, 0, 1.15, 1.15)

  love.graphics.setColor(0.20, 0.18, 0.18)
  love.graphics.rectangle("fill", -lw/2 + 20, -lh/2 + 80, lw - 40, 1.5)

  local y = -lh/2 + 95
  local saltoY = 13

  local lineas = {
    { "Nivel alcanzado:", tostring(J.nivel), {0.85, 0.85, 0.90} },
    { "Jefes derrotados:", tostring(math.floor((J.nivel - 1) / 3)), {0.90, 0.60, 0.60} },
    { "Monedas conseguidas:", tostring(J.robin.monedas), {0.95, 0.85, 0.40} },
    { "Gemas ganadas:", "+" .. tostring(J.gemasGanadas or 0), {0.40, 0.90, 0.95} },
    { "Perdidas con Mack:", "-" .. tostring(J.gemasPerdidas or 0), {0.95, 0.45, 0.45} },
  }

  for _, linea in ipairs(lineas) do
    love.graphics.setColor(0.15, 0.12, 0.12, 0.85)
    love.graphics.print(linea[1], -lw/2 + 25, y + 1)
    love.graphics.setColor(0.55, 0.52, 0.50)
    love.graphics.print(linea[1], -lw/2 + 24, y)

    local twV = f:getWidth(linea[2])
    love.graphics.setColor(0.15, 0.12, 0.12, 0.85)
    love.graphics.print(linea[2], lw/2 - 25 - twV + 1, y + 1)
    love.graphics.setColor(linea[3])
    love.graphics.print(linea[2], lw/2 - 25 - twV, y)

    y = y + saltoY
  end

  y = y + 3
  love.graphics.setColor(0.20, 0.18, 0.18)
  love.graphics.rectangle("fill", -lw/2 + 20, y, lw - 40, 1.5)
  y = y + 6

  local gemasTotal = Guardado.get("gemas") or 0
  love.graphics.setColor(0.15, 0.12, 0.12, 0.85)
  love.graphics.print("Gemas totales:", -lw/2 + 25, y + 1)
  love.graphics.setColor(0.60, 0.55, 0.50)
  love.graphics.print("Gemas totales:", -lw/2 + 24, y)

  local totalStr = tostring(gemasTotal)
  local twT = f:getWidth(totalStr)
  love.graphics.setColor(0.15, 0.12, 0.12, 0.85)
  love.graphics.print(totalStr, lw/2 - 25 - twT + 1, y + 1)
  love.graphics.setColor(0.40, 0.90, 0.95)
  love.graphics.print(totalStr, lw/2 - 25 - twT, y)

  love.graphics.pop()

  if m.puedeAvanzar then
    local blink = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(1, 1, 1, 0.5 + blink * 0.5)
    local txt2 = "Toca para volver al menu"
    local tw2 = f:getWidth(txt2)
    love.graphics.print(txt2, (ancho - tw2) / 2, alto - 40)
  end
end

function MuerteUI.dibujar()
  if J.estadoFinNivel ~= "derrota" then return end
  local m = J.muerte

  if m.fase == "mensaje" then
    dibujarMensaje()
  elseif m.fase == "lapida" then
    dibujarLapida()
  end
end

return MuerteUI