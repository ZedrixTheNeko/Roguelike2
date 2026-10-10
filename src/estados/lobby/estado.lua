local L = {}

-- ============================================================
-- MAPA (80 x 56 tiles = 1280 x 896 px)
-- ============================================================
L.mapa = nil
L.anchoTiles = 80
L.altoTiles = 56
L.anchoMundo = 0
L.altoMundo = 0
L.t = 16

-- ============================================================
-- CAMARA
-- ============================================================
L.camX = 0
L.camY = 0
L.zoom = 1.5
L.joyMover = nil
L.robin = nil

-- ============================================================
-- ESTADO GENERAL
-- ============================================================
L.estado = "explorando"   -- "explorando" | "preguntando" | "dialogo" | "seleccion"
L.tiempoEstado = 0
L.tGlobal = 0
L.fadeAlpha = 0
L.escalaRobin = 1
L.startX = nil
L.startY = nil

-- ============================================================
-- TRANSICION DE SALIDA AL MENU
-- ============================================================
L.saliendoAlMenu = false
L.timerSalida = 0
L.duracionSalida = 1.0

-- ============================================================
-- DIALOGO
-- ============================================================
L.dialogoTitulo = nil
L.dialogoTexto = nil
L.botonCerrar = nil

-- Botones del portal (Si/No)
L.botonSi = nil
L.botonNo = nil

-- ============================================================
-- INTERACTUABLES
-- ============================================================
L.interactuables = {}
L.interactuableCercano = nil
L.botonInteractuar = nil

-- ============================================================
-- COORDENADAS CLAVE
-- ============================================================
L.portalX = 0
L.portalY = 0
L.pilares = {}

L.joyX = 0
L.joyY = 0
L.soulMasterX = 0
L.soulMasterY = 0
L.libroX = 0
L.libroY = 0

L.computadoraX = 0
L.computadoraY = 0
L.capsulaX = 0
L.capsulaY = 0

L.puertaSalidaX = 0
L.puertaSalidaY = 0

-- ============================================================
-- ANIMACION DE CAMBIO DE PERSONAJE (desintegracion)
-- ============================================================
L.cambioPersonaje = {
  activo = false,
  fase = "desintegrando",  -- "desintegrando" | "esperando" | "apareciendo"
  timer = 0,
  personajeNuevo = nil,
  particulasViejas = {},
  particulasNuevas = {},
  movido = false,
}

-- ============================================================
-- PARTICULAS
-- ============================================================
L.particulasPortal = {}
L.particulasAmbiente = {}
L.particulasMagicas = {}
L.timerMagica = 0
L.MAX_LUCIERNAGAS = 12
L.MAX_AMBIENTE = 30

L.runas = {}
L.timerRuna = 0
L.MAX_RUNAS = 4

L.toques = {}

-- ============================================================
-- HELPERS
-- ============================================================

function L.crearParticulaAmbiente()
  return {
    x = math.random() * L.anchoMundo,
    y = math.random() * L.altoMundo,
    vy = -6 - math.random() * 12,
    vx = (math.random() - 0.5) * 6,
    radio = 0.6 + math.random() * 1.6,
    vida = 3 + math.random() * 4,
    maxVida = 0,
    tipo = math.random(1, 3),
  }
end

function L.crearParticulaMagica()
  local p = {
    x = math.random() * L.anchoMundo,
    y = L.altoMundo - 20 + math.random() * 60,
    vx = (math.random() - 0.5) * 14,
    vy = -10 - math.random() * 22,
    radio = 1 + math.random() * 2,
    vida = 4 + math.random() * 4,
    maxVida = 0,
    fase = math.random() * math.pi * 2,
    brillo = 0.55 + math.random() * 0.45,
  }
  p.maxVida = p.vida
  return p
end

function L.crearRuna()
  return {
    x = 40 + math.random() * (L.anchoMundo - 80),
    y = 60 + math.random() * (L.altoMundo - 120),
    tipo = math.random(1, 8),
    tamano = 6 + math.random() * 10,
    vida = 0,
    maxVida = 4 + math.random() * 4,
    fase = math.random() * math.pi * 2,
    velocidadPulso = 0.8 + math.random() * 1.6,
    color = {0.55, 0.85, 1.00},
    colorClaro = {0.85, 0.95, 1.00},
    rotacion = (math.random() - 0.5) * 0.4,
    boost = 0,
  }
end

function L.crearParticulaCambio(x, y, tipo)
  if tipo == "viejo" then
    local ang = math.random() * math.pi * 2
    local vel = 20 + math.random() * 40
    return {
      x = x + (math.random() - 0.5) * 8,
      y = y + (math.random() - 0.5) * 12,
      vx = math.cos(ang) * vel * 0.3,
      vy = -30 - math.random() * 40,
      radio = 1 + math.random() * 2,
      vida = 0.8 + math.random() * 0.6,
      maxVida = 0,
      color = {0.55, 0.85, 1.00},
    }
  else
    local ang = math.random() * math.pi * 2
    local dist = math.random() * 15
    return {
      x = x + math.cos(ang) * dist,
      y = y + math.sin(ang) * dist,
      vx = (math.random() - 0.5) * 20,
      vy = -20 - math.random() * 30,
      radio = 1 + math.random() * 2,
      vida = 0.8 + math.random() * 0.6,
      maxVida = 0,
      color = {0.55, 0.85, 1.00},
    }
  end
end

return L