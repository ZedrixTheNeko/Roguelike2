local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local Jugador    = require("src.entidades.jugador")
local Joystick   = require("src.ui.joystick")
local Boton      = require("src.ui.boton")
local Config     = require("src.datos.config")

local t = constantes.TILE

-- ============================================================
-- ZONAS
-- ============================================================
local ZONAS = {
  sala_portal = { x1 = 24, y1 = 2,  x2 = 56, y2 = 20 },
  pasillo     = { x1 = 36, y1 = 20, x2 = 44, y2 = 30 },
  lobby       = { x1 = 24, y1 = 30, x2 = 56, y2 = 54 },
  invocacion  = { x1 = 2,  y1 = 20, x2 = 24, y2 = 34 },
  tiendas     = { x1 = 2,  y1 = 34, x2 = 24, y2 = 52 },
  selector    = { x1 = 56, y1 = 32, x2 = 78, y2 = 50 },
}

function L.construirMapa()
  L.anchoMundo = L.anchoTiles * t
  L.altoMundo = L.altoTiles * t

  L.mapa = {}
  for y = 1, L.altoTiles do
    L.mapa[y] = {}
    for x = 1, L.anchoTiles do
      L.mapa[y][x] = "#"
    end
  end

  L.dentroZona = {}
  for y = 1, L.altoTiles do
    L.dentroZona[y] = {}
    for x = 1, L.anchoTiles do
      L.dentroZona[y][x] = false
    end
  end

  local function tallarZona(z)
    for y = z.y1, z.y2 do
      for x = z.x1, z.x2 do
        L.dentroZona[y][x] = true
        if x == z.x1 or x == z.x2 or y == z.y1 or y == z.y2 then
          L.mapa[y][x] = "#"
        else
          L.mapa[y][x] = "."
        end
      end
    end
  end

  for _, z in pairs(ZONAS) do tallarZona(z) end

  local function puertaH(y, x1, x2)
    for x = x1, x2 do
      L.mapa[y][x] = "D"
      L.dentroZona[y][x] = true
    end
  end
  local function puertaV(x, y1, y2)
    for y = y1, y2 do
      L.mapa[y][x] = "D"
      L.dentroZona[y][x] = true
    end
  end

  puertaH(20, 38, 41)
  puertaH(30, 38, 41)
  puertaV(56, 40, 43)
  puertaV(24, 40, 43)
  puertaH(34, 10, 13)
  puertaH(54, 38, 41)

  local function bloquear(x1, y1, x2, y2)
    for y = y1, y2 do
      for x = x1, x2 do
        if L.mapa[y] and L.mapa[y][x] == "." then
          L.mapa[y][x] = "X"
        end
      end
    end
  end

  L.portalX = 40 * t + t / 2
  L.portalY = 8 * t + t / 2

  L.pilares = {
    { tileX = 28, tileY = 6,  fase = 0.0 },
    { tileX = 52, tileY = 6,  fase = 1.6 },
    { tileX = 28, tileY = 16, fase = 3.2 },
    { tileX = 52, tileY = 16, fase = 4.8 },
  }
  for _, p in ipairs(L.pilares) do
    bloquear(p.tileX, p.tileY, p.tileX, p.tileY)
    p.x = p.tileX * t + t / 2
    p.y = p.tileY * t + t / 2
  end

  bloquear(30, 36, 31, 36)
  L.joyX = 30 * t + t
  L.joyY = 35 * t + t / 2

  bloquear(50, 36, 50, 36)
  L.soulMasterX = 50 * t + t / 2
  L.soulMasterY = 36 * t + t / 2

  bloquear(40, 44, 40, 44)
  L.libroX = 40 * t + t / 2
  L.libroY = 44 * t + t / 2

  bloquear(62, 38, 62, 38)
  L.computadoraX = 62 * t + t / 2
  L.computadoraY = 38 * t + t / 2

  bloquear(72, 42, 73, 43)
  L.capsulaX = 72 * t + t
  L.capsulaY = 42 * t + t

  L.puertaSalidaX = 40 * t
  L.puertaSalidaY = 54 * t + t / 2
end

function L.construirInteractuables()
  L.interactuables = {}

  table.insert(L.interactuables, { x = L.portalX, y = L.portalY, radio = 50, tipo = "portal" })

  for i, p in ipairs(L.pilares) do
    table.insert(L.interactuables, {
      x = p.x, y = p.y, radio = 40, tipo = "pilar_" .. i, pilar = p,
    })
  end

  table.insert(L.interactuables, { x = L.joyX, y = L.joyY, radio = 55, tipo = "joy" })
  table.insert(L.interactuables, { x = L.soulMasterX, y = L.soulMasterY, radio = 55, tipo = "soul_master" })
  table.insert(L.interactuables, { x = L.libroX, y = L.libroY, radio = 50, tipo = "libro" })
  table.insert(L.interactuables, { x = L.computadoraX, y = L.computadoraY, radio = 55, tipo = "computadora" })
  table.insert(L.interactuables, { x = L.capsulaX, y = L.capsulaY, radio = 55, tipo = "capsula" })
end

