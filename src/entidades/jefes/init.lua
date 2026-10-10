-- Fabrica de jefes: uno por bioma
local Biomas = require("src.datos.biomas")

local Jefes = {}

local CLASES = {
  slime_rey      = function() return require("src.entidades.jefes.slime_rey") end,
  madre_raiz     = function() return require("src.entidades.jefes.madre_raiz") end,
  coloso_magma   = function() return require("src.entidades.jefes.coloso_magma") end,
  reina_escarcha = function() return require("src.entidades.jefes.reina_escarcha") end,
  soberano_vacio = function() return require("src.entidades.jefes.senor_vacio") end,
}

-- nivel: nivel actual de la mazmorra (3, 6, 9, 12, 15, 18...)
function Jefes.crear(nivel, x, y)
  local bioma = Biomas.paraNivel(nivel)
  local escala = 1 + 0.55 * Biomas.vuelta(nivel)
  local id = bioma.jefe

  local claseFactory = CLASES[id]
  if not claseFactory then
    -- Fallback por si acaso: siempre hay Slime Rey
    local SlimeRey = require("src.entidades.jefes.slime_rey")
    return SlimeRey.nuevo(x, y, escala)
  end

  local clase = claseFactory()
  return clase.nuevo(x, y, escala)
end

return Jefes