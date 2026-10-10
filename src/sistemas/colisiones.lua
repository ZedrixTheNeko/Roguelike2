local constantes = require("src.constantes")
local Colisiones = {}

-- Tiles que bloquean (solo cuentan como pared para jefes y ataques area)
local TILES_PARED = {
  ["#"] = true,
  ["T"] = true,   -- antorcha (reemplaza a "#" en el borde)
}

-- Tiles solidos (bloquean al jugador y a los enemigos)
local TILES_SOLIDOS = {
  ["#"] = true,
  ["T"] = true,
  ["X"] = true,
  ["P"] = true,
  ["C"] = true,
  ["B"] = true,
  ["S"] = true,
}

function Colisiones.circuloConMapa(cx, cy, r, mapa, soloParedes)
  local filtro = soloParedes and TILES_PARED or TILES_SOLIDOS
  local offX = mapa.offX or 0
  local offY = mapa.offY or 0
  local t = constantes.TILE
  local minX = math.floor((cx - offX - r) / t) + 1
  local maxX = math.floor((cx - offX + r) / t) + 1
  local minY = math.floor((cy - offY - r) / t) + 1
  local maxY = math.floor((cy - offY + r) / t) + 1

  for ty = minY, maxY do
    local fila = mapa[ty]
    if fila then
      for tx = minX, maxX do
        if filtro[fila[tx]] then
          local rx = offX + (tx - 1) * t
          local ry = offY + (ty - 1) * t
          local px = math.max(rx, math.min(cx, rx + t))
          local py = math.max(ry, math.min(cy, ry + t))
          local dx = cx - px
          local dy = cy - py
          if dx * dx + dy * dy < r * r then
            return true
          end
        end
      end
    end
  end
  return false
end

return Colisiones