function L.entrar()
  if L.fxReset then L.fxReset() end
  L.estado = "explorando"
  L.tiempoEstado = 0
  L.tGlobal = 0
  L.fadeAlpha = 0
  L.escalaRobin = 1
  L.startX, L.startY = nil, nil
  L.dialogoTitulo = nil
  L.dialogoTexto = nil
  L.interactuableCercano = nil
  L.particulasPortal = {}
  L.particulasAmbiente = {}
  L.particulasMagicas = {}
  L.runas = {}
  L.toques = {}

  L.saliendo = false
  L.timerSalida = 0
  L.destinoSalida = nil

  L.cambioPersonaje.activo = false
  L.cambioPersonaje.fase = "desintegrando"
  L.cambioPersonaje.timer = 0
  L.cambioPersonaje.personajeNuevo = nil
  L.cambioPersonaje.particulasViejas = {}
  L.cambioPersonaje.particulasNuevas = {}
  L.cambioPersonaje.movido = false

  L.zoom = Config.get("zoom") or 1.5

  L.construirMapa()
  L.construirInteractuables()

  local spawnX = L.puertaSalidaX + t
  local spawnY = L.puertaSalidaY - 4 * t

  if not L.robin then
    L.robin = Jugador.nuevo(spawnX, spawnY)
  else
    L.robin.x, L.robin.y = spawnX, spawnY
    L.robin.vivo = true
    L.robin.invulnerable = 0
    L.robin.estado = "normal"
    L.robin.buffVelocidad = 0
    L.robin.slowTimer = 0
    L.robin:aplicarPersonaje()
    L.robin:resetearVida()
  end

  local anchoVis = constantes.ANCHO_VIRTUAL / L.zoom
  local altoVis = constantes.ALTO_VIRTUAL / L.zoom
  L.camX = L.robin.x - anchoVis / 2
  L.camY = L.robin.y - altoVis / 2
  L.camX = math.max(0, math.min(L.camX, L.anchoMundo - anchoVis))
  L.camY = math.max(0, math.min(L.camY, L.altoMundo - altoVis))

  local jx, jy = 70, constantes.ALTO_VIRTUAL - 70
  L.joyMover = Joystick.nuevo(jx, jy, 52, 14,
    0, constantes.ALTO_VIRTUAL / 2,
    constantes.ANCHO_VIRTUAL / 2,
    constantes.ALTO_VIRTUAL / 2, "mover")

  L.botonInteractuar = Boton.nuevo(0, 0, 180, 30, "Hablar", function()
    L.ativarInteractuable()
  end)
  L.botonInteractuar.oculto = true

  L.botonCerrar = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 70,
                              constantes.ALTO_VIRTUAL - 60,
                              140, 32, "Cerrar", function()
    L.estado = "explorando"
    L.dialogoTitulo = nil
    L.dialogoTexto = nil
  end)

  -- Botones Si/No del portal
  local bw, bh = 70, 28
  local cy = constantes.ALTO_VIRTUAL / 2 + 40
  L.botonSi = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - bw - 6, cy, bw, bh, "Si", function()
    L.saliendo = true
    L.timerSalida = 0
    L.destinoSalida = "juego"
  end)
  L.botonNo = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 + 6, cy, bw, bh, "No", function()
    L.estado = "explorando"
  end)
end

function L.ativarInteractuable()
  if not L.interactuableCercano then return end
  local tipo = L.interactuableCercano.tipo

  if tipo == "portal" then
    L.estado = "preguntando"

  elseif tipo:match("^pilar_") then
    L.dialogoTitulo = "Pilar Arcano"
    L.dialogoTexto = {
      "Un pilar antiguo con runas latiendo",
      "en un azul celeste hipnotico.",
      "",
      "Parece formar parte de un sello.",
    }
    L.estado = "dialogo"

  elseif tipo == "joy" then
    L.dialogoTitulo = "Joy - Enfermera"
    L.dialogoTexto = {
      "\"Hola! Soy Joy, tu guia.\"",
      "",
      "Estoy aqui para ayudarte con:",
      "  - Controles del juego",
      "  - Consejos y estrategias",
      "  - Lore del mundo",
    }
    L.estado = "dialogo"

  elseif tipo == "soul_master" then
    L.dialogoTitulo = "SoulMaster"
    L.dialogoTexto = {
      "\"...Percibo la esencia de tu alma.\"",
      "",
      "Puedo reconfigurar tu poder interior.",
      "Sube de clase y desbloquea lo oculto.",
      "",
      "Proximamente: mejoras de personaje.",
    }
    L.estado = "dialogo"

  elseif tipo == "libro" then
    local Guardado = require("src.datos.guardado")
    local gemas = Guardado.get("gemas") or 0
    local stats = Guardado.get("estadisticas") or {}
    L.dialogoTitulo = "Libro de Registros"
    L.dialogoTexto = {
      "Consultas el libro antiguo...",
      "",
      "Gemas totales: " .. gemas,
      "Partidas jugadas: " .. (stats.partidasJugadas or 0),
      "Niveles completados: " .. (stats.nivelesCompletados or 0),
      "Jefes derrotados: " .. (stats.jefesDerrotados or 0),
    }
    L.estado = "dialogo"

  elseif tipo == "computadora" then
    local Personajes = require("src.datos.personajes")
    L.personajePreview = Personajes.actual
    L.estado = "seleccion"
    L.construirBotonesSeleccion()

  elseif tipo == "capsula" then
    L.dialogoTitulo = "Capsula de Reconfiguracion"
    L.dialogoTexto = {
      "Una capsula de cristal con luz azul.",
      "",
      "Utiliza la computadora cercana",
      "para reconfigurar tu forma.",
    }
    L.estado = "dialogo"
  end
end

return L