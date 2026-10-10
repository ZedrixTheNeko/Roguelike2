-- ============================================================
-- BIOMAS: uno por jefe. Cada 3 niveles cambia el bioma.
--   Niveles  1-3  -> Catacumbas (Rey Slime)
--   Niveles  4-6  -> Bosque Maldito (Madre Raiz)
--   Niveles  7-9  -> Forja de Magma (Coloso de Magma)
--   Niveles 10-12 -> Glaciar Eterno (Reina de Escarcha)
--   Niveles 13-15 -> Santuario del Vacio (Soberano del Vacio)
-- Pasado el 15 el ciclo vuelve a empezar con enemigos mas duros.
-- ============================================================
local Biomas = {}

local function pool1(nivel)
  if nivel >= 16 then
    return { {"slime",12}, {"guardia",20}, {"arquero",16}, {"rata",14}, {"murcielago",14}, {"mago",14} }
  elseif nivel >= 3 then
    return { {"slime",35}, {"guardia",20}, {"arquero",15}, {"rata",15}, {"murcielago",15} }
  else
    return { {"slime",75}, {"rata",25} }
  end
end

Biomas.lista = {
  -- 1 ---------------------------------------------------------
  {
    id = "catacumbas", nombre = "Catacumbas Olvidadas",
    jefe = "slime_rey",
    suelo1 = {0.20, 0.19, 0.24}, suelo2 = {0.17, 0.16, 0.21}, linea = {0.10, 0.09, 0.14},
    pared = {0.28, 0.26, 0.32}, paredLinea = {0.18, 0.16, 0.22}, paredLuz = {0.42, 0.40, 0.48},
    musgo = {0.25, 0.42, 0.28},
    llama = { {1, 0.55, 0.15}, {1, 0.80, 0.30}, {1, 0.95, 0.65} },
    detalleSuelo = "grietas",
    estilos = { P = "piedra", C = "piedra", S = "piedra", X = "piedra", B = "piedra" },
    decor = { P = {3, 5}, C = {2, 3}, X = {1, 3}, B = {1, 2}, S = {0, 1} },
    ambiente = { cantidad = 22, modo = "flotar", vx = 6, vy = 4, rMin = 0.5, rMax = 1.2,
                 color = {0.75, 0.75, 0.85}, alpha = 0.25 },
    tinte = {0.05, 0.05, 0.12, 0.05},
    pool = pool1,
  },
  -- 2 ---------------------------------------------------------
  {
    id = "bosque", nombre = "Bosque Maldito",
    jefe = "madre_raiz",
    suelo1 = {0.14, 0.22, 0.12}, suelo2 = {0.12, 0.19, 0.10}, linea = {0.07, 0.12, 0.06},
    pared = {0.22, 0.16, 0.10}, paredLinea = {0.12, 0.09, 0.06}, paredLuz = {0.38, 0.28, 0.17},
    musgo = {0.30, 0.55, 0.22},
    llama = { {0.45, 0.95, 0.35}, {0.70, 1.0, 0.45}, {0.90, 1.0, 0.75} },
    detalleSuelo = "hierba",
    estilos = { P = "arbol", C = "tocon", S = "hongo", X = "tronco", B = "hongo" },
    decor = { P = {5, 8}, C = {2, 4}, X = {0, 1}, B = {0, 1}, S = {1, 2} },
    ambiente = { cantidad = 34, modo = "subir", vx = 10, vy = 7, rMin = 0.6, rMax = 1.4,
                 color = {0.75, 1.0, 0.45}, alpha = 0.55 },
    tinte = {0.0, 0.14, 0.02, 0.10},
    pool = function()
      return { {"lobo_sombra",22}, {"hongo_toxico",15}, {"arana_venenosa",20},
               {"slime",12}, {"rata",12}, {"arquero",9}, {"murcielago",10} }
    end,
  },
  -- 3 ---------------------------------------------------------
  {
    id = "magma", nombre = "Forja de Magma",
    jefe = "coloso_magma",
    suelo1 = {0.22, 0.12, 0.10}, suelo2 = {0.18, 0.09, 0.08}, linea = {0.09, 0.04, 0.04},
    pared = {0.31, 0.17, 0.13}, paredLinea = {0.17, 0.08, 0.06}, paredLuz = {0.58, 0.30, 0.17},
    musgo = {0.85, 0.35, 0.10},
    llama = { {1, 0.35, 0.08}, {1, 0.60, 0.15}, {1, 0.90, 0.45} },
    detalleSuelo = "lava",
    estilos = { P = "basalto", C = "roca_ardiente", S = "obelisco", X = "obsidiana", B = "geiser" },
    decor = { P = {3, 5}, C = {3, 5}, X = {0, 1}, B = {1, 2}, S = {0, 1} },
    ambiente = { cantidad = 38, modo = "subir", vx = 12, vy = 26, rMin = 0.6, rMax = 1.5,
                 color = {1.0, 0.55, 0.15}, alpha = 0.75 },
    tinte = {0.22, 0.04, 0.0, 0.10},
    pool = function()
      return { {"salamandra",20}, {"golem_menor",14}, {"espiritu_fuego",20},
               {"guardia",16}, {"mago",12}, {"arquero",10}, {"murcielago",8} }
    end,
  },
  -- 4 ---------------------------------------------------------
  {
    id = "glaciar", nombre = "Glaciar Eterno",
    jefe = "reina_escarcha",
    suelo1 = {0.30, 0.38, 0.48}, suelo2 = {0.26, 0.34, 0.44}, linea = {0.14, 0.20, 0.30},
    pared = {0.42, 0.56, 0.70}, paredLinea = {0.26, 0.38, 0.52}, paredLuz = {0.78, 0.90, 1.0},
    musgo = {0.70, 0.90, 1.0},
    llama = { {0.30, 0.65, 1.0}, {0.55, 0.85, 1.0}, {0.90, 0.98, 1.0} },
    detalleSuelo = "hielo",
    estilos = { P = "cristal", C = "bloque_hielo", S = "estatua_hielo", X = "nieve", B = "barril_hielo" },
    decor = { P = {4, 6}, C = {3, 4}, X = {1, 2}, B = {0, 1}, S = {1, 2} },
    ambiente = { cantidad = 46, modo = "caer", vx = 14, vy = 22, rMin = 0.5, rMax = 1.3,
                 color = {1, 1, 1}, alpha = 0.8 },
    tinte = {0.0, 0.08, 0.22, 0.09},
    pool = function()
      return { {"yeti",15}, {"cristal_helado",14}, {"fantasma_escarcha",20},
               {"guardia",15}, {"arquero",12}, {"mago",12}, {"lobo_sombra",12} }
    end,
  },
  -- 5 ---------------------------------------------------------
  {
    id = "vacio", nombre = "Santuario del Vacio",
    jefe = "soberano_vacio",
    suelo1 = {0.10, 0.07, 0.16}, suelo2 = {0.08, 0.05, 0.13}, linea = {0.20, 0.09, 0.32},
    pared = {0.17, 0.10, 0.25}, paredLinea = {0.09, 0.05, 0.15}, paredLuz = {0.42, 0.22, 0.62},
    musgo = {0.55, 0.25, 0.85},
    llama = { {0.55, 0.25, 0.95}, {0.75, 0.45, 1.0}, {0.92, 0.80, 1.0} },
    detalleSuelo = "runas",
    estilos = { P = "monolito", C = "fragmento", S = "ojo_piedra", X = "cubo_vacio", B = "orbe_cautivo" },
    decor = { P = {3, 5}, C = {3, 5}, X = {1, 2}, B = {0, 1}, S = {1, 2} },
    ambiente = { cantidad = 40, modo = "flotar", vx = 12, vy = 9, rMin = 0.6, rMax = 1.6,
                 color = {0.75, 0.40, 1.0}, alpha = 0.7 },
    tinte = {0.12, 0.0, 0.18, 0.12},
    pool = function()
      return { {"acechador_vacio",22}, {"ojo_del_vacio",14}, {"caballero_vacio",20},
               {"mago",12}, {"fantasma_escarcha",10}, {"espiritu_fuego",10}, {"murcielago",12} }
    end,
  },
}

function Biomas.indicePara(nivel)
  local grupo = math.floor(((nivel or 1) - 1) / 3)
  return (grupo % #Biomas.lista) + 1
end

function Biomas.paraNivel(nivel)
  return Biomas.lista[Biomas.indicePara(nivel)]
end

-- Numero de vueltas completadas (0 en la primera pasada de 15 niveles)
function Biomas.vuelta(nivel)
  return math.floor(math.floor(((nivel or 1) - 1) / 3) / #Biomas.lista)
end

-- Multiplicador de vida de enemigos segun el nivel
function Biomas.escalaVida(nivel)
  return 1 + 0.045 * ((nivel or 1) - 1)
end

function Biomas.elegirEnemigo(bioma, nivel)
  local lista = bioma.pool(nivel)
  local total = 0
  for _, e in ipairs(lista) do total = total + e[2] end
  local r = math.random() * total
  for _, e in ipairs(lista) do
    r = r - e[2]
    if r <= 0 then return e[1] end
  end
  return lista[1][1]
end

return Biomas