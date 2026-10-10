local constantes = require("src.constantes")

local Minimapa = {}

-- Dibuja una fila de dots representando los niveles.
-- nivelActual = numero de nivel (1..15)
-- totalNiveles = 15
-- biomas = 5 (cada 3 niveles = 1 bioma)
function Minimapa.dibujar(nivelActual, totalNiveles, x, y)
  totalNiveles = totalNiveles or 15
  x = x or (constantes.ANCHO_VIRTUAL - 60)
  y = y or 8

  local anchoTotal = totalNiveles * 6 - 2
  local inicioX = x - anchoTotal

  for i = 1, totalNiveles do
    local cx = inicioX + (i - 1) * 6
    local cy = y

    -- Color: pasado (azul claro), actual (dorado), futuro (gris oscuro)
    local color
    if i < nivelActual then
      color = {0.35, 0.75, 0.95}
    elseif i == nivelActual then
      color = {0.95, 0.85, 0.30}
    else
      color = {0.30, 0.30, 0.35}
    end

    -- Bioma: cada 3 niveles cambia el borde
    local bioma = math.floor((i - 1) / 3)
    local borde = nil
    if bioma == 0 then borde = {0.55, 0.55, 0.60}
    elseif bioma == 1 then borde = {0.75, 0.55, 0.30}
    elseif bioma == 2 then borde = {0.30, 0.65, 0.45}
    elseif bioma == 3 then borde = {0.65, 0.30, 0.65}
    else borde = {0.85, 0.35, 0.35} end

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", cx, cy, 4, 4, 1)
    love.graphics.setColor(borde)
    love.graphics.rectangle("line", cx, cy, 4, 4, 1)
  end

  -- Puntos de jefe debajo de cada 3er nivel
  for i = 3, totalNiveles, 3 do
    local cx = inicioX + (i - 1) * 6 + 2
    local cy = y + 8
    local color
    if i < nivelActual then color = {0.85, 0.35, 0.35}
    elseif i == nivelActual then color = {1, 0.85, 0.30}
    else color = {0.35, 0.20, 0.20} end
    love.graphics.setColor(color)
    love.graphics.circle("fill", cx, cy, 2)
  end
end

return Minimapa