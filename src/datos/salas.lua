local Sala = {}

local function randint(a, b)
  return love.math.random(a, b)
end

-- Genera una sala con:
--   * bordes de pared
--   * pilares/obstaculos en patron con algo de azar
--   * una puerta arriba en el centro (2 tiles)
function Sala.generar(anchoTiles, altoTiles, nivel)
  local mapa = {}
  for y = 1, altoTiles do
    mapa[y] = {}
    for x = 1, anchoTiles do
      mapa[y][x] = "."
    end
  end

  -- Bordes
  for x = 1, anchoTiles do
    mapa[1][x] = "#"
    mapa[altoTiles][x] = "#"
  end
  for y = 1, altoTiles do
    mapa[y][1] = "#"
    mapa[y][anchoTiles] = "#"
  end

  -- Puerta arriba centro (deja hueco)
  local puertaX = math.floor(anchoTiles / 2)
  mapa[1][puertaX] = "D"
  mapa[1][puertaX + 1] = "D"

  -- Pilares: cuadricula cada 4-5 tiles con azar
  local pasoX = randint(4, 5)
  local pasoY = randint(4, 5)
  for y = 4, altoTiles - 3, pasoY do
    for x = 4, anchoTiles - 3, pasoX do
      if math.random() < 0.75 then
        -- No colocar pilares junto a la puerta
        if math.abs(x - puertaX) > 3 or y > 6 then
          mapa[y][x] = "#"
          -- A veces pilares de 2x2
          if math.random() < 0.4 then
            mapa[y][x + 1] = "#"
          end
        end
      end
    end
  end

  return mapa, anchoTiles, altoTiles, puertaX
end

-- Compatibilidad con codigo antiguo
function Sala.crearBasica(anchoTiles, altoTiles)
  return Sala.generar(anchoTiles, altoTiles, 1)
end

return Sala