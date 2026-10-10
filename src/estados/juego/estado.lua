local Sala = require("src.datos.sala")

local J = {}

J.RW = Sala.ANCHO_PX
J.RH = Sala.ALTO_PX

J.salas = nil
J.salaActual = nil
J.salaIndice = 1

J.robin = nil
J.joyMover = nil
J.joyApuntar = nil
J.botonHabilidad = nil
J.botonPausa = nil
J.botonInteractuar = nil
J.puedeInteractuar = false

J.botonesHabilidad = {}
J.cooldownsHabilidad = {0, 0, 0}

J.accionEspecial = {
  tipo = nil,
  timer = 0,
  duracion = 0,
  fase = 1,
  objetivoX = 0,
  objetivoY = 0,
  enemigoObjetivo = nil,
  particulas = {},
  golpeAplicado = {},
}

J.poolFlechas = nil
J.poolFlechasEnemigas = nil
J.poolDrops = nil
J.drops = {}
J.bufferFlechas = {}

J.nivel = 1
J.pausado = false
J.dialogoJoy = false

J.botonCuraSi = nil
J.botonCuraNo = nil
J.botonReanudar = nil
J.botonMenuPausa = nil
J.botonAjustesPausa = nil
J.botonGuardarSalir = nil

J.timerFinNivel = 0
J.estadoFinNivel = nil

J.cortes = {}

J.monedasConvertidas = 0
J.gemasGanadas = 0
J.gemasPerdidas = 0

J.notificaciones = {}

-- ============================================================
-- SLOW MOTION (Coyote hab 3)
-- ============================================================
J.tiempoSlow = 0
J.factorSlow = 1

-- ============================================================
-- EXTRAS (Rex: torretas y granadas; roll/frasco)
-- ============================================================
J.torretas = {}
J.granadas = {}
J.botonRodar = nil
J.botonFrasco = nil

-- ============================================================
-- DESIGNTEGRACION (Nyx-7)
-- ============================================================
J.designtegraciones = {}

function J.designtegrarEnemigo(e)
  if not e then return end

  local color = {0.55, 0.90, 1.0}   -- cian plasma

  -- 14 particulas radiales
  for i = 1, 14 do
    local ang = math.random() * math.pi * 2
    local vel = 30 + math.random() * 90
    local vida = 0.5 + math.random() * 0.5
    table.insert(J.designtegraciones, {
      x = e.x + (math.random() - 0.5) * 8,
      y = e.y + (math.random() - 0.5) * 8,
      vx = math.cos(ang) * vel,
      vy = math.sin(ang) * vel - 30,
      vida = vida,
      maxVida = vida,
      radio = 1 + math.random() * 2.5,
      color = color,
    })
  end

  -- Anillo de energia
  table.insert(J.cortes, {
    x = e.x, y = e.y,
    angulo = 0,
    tipo = "desintegracion_anillo",
    vida = 0.4,
    duracion = 0.4,
    radio = (e.radio or 8) * 2.5,
  })
end

-- ============================================================
-- NOTIFICACIONES FLOTANTES
-- ============================================================

function J.agregarNotificacion(texto, x, y, color)
  table.insert(J.notificaciones, {
    texto = texto,
    x = x,
    y = y,
    vida = 1.5,
    vidaMax = 1.5,
    color = color or {1, 0.85, 0.40},
  })
end

-- ============================================================
-- PANTALLA DE MUERTE
-- ============================================================
J.muerte = {
  fase = "mensaje",       -- "mensaje" | "lapida"
  timer = 0,
  puedeAvanzar = false,
  lapidaY = -220,         -- arriba de la pantalla
  lapidaVY = 0,
  lapidaCayo = false,
  shakeTimer = 0,
  shakeMag = 0,
  particulas = {},
  rojoPulso = 0,
}

function J.resetearMuerte()
  J.muerte.fase = "mensaje"
  J.muerte.timer = 0
  J.muerte.puedeAvanzar = false
  J.muerte.lapidaY = -220
  J.muerte.lapidaVY = 0
  J.muerte.lapidaCayo = false
  J.muerte.shakeTimer = 0
  J.muerte.shakeMag = 0
  J.muerte.particulas = {}
  J.muerte.rojoPulso = 0
end

-- ============================================================
-- MULTIJUGADOR
-- ============================================================
J.red = nil
J.remotos = {}
J.remotosEnemigos = {}
J.remotosProyectiles = {}
J.remotosEProyectiles = {}
J.remotosDrops = {}
J.remotosJefe = nil


return J