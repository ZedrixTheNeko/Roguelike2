local constantes = require("src.constantes")
local Shaders = require("src.utils.shaders")

local Escalador = {}

local canvas
local escala = 1
local offsetX = 0
local offsetY = 0

function Escalador.inicializar()
  canvas = love.graphics.newCanvas(constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  canvas:setFilter("nearest", "nearest")
  Escalador.recalcular(love.graphics.getWidth(), love.graphics.getHeight())
end

function Escalador.recalcular(w, h)
  local escalaX = w / constantes.ANCHO_VIRTUAL
  local escalaY = h / constantes.ALTO_VIRTUAL
  escala = math.min(escalaX, escalaY)

  -- Si quieres pixel perfect estricto (barras negras mas grandes),
  -- descomenta esta linea:
  -- escala = math.max(1, math.floor(escala))

  offsetX = math.floor((w - constantes.ANCHO_VIRTUAL * escala) / 2)
  offsetY = math.floor((h - constantes.ALTO_VIRTUAL * escala) / 2)
end

function Escalador.iniciar()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(constantes.COLORES.fondo)
end

function Escalador.terminar()
  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0)
  love.graphics.setColor(1, 1, 1)
  -- Post-proceso (bloom, correccion de color...). Si no esta disponible o
  -- falla, se dibuja el canvas normal: nunca debe romper el render.
  local hecho = Shaders.dibujarCanvas(canvas, offsetX, offsetY, escala,
    constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  if not hecho then
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, offsetX, offsetY, 0, escala, escala)
  end
end

-- Convierte coordenadas de pantalla a coordenadas virtuales (640x360)
function Escalador.aVirtual(x, y)
  local vx = (x - offsetX) / escala
  local vy = (y - offsetY) / escala
  return vx, vy
end

return Escalador