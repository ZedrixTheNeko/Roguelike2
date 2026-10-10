-- ============================================================
-- ILUMINACION DE LA MAZMORRA
-- Oscuridad ambiental del bioma con "agujeros" de luz (shader) alrededor
-- del jugador, antorchas, jefe y proyectiles, mas resplandores de color
-- aditivos. Sin shaders no hace nada (el juego se ve normal).
-- ============================================================
local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local Shaders    = require("src.utils.shaders")
local Config     = require("src.datos.config")

local COLOR_PROYECTIL = {
  bola_fuego = { 1.0, 0.55, 0.15 },
  bola_slime = { 0.4, 0.9, 0.3 },
  esquirla_hielo = { 0.6, 0.85, 1.0 },
  orbe_vacio = { 0.7, 0.35, 1.0 },
  espora = { 0.6, 0.9, 0.3 },
  roca = { 1.0, 0.5, 0.15 },
  bala = { 1.0, 0.9, 0.5 },
  daga = { 0.7, 0.45, 1.0 },
  onda_santa = { 1.0, 0.95, 0.6 },
}

local function aPantalla(wx, wy)
  local Z = J.zoomActual or 1
  return (wx - (J.camXActual or 0)) * Z, (wy - (J.camYActual or 0)) * Z
end

function J.dibujarIluminacion()
  if not Shaders.activo or Config.get("efectosVisuales") == false then return end
  local sala = J.salaActual
  if not sala or not J.robin then return end
  local Z = J.zoomActual or 1
  local W, H = constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL
  local bioma = sala.bioma
  local llama = (bioma and bioma.llama and bioma.llama[2]) or { 1.0, 0.7, 0.3 }

  local luces = {}
  local brillos = {}

  -- jugador
  local px, py = aPantalla(J.robin.x, J.robin.y)
  luces[#luces + 1] = { px, py, 150 * Z }
  brillos[#brillos + 1] = { px, py, 80 * Z, 1.0, 0.92, 0.8, 0.10 }

  -- jefe
  local jf = sala.jefe
  if jf and jf.vivo then
    local jx, jy = aPantalla(jf.x, jf.y)
    local c = jf.colorFase or { 1, 0.5, 0.4 }
    luces[#luces + 1] = { jx, jy, 110 * Z }
    brillos[#brillos + 1] = { jx, jy, 90 * Z, c[1], c[2], c[3], 0.14 }
  end

  -- antorchas cercanas a la camara
  local mapa = sala.mapa
  if mapa then
    local ox, oy = mapa.offX or 0, mapa.offY or 0
    local t = constantes.TILE
    local cand = {}
    for y = 1, #mapa do
      local fila = mapa[y]
      for x = 1, #fila do
        if fila[x] == "T" then
          local wx, wy = ox + (x - 1) * t + 8, oy + (y - 1) * t + 8
          local dx, dy = wx - J.robin.x, wy - J.robin.y
          local d2 = dx * dx + dy * dy
          if d2 < 260 * 260 then cand[#cand + 1] = { wx, wy, d2 } end
        end
      end
    end
    table.sort(cand, function(a, b) return a[3] < b[3] end)
    for i = 1, math.min(4, #cand) do
      local sx, sy = aPantalla(cand[i][1], cand[i][2])
      local fl = 0.85 + 0.15 * math.sin(love.timer.getTime() * 9 + i * 2)
      luces[#luces + 1] = { sx, sy, 80 * Z * fl }
      brillos[#brillos + 1] = { sx, sy, 60 * Z, llama[1], llama[2], llama[3], 0.22 * fl }
    end
  end

  -- proyectiles luminosos
  local cuenta = 0
  for _, pool in ipairs({ J.poolFlechasEnemigas, J.poolFlechas }) do
    for p in pool:iterarActivos() do
      local c = COLOR_PROYECTIL[p.tipo]
      if c and cuenta < 2 and #luces < 8 then
        local sx, sy = aPantalla(p.x, p.y)
        if sx > -40 and sx < W + 40 and sy > -40 and sy < H + 40 then
          luces[#luces + 1] = { sx, sy, 38 * Z }
          brillos[#brillos + 1] = { sx, sy, 34 * Z, c[1], c[2], c[3], 0.35 }
          cuenta = cuenta + 1
        end
      end
    end
  end

  -- menos oscuridad cuando hay jefe vivo (se deben leer los avisos)
  local escala = (jf and jf.vivo) and 0.55 or 1.0
  Shaders.oscuridad(luces, escala)

  for _, b in ipairs(brillos) do
    Shaders.luz(b[1], b[2], b[3], b[4], b[5], b[6], b[7])
  end
end

return J
