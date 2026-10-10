local Sala = require("src.datos.sala")
local Biomas = require("src.datos.biomas")

local Mazmorra = {}

local RW = 30 * 16
local RH = 17 * 16

function Mazmorra.generar(nivel)
  local esJefe = (nivel % 3 == 0)
  local bioma = Biomas.paraNivel(nivel)
  local numSalas = 4

  local salas = {}
  for i = 1, numSalas do
    local puertas = { arriba = false, abajo = false, izq = false, der = false }
    if i > 1 then puertas.abajo = true end
    if i < numSalas then puertas.arriba = true end

    local tipo = "combate"
    if i == 1 then
      tipo = "inicio"
    elseif i == numSalas and esJefe then
      tipo = "jefe"
    end

    local mapa, W, H = Sala.generar(tipo, puertas, bioma)
    local gridX = 0
    local gridY = numSalas - i

    -- IMPORTANTE: guardar offset de mundo dentro del mapa
    mapa.offX = gridX * RW
    mapa.offY = gridY * RH

    table.insert(salas, {
      gridX = gridX,
      gridY = gridY,
      tipo = tipo,
      bioma = bioma,
      puertas = puertas,
      mapa = mapa,
      W = W,
      H = H,
      enemigos = {},
      limpiada = (tipo == "inicio"),
      visitada = false,
      jefe = nil,
      portalSalida = nil,
    })
  end

  return salas
end

return Mazmorra