local Sala = {}

Sala.ANCHO_TILES = 40
Sala.ALTO_TILES  = 22
Sala.ANCHO_PX    = Sala.ANCHO_TILES * 16
Sala.ALTO_PX     = Sala.ALTO_TILES  * 16

-- Tipos de tile:
-- "."  suelo
-- "#"  pared
-- "D"  puerta
-- "P"  pilar (bloquea)
-- "C"  columna rota (bloquea)
-- "X"  caja (bloquea)
-- "B"  barril (bloquea)
-- "T"  antorcha (decoracion, no bloquea)
-- "S"  estatua (bloquea)
-- "R"  escombro (no bloquea, decoracion)

local function esSolidoParaPared(t)
  return t == "P" or t == "C" or t == "X" or t == "B" or t == "S"
end

-- Coloca una decoracion con comprobacion de colisiones
local function colocarDecoracion(mapa, W, H, tipo, x, y, evitaPuertas, cx, cy)
  if x < 3 or x > W - 2 or y < 3 or y > H - 2 then return false end
  if mapa[y][x] ~= "." then return false end
  if evitaPuertas then
    if math.abs(x - cx) <= 3 and (y <= 4 or y >= H - 3) then return false end
    if math.abs(y - cy) <= 3 and (x <= 4 or x >= W - 3) then return false end
  end
  -- Evitar bloquear el centro donde spawnea el jugador
  if math.abs(x - cx) <= 2 and math.abs(y - cy) <= 2 then return false end
  mapa[y][x] = tipo
  return true
end

function Sala.generar(tipo, puertas, bioma)
  local W, H = Sala.ANCHO_TILES, Sala.ALTO_TILES
  local mapa = {}
  for y = 1, H do
    mapa[y] = {}
    for x = 1, W do
      mapa[y][x] = "."
    end
  end

  -- Bordes de pared
  for x = 1, W do mapa[1][x] = "#" mapa[H][x] = "#" end
  for y = 1, H do mapa[y][1] = "#" mapa[y][W] = "#" end

  local cx = math.floor(W / 2)
  local cy = math.floor(H / 2)

  -- Puertas
  if puertas.arriba then
    mapa[1][cx] = "D"
    mapa[1][cx+1] = "D"
  end
  if puertas.abajo then
    mapa[H][cx] = "D"
    mapa[H][cx+1] = "D"
  end
  if puertas.izq then
    mapa[cy][1] = "D"
    mapa[cy+1][1] = "D"
  end
  if puertas.der then
    mapa[cy][W] = "D"
    mapa[cy+1][W] = "D"
  end

  -- Decoraciones segun el bioma (rangos {min, max} por tipo de tile)
  local decor = (bioma and bioma.decor) or { P = {3, 5}, C = {2, 3}, X = {1, 3}, B = {1, 2}, S = {0, 1} }

  local function repartir(letra, rango, margen)
    if not rango then return end
    local n = love.math.random(rango[1], rango[2])
    for _ = 1, n do
      local px = love.math.random(margen + 1, W - margen)
      local py = love.math.random(margen, H - margen)
      colocarDecoracion(mapa, W, H, letra, px, py, true, cx, cy)
    end
  end

  -- Antorchas / luces en las paredes (en la fila de pared, no bloquean)
  local function ponerAntorchas(paso)
    for ax = 4, W - 3, paso do
      if math.abs(ax - cx) > 2 then
        if mapa[1][ax] == "#" then mapa[1][ax] = "T" end
        if mapa[H][ax] == "#" then mapa[H][ax] = "T" end
      end
    end
    for ay = 4, H - 3, paso do
      if math.abs(ay - cy) > 2 then
        if mapa[ay][1] == "#" then mapa[ay][1] = "T" end
        if mapa[ay][W] == "#" then mapa[ay][W] = "T" end
      end
    end
  end

  if tipo == "combate" then
    repartir("P", decor.P, 4)
    repartir("C", decor.C, 3)
    repartir("X", decor.X, 3)
    repartir("B", decor.B, 3)
    repartir("S", decor.S, 4)

    ponerAntorchas(6)

    -- Escombros decorativos (no bloquean, dispersos)
    for _ = 1, love.math.random(6, 12) do
      local px = love.math.random(3, W - 2)
      local py = love.math.random(3, H - 2)
      if mapa[py][px] == "." then
        mapa[py][px] = "R"
      end
    end

  elseif tipo == "jefe" then
    -- Arena del jefe: 4 pilares en las esquinas del centro, resto despejado
    colocarDecoracion(mapa, W, H, "P", cx - 8, cy - 5, false, cx, cy)
    colocarDecoracion(mapa, W, H, "P", cx + 7, cy - 5, false, cx, cy)
    colocarDecoracion(mapa, W, H, "P", cx - 8, cy + 4, false, cx, cy)
    colocarDecoracion(mapa, W, H, "P", cx + 7, cy + 4, false, cx, cy)
    ponerAntorchas(4)

  elseif tipo == "inicio" then
    ponerAntorchas(8)
  end

  return mapa, W, H
end

Sala.esSolidoParaPared = esSolidoParaPared

return Sala