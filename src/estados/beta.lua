-- ============================================================
-- BETA / SANDBOX - Sala de Lideres + Coliseo
-- ============================================================
-- v3 (fix):
--   * Slime Rey ahora se llama como los demas jefes (ctx unificado)
--   * Dano a jefes en el coliseo (falta el bloque de colisiones)
--   * Mini PC para cambiar de personaje sin salir del sandbox
-- ============================================================

local constantes    = require("src.constantes")
local Estados       = require("src.sistemas.estados")
local Jugador       = require("src.entidades.jugador")
local Enemigo       = require("src.entidades.enemigo")
local Proyectil     = require("src.entidades.proyectil")
local Drop          = require("src.entidades.drop")
local Joystick      = require("src.ui.joystick")
local BotonRedondo  = require("src.ui.botonRedondo")
local Boton         = require("src.ui.boton")
local Pool          = require("src.utils.pool")
local Config        = require("src.datos.config")
local Juice         = require("src.sistemas.juice")
local Autoapuntado  = require("src.sistemas.autoapuntado")
local HUD           = require("src.ui.hud")
local Biomas        = require("src.datos.biomas")
local Personajes    = require("src.datos.personajes")

local J = nil
local B = {}

local T = constantes.TILE

-- ============================================================
-- DEFINICION DE JEFES PARA LA SALA DE LIDERES
-- ============================================================
local JEFES_FILA = {
  { id = "slime_rey",      nombre = "Slime Rey",         titulo = "Bioma I - Catacumbas" },
  { id = "madre_raiz",     nombre = "Madre Raiz",        titulo = "Bioma II - Bosque Maldito" },
  { id = "coloso_magma",   nombre = "Coloso de Magma",   titulo = "Bioma III - Forja de Magma" },
  { id = "reina_escarcha", nombre = "Reina de Escarcha", titulo = "Bioma IV - Glaciar Eterno" },
  { id = "soberano_vacio", nombre = "Soberano del Vacio", titulo = "Bioma V - Santuario del Vacio" },
}

local POSICIONES = {
  { x = 16, y = 11 },
  { x = 34, y = 11 },
  { x = 9,  y = 24 },
  { x = 25, y = 24 },
  { x = 41, y = 24 },
}

-- ============================================================
-- ESTADO GLOBAL DEL SANDBOX
-- ============================================================
B.modo             = "sandbox"
B.robin            = nil
B.joyMover         = nil
B.joyApuntar       = nil
B.botonesHabilidad = {}
B.cooldownsHabilidad = {0, 0, 0}
B.botonPausa       = nil
B.botonVolver      = nil
B.botonPelea       = nil
B.botonPC          = nil
B.panelPC          = false
B.botonesPC        = {}
B.botonPCCerrar    = nil
B.camX, B.camY     = 0, 0
B.zoom             = 1.5
B.anchoMundo       = 0
B.altoMundo        = 0
B.mapa             = nil
B.W, B.H           = 0, 0
B.biomaActual      = nil
B.jefesDisplay     = {}
B.jefeActual       = nil
B.bossCercanoIdx   = nil
B.salaFalsa        = nil
B.accionEspecial   = { tipo = nil, timer = 0, duracion = 0, fase = 1,
                       particulas = {}, golpeAplicado = {} }
B.poolFlechas         = nil
B.poolFlechasEnemigas = nil
B.poolDrops           = nil
B.drops            = {}
B.bufferFlechas    = {}
B.cortes           = {}
B.notificaciones   = {}
B.designtegraciones = {}
B.torretas         = {}
B.granadas         = {}
B.tiempoSlow       = 0
B.factorSlow       = 1
B.tGlobal          = 0

-- ============================================================
-- HELPERS COMPARTIDOS (se inyectan en J)
-- ============================================================
local function asegurarJ()
  if not J then J = require("src.estados.juego.estado") end
end

function B.agregarNotificacion(texto, x, y, color)
  table.insert(B.notificaciones, {
    texto = texto, x = x, y = y,
    vida = 1.5, vidaMax = 1.5,
    color = color or {1, 0.85, 0.40},
  })
end

function B.soltarDrop(x, y, tipo, cantidad)
  for i = 1, cantidad do
    local d = B.poolDrops:obtener()
    if d then
      d:lanzar(x, y, tipo, 1)
      table.insert(B.drops, d)
    end
  end
end

function B.obtenerTodosEnemigos()
  local todos = {}
  if B.salaFalsa then
    for _, e in ipairs(B.salaFalsa.enemigos) do table.insert(todos, e) end
    if B.salaFalsa.jefe and B.salaFalsa.jefe.vivo then
      table.insert(todos, B.salaFalsa.jefe)
    end
  end
  return todos
end

function B.designtegrarEnemigo(e)
  if not e then return end
  for i = 1, 14 do
    local ang = math.random() * math.pi * 2
    local vel = 30 + math.random() * 90
    local vida = 0.5 + math.random() * 0.5
    table.insert(B.designtegraciones, {
      x = e.x + (math.random() - 0.5) * 8,
      y = e.y + (math.random() - 0.5) * 8,
      vx = math.cos(ang) * vel,
      vy = math.sin(ang) * vel - 30,
      vida = vida, maxVida = vida,
      radio = 1 + math.random() * 2.5,
      color = {0.55, 0.90, 1.0},
    })
  end
  table.insert(B.cortes, {
    x = e.x, y = e.y, angulo = 0,
    tipo = "desintegracion_anillo",
    vida = 0.4, duracion = 0.4,
    radio = (e.radio or 8) * 2.5,
  })
end

-- ============================================================
-- INYECTAR / RESTAURAR EN J
-- ============================================================
local orig = {}
local originalsSaved = false

function B.instalarEnJ()
  asegurarJ()
  if not originalsSaved then
    orig.robin               = J.robin
    orig.salaActual          = J.salaActual
    orig.poolFlechas         = J.poolFlechas
    orig.poolFlechasEnemigas = J.poolFlechasEnemigas
    orig.poolDrops           = J.poolDrops
    orig.drops               = J.drops
    orig.bufferFlechas       = J.bufferFlechas
    orig.cortes              = J.cortes
    orig.notificaciones      = J.notificaciones
    orig.designtegraciones   = J.designtegraciones
    orig.accionEspecial      = J.accionEspecial
    orig.cooldownsHabilidad  = J.cooldownsHabilidad
    orig.torretas            = J.torretas
    orig.granadas            = J.granadas
    orig.tiempoSlow          = J.tiempoSlow
    orig.factorSlow          = J.factorSlow
    orig.soltarDrop          = J.soltarDrop
    orig.agregarNotificacion = J.agregarNotificacion
    orig.obtenerTodosEnemigos = J.obtenerTodosEnemigos
    orig.designtegrarEnemigo = J.designtegrarEnemigo
    orig._ctxJefe            = J._ctxJefe
    originalsSaved = true
  end

  J.robin               = B.robin
  J.salaActual          = B.salaFalsa
  J.poolFlechas         = B.poolFlechas
  J.poolFlechasEnemigas = B.poolFlechasEnemigas
  J.poolDrops           = B.poolDrops
  J.drops               = B.drops
  J.bufferFlechas       = B.bufferFlechas
  J.cortes              = B.cortes
  J.notificaciones      = B.notificaciones
  J.designtegraciones   = B.designtegraciones
  J.accionEspecial      = B.accionEspecial
  J.cooldownsHabilidad  = B.cooldownsHabilidad
  J.torretas            = B.torretas
  J.granadas            = B.granadas
  J.tiempoSlow          = B.tiempoSlow
  J.factorSlow          = B.factorSlow
  J.soltarDrop          = B.soltarDrop
  J.agregarNotificacion = B.agregarNotificacion
  J.obtenerTodosEnemigos = B.obtenerTodosEnemigos
  J.designtegrarEnemigo = B.designtegrarEnemigo

  -- IMPORTANTE: invalidar cache de ctxJefe para que use la sala nueva
  J._ctxJefe = nil
end

function B.restaurarEnJ()
  asegurarJ()
  if not originalsSaved then return end
  for k, v in pairs(orig) do J[k] = v end
end

-- ============================================================
-- MAPAS
-- ============================================================
local function construirMapaSandbox()
  local W, H = 50, 36
  local mapa = {}
  for y = 1, H do
    mapa[y] = {}
    for x = 1, W do
      if x == 1 or x == W or y == 1 or y == H then
        mapa[y][x] = "#"
      else
        mapa[y][x] = "."
      end
    end
  end
  mapa.offX = 0
  mapa.offY = 0
  return mapa, W, H
end

local function construirMapaColiseo()
  local W, H = 36, 22
  local mapa = {}
  local cx, cy = (W - 1) / 2, (H - 1) / 2
  local rx, ry = cx - 0.5, cy - 0.5

  for y = 1, H do
    mapa[y] = {}
    for x = 1, W do
      local dx = (x - 1 - cx) / rx
      local dy = (y - 1 - cy) / ry
      local d = dx * dx + dy * dy

      if d > 0.92 then
        mapa[y][x] = "#"
      elseif d > 0.85 then
        mapa[y][x] = "P"
      else
        mapa[y][x] = "."
      end
    end
  end

  mapa.offX = 0
  mapa.offY = 0
  return mapa, W, H
end

-- ============================================================
-- FABRICAS
-- ============================================================
local function crearJefePorId(id, x, y)
  if id == "slime_rey" then
    return require("src.entidades.jefes.slime_rey").nuevo(x, y, 1)
  elseif id == "madre_raiz" then
    return require("src.entidades.jefes.madre_raiz").nuevo(x, y, 1)
  elseif id == "coloso_magma" then
    return require("src.entidades.jefes.coloso_magma").nuevo(x, y, 1)
  elseif id == "reina_escarcha" then
    return require("src.entidades.jefes.reina_escarcha").nuevo(x, y, 1)
  elseif id == "soberano_vacio" then
    return require("src.entidades.jefes.senor_vacio").nuevo(x, y, 1)
  end
  return nil
end

local function biomaPorJefe(id)
  if id == "slime_rey" then return Biomas.lista[1] end
  if id == "madre_raiz" then return Biomas.lista[2] end
  if id == "coloso_magma" then return Biomas.lista[3] end
  if id == "reina_escarcha" then return Biomas.lista[4] end
  if id == "soberano_vacio" then return Biomas.lista[5] end
  return Biomas.lista[1]
end

-- ============================================================
-- CAMBIAR PERSONAJE (mini PC)
-- ============================================================
local function aplicarPersonaje(idx)
  Personajes.actual = idx
  B.robin:aplicarPersonaje()
  B.robin:resetearVida()
  B.robin.dron = nil

  local p = Personajes.lista[idx]
  B.agregarNotificacion("Cambiado a " .. p.nombre,
    B.robin.x, B.robin.y - 40, {0.5, 1.0, 0.85})

  B.panelPC = false
end

local function construirPanelPC()
  B.botonesPC = {}
  local ancho = 440
  local alto = 260
  local px = (constantes.ANCHO_VIRTUAL - ancho) / 2
  local py = (constantes.ALTO_VIRTUAL - alto) / 2

  local cols = 3
  local bw = 130
  local bh = 32
  local sp = 8
  local x0 = px + (ancho - (bw * cols + sp * (cols - 1))) / 2
  local y0 = py + 60

  for i, p in ipairs(Personajes.lista) do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    local bx = x0 + col * (bw + sp)
    local by = y0 + row * (bh + sp)

    local idx = i
    local b = Boton.nuevo(bx, by, bw, bh, p.nombre, function()
      aplicarPersonaje(idx)
    end)
    table.insert(B.botonesPC, b)
  end

  B.botonPCCerrar = Boton.nuevo(
    px + ancho - 90, py + alto - 40, 80, 30, "Cerrar",
    function() B.panelPC = false end)
end

-- ============================================================
-- SALA DE LIDERES
-- ============================================================
function B.iniciarSandbox()
  B.modo = "sandbox"
  B.mapa, B.W, B.H = construirMapaSandbox()
  B.anchoMundo = B.W * T
  B.altoMundo  = B.H * T
  B.biomaActual = Biomas.lista[1]

  B.jefesDisplay = {}
  B.jefeActual = nil
  B.bossCercanoIdx = nil

  for i, jinfo in ipairs(JEFES_FILA) do
    local pos = POSICIONES[i]
    local bx = pos.x * T
    local by = pos.y * T
    local j = crearJefePorId(jinfo.id, bx, by)
    if j then
      j.estado = "idle"
      j.anim = j.anim or 0
      j.vivo = true
      j._display = true

      table.insert(B.jefesDisplay, {
        jefe = j, idx = i, nombre = jinfo.nombre,
        titulo = jinfo.titulo,
        x = bx, y = by,
      })
    end
  end

  B.salaFalsa = {
    enemigos = {}, jefe = nil, mapa = B.mapa,
    W = B.W, H = B.H, tipo = "sandbox",
    limpiada = true, visitada = true,
    puertas = { arriba = false, abajo = false, izq = false, der = false },
    bioma = B.biomaActual,
  }

  B.robin.x = (B.W / 2) * T
  B.robin.y = (B.H - 3) * T
  B.robin.vivo = true
  B.robin.invulnerable = 0
  B.robin.hp = B.robin.hpMax
  B.robin.escudo = B.robin.escudoMax
  B.robin.recurso = B.robin.recursoMax
  B.robin.dron = nil

  B.camX = B.robin.x - (constantes.ANCHO_VIRTUAL / B.zoom) / 2
  B.camY = B.robin.y - (constantes.ALTO_VIRTUAL  / B.zoom) / 2

  for p in B.poolFlechas:iterarActivos() do B.poolFlechas:devolver(p) end
  for p in B.poolFlechasEnemigas:iterarActivos() do B.poolFlechasEnemigas:devolver(p) end

  B.accionEspecial   = { tipo = nil, timer = 0, duracion = 0, fase = 1,
                         particulas = {}, golpeAplicado = {} }
  B.cortes           = {}
  B.drops            = {}
  B.notificaciones   = {}
  B.designtegraciones = {}
  B.torretas         = {}
  B.granadas         = {}
  B.cooldownsHabilidad = {0, 0, 0}
  B.tiempoSlow       = 0
  B.factorSlow       = 1
  B.panelPC          = false
  Juice.reset()

  B._victoriaTimer = nil
  B._derrotaTimer  = nil

  B.instalarEnJ()
end

-- ============================================================
-- COLISEO
-- ============================================================
function B.iniciarArena(idx)
  local info = B.jefesDisplay[idx]
  if not info then return end

  B.modo = "arena"
  B.biomaActual = biomaPorJefe(info.jefe.tipo)

  B.mapa, B.W, B.H = construirMapaColiseo()
  B.anchoMundo = B.W * T
  B.altoMundo  = B.H * T

  local jefe = crearJefePorId(info.jefe.tipo, (B.W / 2) * T, (B.H / 2) * T - 30)
  if not jefe then return end
  B.jefeActual = jefe
  jefe._display = false

  B.salaFalsa = {
    enemigos = {}, jefe = jefe, mapa = B.mapa,
    W = B.W, H = B.H, tipo = "arena",
    limpiada = false, visitada = true,
    puertas = { arriba = false, abajo = false, izq = false, der = false },
    bioma = B.biomaActual,
  }

  B.robin.x = (B.W / 2) * T
  B.robin.y = (B.H - 3) * T
  B.robin.vivo = true
  B.robin.hp = B.robin.hpMax
  B.robin.escudo = B.robin.escudoMax
  B.robin.recurso = B.robin.recursoMax
  B.robin.invulnerable = 0
  B.robin.estado = "normal"
  B.robin.recargando = false
  B.robin.dron = nil

  for p in B.poolFlechas:iterarActivos() do B.poolFlechas:devolver(p) end
  for p in B.poolFlechasEnemigas:iterarActivos() do B.poolFlechasEnemigas:devolver(p) end

  B.accionEspecial   = { tipo = nil, timer = 0, duracion = 0, fase = 1,
                         particulas = {}, golpeAplicado = {} }
  B.cortes           = {}
  B.drops            = {}
  B.notificaciones   = {}
  B.designtegraciones = {}
  B.torretas         = {}
  B.granadas         = {}
  B.cooldownsHabilidad = {0, 0, 0}
  B.tiempoSlow       = 0
  B.factorSlow       = 1
  B.panelPC          = false
  Juice.reset()
  Juice.banners(jefe.nombre or "Jefe", "Arena de practica - sin recompensas",
    2.5, B.biomaActual.llama[2])

  B._victoriaTimer = nil
  B._derrotaTimer  = nil

  B.instalarEnJ()

  B.camX = B.robin.x - (constantes.ANCHO_VIRTUAL / B.zoom) / 2
  B.camY = B.robin.y - (constantes.ALTO_VIRTUAL  / B.zoom) / 2
end

-- ============================================================
-- ENTRAR / SALIR
-- ============================================================
function B.entrar()
  asegurarJ()

  if not B.robin then
    B.robin = Jugador.nuevo(640, 720)
  else
    B.robin:aplicarPersonaje()
    B.robin:resetearVida()
  end

  B.poolFlechas         = B.poolFlechas         or Pool.nuevo(60, function() return Proyectil.nuevo() end)
  B.poolFlechasEnemigas = B.poolFlechasEnemigas or Pool.nuevo(60, function() return Proyectil.nuevo() end)
  B.poolDrops           = B.poolDrops           or Pool.nuevo(30, function() return Drop.nuevo() end)

  local escala = Config.get("escalaControles") or 1.0
  B.joyMover = Joystick.nuevo(70, constantes.ALTO_VIRTUAL - 70,
    52 * escala, 14 * escala,
    0, constantes.ALTO_VIRTUAL / 2,
    constantes.ANCHO_VIRTUAL / 2, constantes.ALTO_VIRTUAL / 2, "mover")
  B.joyApuntar = Joystick.nuevo(constantes.ANCHO_VIRTUAL - 70, constantes.ALTO_VIRTUAL - 70,
    60 * escala, 38 * escala,
    constantes.ANCHO_VIRTUAL / 2, constantes.ALTO_VIRTUAL / 2,
    constantes.ANCHO_VIRTUAL / 2, constantes.ALTO_VIRTUAL / 2, "apuntar")

  local r  = 26 * escala
  local ax = constantes.ANCHO_VIRTUAL - 90
  local ay = constantes.ALTO_VIRTUAL - 90

  B.botonesHabilidad = {
    BotonRedondo.nuevo(ax,      ay - 90, r, "1", {0.35, 0.55, 0.85}),
    BotonRedondo.nuevo(ax - 90, ay,      r, "2", {0.55, 0.35, 0.75}),
    BotonRedondo.nuevo(ax - 70, ay - 70, r, "3", {0.75, 0.45, 0.35}),
  }

  B.botonPausa = BotonRedondo.nuevo(constantes.ANCHO_VIRTUAL / 2, 20, 16, "II", {0.40, 0.40, 0.45})

  B.botonVolver = Boton.nuevo(
    constantes.ANCHO_VIRTUAL / 2 - 90, 40, 180, 30, "Volver al Sandbox",
    function() B.iniciarSandbox() end)

  B.botonPelea = Boton.nuevo(0, 0, 160, 30, "Pelea rapida", function()
    if B.bossCercanoIdx then B.iniciarArena(B.bossCercanoIdx) end
  end)

  -- Boton PC (cambiar personaje) — arriba a la derecha
  B.botonPC = Boton.nuevo(
    constantes.ANCHO_VIRTUAL - 190, 12, 178, 30, "Cambiar personaje",
    function() B.panelPC = not B.panelPC end)

  construirPanelPC()

  if J.crearBotonesExtra then J.crearBotonesExtra() end

  Juice.reset()
  B.iniciarSandbox()
  B.tGlobal = 0
end

function B.salir()
  B.restaurarEnJ()
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================
function B.actualizar(dt)
  asegurarJ()
  B.tGlobal = B.tGlobal + dt

  HUD.actualizar(dt, B.robin)
  Juice.actualizar(dt)
  if Juice.hitStop > 0 then
    Juice.hitStop = Juice.hitStop - dt
    return
  end

  -- Si el panel PC esta abierto, no se actualiza el mundo
  if B.panelPC then
    for _, b in ipairs(B.botonesPC) do b.presionado = b.presionado end
    return
  end

  local iN = 1
  while iN <= #B.notificaciones do
    local n = B.notificaciones[iN]
    n.vida = n.vida - dt
    n.y = n.y - 20 * dt
    if n.vida <= 0 then table.remove(B.notificaciones, iN) else iN = iN + 1 end
  end

  for i = 1, 3 do
    if B.cooldownsHabilidad[i] > 0 then
      B.cooldownsHabilidad[i] = B.cooldownsHabilidad[i] - dt
    end
  end
  for _, b in ipairs(B.botonesHabilidad or {}) do b:actualizar(dt) end

  local i = 1
  while i <= #B.cortes do
    local c = B.cortes[i]
    c.vida = c.vida - dt
    if c.vida <= 0 then table.remove(B.cortes, i) else i = i + 1 end
  end

  local ides = 1
  while ides <= #B.designtegraciones do
    local p = B.designtegraciones[ides]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 60 * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then table.remove(B.designtegraciones, ides) else ides = ides + 1 end
  end

  if J.actualizarAccionEspecial then J.actualizarAccionEspecial(dt) end
  if J.actualizarExtras then J.actualizarExtras(dt) end

  -- Movimiento del jugador
  local movimientoBloqueado = B.accionEspecial.bloqueaMovimiento == true

  local evento
  if B.joyMover.activo and not movimientoBloqueado then
    evento = B.robin:actualizar(dt,
      B.joyMover.dx * B.joyMover.magnitud,
      B.joyMover.dy * B.joyMover.magnitud,
      B.mapa)
  else
    evento = B.robin:actualizar(dt, 0, 0, B.mapa)
  end

  if B.joyApuntar.activo and B.joyApuntar.magnitud > 0.05 and not movimientoBloqueado then
    B.robin.ultimaDirX, B.robin.ultimaDirY = B.joyApuntar.dx, B.joyApuntar.dy
  end

  if evento == "dashFin" then
    B.robin.buffVelocidad = B.robin.buffDuracion or 5
  end

  if B.joyApuntar.disparando and B.robin:puedeDisparar()
     and B.robin.recurso >= B.robin.costeAtaque
     and not movimientoBloqueado then
    local dirX, dirY = B.joyApuntar.dx, B.joyApuntar.dy
    local ta = B.robin.tipoArma
    if ta ~= "espada" and ta ~= "dagas" and ta ~= "martillo" and ta ~= "katana" then
      if Config.get("autoAim") then
        dirX, dirY = Autoapuntado.calcular(B.robin.x, B.robin.y, dirX, dirY,
          B.obtenerTodosEnemigos())
      end
    end
    J.dispararEnDireccion(dirX, dirY)
  end

  -- ============================================================
  -- ARENA
  -- ============================================================
  if B.modo == "arena" then
    local jf = B.jefeActual

    -- ============================================================
    -- ACTUALIZAR JEFE (todos con ctx unificado)
    -- ============================================================
    if jf and jf.vivo then
      jf:actualizar(dt, B.mapa, B.robin, B.salaFalsa.enemigos, J.ctxJefe())
    end

    -- ============================================================
    -- FLECHAS DEL JUGADOR vs JEFE (esto es lo que faltaba!)
    -- ============================================================
    for p in B.poolFlechas:iterarActivos() do
      local impacto = false

      -- Jefe
      if jf and jf.vivo and not (p.golpeados and p.golpeados[jf]) then
        local dx = jf.x - p.x
        local dy = jf.y - p.y
        local r = jf.radio + p.radio
        if dx*dx + dy*dy < r*r then
          if p.golpeados then p.golpeados[jf] = true end

          local dano = p.dano
          if jf.marcadoMultiplicador and jf.marcadoTimer and jf.marcadoTimer > 0 then
            dano = dano * jf.marcadoMultiplicador
          end

          jf:recibirDanio(dano)

          if p.tipo == "orbe_fuego" and J.explotarOrbeFuego then
            J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
          end

          if not p.perforante then impacto = true end
          if not p.perforante or not p.golpeados then break end
        end
      end

      -- Enemigos invocados por el jefe (esbirros)
      for _, e in ipairs(B.salaFalsa.enemigos) do
        if e.vivo and not (p.golpeados and p.golpeados[e]) then
          local dx = e.x - p.x
          local dy = e.y - p.y
          local r = e.radio + p.radio
          if dx*dx + dy*dy < r*r then
            if p.golpeados then p.golpeados[e] = true end

            local dano = p.dano
            if e.marcadoMultiplicador and e.marcadoTimer and e.marcadoTimer > 0 then
              dano = dano * e.marcadoMultiplicador
            end

            local murio = e:recibirDanio(dano)
            if p.aplicaQuemadura then e:aplicarQuemadura(5.0) end
            if murio then
              local cantidad = e.datos.monedasAlMorir or 1
              if e.esElite then cantidad = cantidad * 2 end
              J.soltarDrop(e.x, e.y, "moneda", cantidad)
            end

            if p.tipo == "orbe_fuego" and J.explotarOrbeFuego then
              J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
            end

            if not p.perforante then impacto = true end
            if not p.perforante or not p.golpeados then break end
          end
        end
      end

      if impacto then B.poolFlechas:devolver(p) end
    end

    -- Proyectiles enemigos vs jugador
    for p in B.poolFlechasEnemigas:iterarActivos() do
      local dx = B.robin.x - p.x
      local dy = B.robin.y - p.y
      local r = B.robin.radio + p.radio
      if dx*dx + dy*dy < r*r then
        B.robin:recibirDanio(p.dano)
        if p.efecto == "slow" then B.robin:aplicarSlow(3.0) end
        B.poolFlechasEnemigas:devolver(p)
      end
    end

    -- Contacto con jefe
    if jf and jf.vivo and jf:colisiona(B.robin.x, B.robin.y, B.robin.radio) then
      B.robin:recibirDanio(jf.danoContacto or 1)
    end

    -- Charcos del jefe
    if jf then
      for _, c in ipairs(jf.charcos) do
        local dx = B.robin.x - c.x
        local dy = B.robin.y - c.y
        if dx*dx + dy*dy < (c.radio * 0.7)^2 then
          if (c.dano or 1) > 0 then B.robin:recibirDanio(c.dano or 1) end
          if c.slow then B.robin:aplicarSlow(c.slow) end
        end
      end
    end

    -- Victoria
    if jf and not jf.vivo and not B._victoriaTimer then
      Juice.banners("VICTORIA!", jf.nombre or "", 2.0, {0.5, 1, 0.5})
      B._victoriaTimer = 1.6
    end
    if B._victoriaTimer then
      B._victoriaTimer = B._victoriaTimer - dt
      if B._victoriaTimer <= 0 then
        B._victoriaTimer = nil
        B.iniciarSandbox()
        return
      end
    end

    -- Derrota
    if not B.robin.vivo and not B._derrotaTimer then
      Juice.banners("DERROTA", "Volviendo al sandbox...", 1.6, {1, 0.4, 0.4})
      B._derrotaTimer = 1.6
      B.robin.vivo = true
    end
    if B._derrotaTimer then
      B._derrotaTimer = B._derrotaTimer - dt
      if B._derrotaTimer <= 0 then
        B._derrotaTimer = nil
        B.iniciarSandbox()
        return
      end
    end

  else
    -- ============================================================
    -- SALA DE LIDERES
    -- ============================================================
    for _, info in ipairs(B.jefesDisplay) do
      info.jefe.anim = (info.jefe.anim or 0) + dt
    end

    B.bossCercanoIdx = nil
    local mejorD = 70 * 70
    for _, info in ipairs(B.jefesDisplay) do
      local dx = B.robin.x - info.x
      local dy = B.robin.y - info.y
      local d2 = dx * dx + dy * dy
      if d2 < mejorD then
        mejorD = d2
        B.bossCercanoIdx = info.idx
      end
    end
  end

  -- Proyectiles (avanzan)
  for p in B.poolFlechas:iterarActivos() do
    if not p:actualizar(dt, B.mapa) then
      if p.tipo == "orbe_fuego" and J.explotarOrbeFuego then
        J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
      end
      B.poolFlechas:devolver(p)
    end
  end
  for p in B.poolFlechasEnemigas:iterarActivos() do
    if not p:actualizar(dt, B.mapa) then
      B.poolFlechasEnemigas:devolver(p)
    end
  end

  -- Camara
  local anchoVis = constantes.ANCHO_VIRTUAL / B.zoom
  local altoVis  = constantes.ALTO_VIRTUAL  / B.zoom
  local objetivoX = B.robin.x - anchoVis / 2
  local objetivoY = B.robin.y - altoVis  / 2

  local maxX = B.anchoMundo - anchoVis
  local maxY = B.altoMundo - altoVis
  if maxX < 0 then objetivoX = B.anchoMundo / 2 - anchoVis / 2
  else objetivoX = math.max(0, math.min(objetivoX, maxX)) end
  if maxY < 0 then objetivoY = B.altoMundo / 2 - altoVis / 2
  else objetivoY = math.max(0, math.min(objetivoY, maxY)) end

  local factor = math.min(1, dt * 8)
  B.camX = B.camX + (objetivoX - B.camX) * factor
  B.camY = B.camY + (objetivoY - B.camY) * factor
end

-- ============================================================
-- DIBUJAR
-- ============================================================
local function colorSuelo(bioma, x, y)
  if (x + y) % 2 == 0 then
    love.graphics.setColor(bioma.suelo1[1], bioma.suelo1[2], bioma.suelo1[3])
  else
    love.graphics.setColor(bioma.suelo2[1], bioma.suelo2[2], bioma.suelo2[3])
  end
end

local function colorPared(bioma)
  love.graphics.setColor(bioma.pared[1], bioma.pared[2], bioma.pared[3])
end

local function colorParedLinea(bioma)
  love.graphics.setColor(bioma.paredLinea[1], bioma.paredLinea[2], bioma.paredLinea[3])
end

local function dibujarPanelPC()
  if not B.panelPC then return end

  -- Fondo oscuro
  love.graphics.setColor(0, 0, 0, 0.80)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  local ancho = 440
  local alto = 260
  local px = (constantes.ANCHO_VIRTUAL - ancho) / 2
  local py = (constantes.ALTO_VIRTUAL - alto) / 2

  -- Panel
  love.graphics.setColor(0.08, 0.12, 0.22, 0.98)
  love.graphics.rectangle("fill", px, py, ancho, alto, 8)
  love.graphics.setColor(0.55, 0.85, 1.0, 0.85)
  love.graphics.rectangle("line", px, py, ancho, alto, 8)

  -- Esquinas
  local s = 8
  love.graphics.setColor(1, 0.85, 0.35, 0.95)
  love.graphics.setLineWidth(2)
  love.graphics.line(px + 4, py + 4, px + 4 + s, py + 4)
  love.graphics.line(px + 4, py + 4, px + 4, py + 4 + s)
  love.graphics.line(px + ancho - 4, py + 4, px + ancho - 4 - s, py + 4)
  love.graphics.line(px + ancho - 4, py + 4, px + ancho - 4, py + 4 + s)
  love.graphics.line(px + 4, py + alto - 4, px + 4 + s, py + alto - 4)
  love.graphics.line(px + 4, py + alto - 4, px + 4, py + alto - 4 - s)
  love.graphics.line(px + ancho - 4, py + alto - 4, px + ancho - 4 - s, py + alto - 4)
  love.graphics.line(px + ancho - 4, py + alto - 4, px + ancho - 4, py + alto - 4 - s)
  love.graphics.setLineWidth(1)

  -- Titulo
  local f = love.graphics.getFont()
  local titulo = "CAMBIAR PERSONAJE"
  local tw = f:getWidth(titulo) * 1.3
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(titulo, px + (ancho - tw) / 2 + 1, py + 18 + 1, 0, 1.3, 1.3)
  love.graphics.setColor(1, 0.90, 0.55)
  love.graphics.print(titulo, px + (ancho - tw) / 2, py + 18, 0, 1.3, 1.3)

  love.graphics.setColor(0.55, 0.85, 1.0, 0.5)
  love.graphics.rectangle("fill", px + 20, py + 48, ancho - 40, 1)

  -- Botones de personajes
  for i, b in ipairs(B.botonesPC) do
    local p = Personajes.lista[i]
    local esActual = (i == Personajes.actual)
    local esHover = b.presionado

    local colorBase
    if esActual then
      colorBase = {0.55, 1.0, 0.65}
    else
      colorBase = {0.55, 0.85, 1.0}
    end

    love.graphics.setColor(0.10, 0.15, 0.25, 0.9)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4)

    if esHover then
      love.graphics.setColor(1, 0.85, 0.35, 0.95)
    elseif esActual then
      love.graphics.setColor(0.55, 1.0, 0.65, 0.9)
    else
      love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.6)
    end
    love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4)

    local txt = b.texto
    local tw2 = f:getWidth(txt)
    local th2 = f:getHeight()
    local tx2 = b.x + (b.w - tw2) / 2
    local ty2 = b.y + (b.h - th2) / 2

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(txt, tx2 + 1, ty2 + 1)
    if esActual then
      love.graphics.setColor(0.55, 1.0, 0.65)
    elseif esHover then
      love.graphics.setColor(1, 0.95, 0.75)
    else
      love.graphics.setColor(1, 1, 1)
    end
    love.graphics.print(txt, tx2, ty2)
  end

  -- Boton cerrar
  local b = B.botonPCCerrar
  love.graphics.setColor(0.10, 0.15, 0.25, 0.9)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4)
  love.graphics.setColor(1, 0.55, 0.55, b.presionado and 0.95 or 0.7)
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4)
  local twC = f:getWidth(b.texto)
  local thC = f:getHeight()
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(b.texto, b.x + (b.w - twC) / 2 + 1, b.y + (b.h - thC) / 2 + 1)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(b.texto, b.x + (b.w - twC) / 2, b.y + (b.h - thC) / 2)

  -- Texto debajo
  local fActual = Personajes.lista[Personajes.actual]
  local subt = "Actual: " .. fActual.nombre .. " (" .. fActual.tipo .. ")"
  local twS = f:getWidth(subt)
  love.graphics.setColor(0.75, 0.88, 1.0)
  love.graphics.print(subt, px + (ancho - twS) / 2, py + alto - 74)
end

function B.dibujar()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  local bioma = B.biomaActual or Biomas.lista[1]

  love.graphics.push()
  love.graphics.scale(B.zoom, B.zoom)
  love.graphics.translate(-B.camX, -B.camY)

  -- Culling
  local anchoVis = constantes.ANCHO_VIRTUAL / B.zoom
  local altoVis  = constantes.ALTO_VIRTUAL  / B.zoom
  local tileIniX = math.max(1, math.floor(B.camX / T) - 1)
  local tileFinX = math.min(B.W, math.ceil((B.camX + anchoVis) / T) + 1)
  local tileIniY = math.max(1, math.floor(B.camY / T) - 1)
  local tileFinY = math.min(B.H, math.ceil((B.camY + altoVis) / T) + 1)

  for y = tileIniY, tileFinY do
    for x = tileIniX, tileFinX do
      local px, py = (x - 1) * T, (y - 1) * T
      colorSuelo(bioma, x, y)
      love.graphics.rectangle("fill", px, py, T, T)
      love.graphics.setColor(bioma.linea[1], bioma.linea[2], bioma.linea[3], 0.5)
      love.graphics.rectangle("line", px, py, T, T)
    end
  end

  for y = tileIniY, tileFinY do
    for x = tileIniX, tileFinX do
      local tile = B.mapa[y][x]
      local px, py = (x - 1) * T, (y - 1) * T

      if tile == "#" then
        colorPared(bioma)
        love.graphics.rectangle("fill", px, py, T, T)
        colorParedLinea(bioma)
        love.graphics.rectangle("fill", px, py + 7, T, 1)
        love.graphics.rectangle("fill", px + 8, py, 1, 7)
        love.graphics.setColor(bioma.paredLuz[1], bioma.paredLuz[2], bioma.paredLuz[3], 0.5)
        love.graphics.rectangle("fill", px, py, T, 1)
      elseif tile == "P" then
        colorPared(bioma)
        love.graphics.rectangle("fill", px, py, T, T)
        colorParedLinea(bioma)
        love.graphics.rectangle("fill", px + 3, py + 3, T - 6, T - 6)
        love.graphics.setColor(bioma.paredLuz[1], bioma.paredLuz[2], bioma.paredLuz[3], 0.7)
        love.graphics.circle("fill", px + 8, py + 8, 2)
      end
    end
  end

  -- Sala de lideres: pedestales + jefes
  if B.modo == "sandbox" then
    for _, info in ipairs(B.jefesDisplay) do
      local jf = info.jefe
      local bx, by = info.x, info.y
      local t = B.tGlobal
      local pulso = 0.5 + 0.5 * math.sin(t * 2)

      love.graphics.setColor(0, 0, 0, 0.45)
      love.graphics.ellipse("fill", bx, by + 24, 32, 8)

      love.graphics.setColor(bioma.pared[1] * 1.2, bioma.pared[2] * 1.2, bioma.pared[3] * 1.2)
      love.graphics.ellipse("fill", bx, by + 22, 32, 8)
      love.graphics.setColor(bioma.paredLuz[1], bioma.paredLuz[2], bioma.paredLuz[3])
      love.graphics.ellipse("line", bx, by + 22, 32, 8)

      love.graphics.setColor(bioma.llama[1][1], bioma.llama[1][2], bioma.llama[1][3], 0.15 + pulso * 0.15)
      love.graphics.circle("line", bx, by, 40 + pulso * 4)

      if jf.vivo then jf:dibujar() end

      local f = love.graphics.getFont()
      local twN = f:getWidth(info.nombre)
      love.graphics.setColor(0, 0, 0, 0.85)
      love.graphics.print(info.nombre, bx - twN / 2 + 2, by - 100 + 2)
      love.graphics.setColor(1, 0.90, 0.55)
      love.graphics.print(info.nombre, bx - twN / 2, by - 100)

      local twT = f:getWidth(info.titulo) * 0.7
      love.graphics.setColor(0, 0, 0, 0.7)
      love.graphics.print(info.titulo, bx - twT / 2 + 1, by - 84 + 1, 0, 0.7, 0.7)
      love.graphics.setColor(0.75, 0.88, 1.0)
      love.graphics.print(info.titulo, bx - twT / 2, by - 84, 0, 0.7, 0.7)
    end
  end

  -- Arena: antorchas + jefe
  if B.modo == "arena" then
    local posicionesAntorchas = {
      { x = (B.W / 2) * T, y = 2 * T },
      { x = (B.W / 2) * T, y = (B.H - 1) * T },
      { x = 2 * T, y = (B.H / 2) * T },
      { x = (B.W - 1) * T, y = (B.H / 2) * T },
    }
    for _, p in ipairs(posicionesAntorchas) do
      local t = B.tGlobal
      local p1 = 0.5 + 0.5 * math.sin(t * 8 + p.x * 0.1)
      love.graphics.setColor(bioma.llama[1][1], bioma.llama[1][2], bioma.llama[1][3], 0.7)
      love.graphics.circle("fill", p.x, p.y, 6 + p1 * 2)
      love.graphics.setColor(bioma.llama[2][1], bioma.llama[2][2], bioma.llama[2][3], 0.9)
      love.graphics.circle("fill", p.x, p.y, 3)
      love.graphics.setColor(bioma.llama[3][1], bioma.llama[3][2], bioma.llama[3][3], 0.95)
      love.graphics.circle("fill", p.x, p.y, 1.5)
      love.graphics.setColor(bioma.llama[1][1], bioma.llama[1][2], bioma.llama[1][3], 0.10 + p1 * 0.08)
      love.graphics.circle("fill", p.x, p.y, 24 + p1 * 4)
    end

    if B.jefeActual and B.jefeActual.vivo then
      B.jefeActual:dibujar()
    end
  end

  for _, d in ipairs(B.drops) do d:dibujar() end
  for p in B.poolFlechas:iterarActivos() do p:dibujar() end
  for p in B.poolFlechasEnemigas:iterarActivos() do p:dibujar() end

  for _, c in ipairs(B.cortes) do J.dibujarCorte(c) end

  if J.dibujarExtrasMundo then J.dibujarExtrasMundo() end

  for _, p in ipairs(B.designtegraciones) do
    local a = p.vida / p.maxVida
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], a * 0.35)
    love.graphics.circle("fill", p.x, p.y, p.radio * 3)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], a)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.4)
  end

  B.robin:dibujar()

  Juice.dibujarMundo()

  local f = love.graphics.getFont()
  for _, n in ipairs(B.notificaciones) do
    local alpha = math.min(1, n.vida)
    love.graphics.setColor(0, 0, 0, alpha * 0.6)
    local tw = f:getWidth(n.texto)
    love.graphics.print(n.texto, n.x - tw / 2 + 1, n.y + 1)
    love.graphics.setColor(n.color[1], n.color[2], n.color[3], alpha)
    love.graphics.print(n.texto, n.x - tw / 2, n.y)
  end

  love.graphics.pop()

  -- UI
  B.joyMover:dibujar()
  B.joyApuntar:dibujar()

  for i, b in ipairs(B.botonesHabilidad or {}) do
    b:dibujar()
    local cd = B.cooldownsHabilidad[i] or 0
    if cd > 0 then
      local h = B.robin.personaje.habilidades[i]
      if h then
        local frac = cd / h.cooldown
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.arc("fill", b.cx, b.cy, b.radio - 2,
          -math.pi / 2, -math.pi / 2 + math.pi * 2 * frac)
        love.graphics.setColor(1, 1, 1, 0.9)
        local txt = string.format("%.1f", cd)
        local tw = f:getWidth(txt)
        love.graphics.print(txt, b.cx - tw / 2, b.cy + b.radio + 2, 0, 0.7, 0.7)
      end
    end
  end

  if J.dibujarBotonesExtra then J.dibujarBotonesExtra() end

  B.botonPausa:dibujar()
  HUD.dibujar(B.robin, 0)

  -- Boton "Pelea rapida"
  if B.modo == "sandbox" and B.bossCercanoIdx then
    local info = B.jefesDisplay[B.bossCercanoIdx]
    local px = (info.x - B.camX) * B.zoom - B.botonPelea.w / 2
    local py = (info.y - B.camY) * B.zoom - 130
    B.botonPelea.x = px
    B.botonPelea.y = py
    B.botonPelea:dibujar()
  end

  if B.modo == "arena" then
    B.botonVolver:dibujar()
  end

  -- Boton "Cambiar personaje" (siempre visible)
  B.botonPC:dibujar()

  -- Barra del jefe (arena)
  if B.modo == "arena" and B.jefeActual and B.jefeActual.vivo
     and B.jefeActual.barraSuperior ~= false
     and B.jefeActual.estado ~= "intro" then
    local jf = B.jefeActual
    local w, h = 260, 9
    local x = (constantes.ANCHO_VIRTUAL - w) / 2
    local y = 30
    local frac = math.max(0, jf.hp / jf.hpMax)

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6, 3)
    love.graphics.setColor(0.22, 0.08, 0.10)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.85, 0.18, 0.22)
    love.graphics.rectangle("fill", x, y, w * frac, h)
    love.graphics.setColor(1, 0.85, 0.40, 0.9)
    love.graphics.rectangle("line", x - 3, y - 3, w + 6, h + 6, 3)

    local txt = jf.nombre or "Jefe"
    local tw = f:getWidth(txt)
    love.graphics.setColor(1, 0.92, 0.75)
    love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, y - 18)
  end

  -- Textos
  if B.modo == "sandbox" then
    love.graphics.setColor(0.75, 0.90, 1.0, 0.9)
    love.graphics.print("SALA DE LIDERES", 12, 12)
    love.graphics.setColor(0.55, 0.70, 0.85, 0.85)
    love.graphics.print("Acercate a un jefe para pelear", 12, 28)
  else
    love.graphics.setColor(0.75, 0.90, 1.0, 0.9)
    love.graphics.print("COLISEO - " .. (B.jefeActual and B.jefeActual.nombre or ""), 12, 12)
    love.graphics.setColor(0.55, 0.70, 0.85, 0.85)
    love.graphics.print(B.biomaActual and B.biomaActual.nombre or "", 12, 28)
  end

  Juice.dibujarPantalla(constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL, B.biomaActual)

  -- Panel PC (encima de todo)
  dibujarPanelPC()
end

-- ============================================================
-- INPUT
-- ============================================================
function B.touchpressed(id, x, y)
  -- Si el panel PC esta abierto, solo capturar sus botones
  if B.panelPC then
    for _, b in ipairs(B.botonesPC) do
      if b:touchpressed(id, x, y) then return end
    end
    B.botonPCCerrar:touchpressed(id, x, y)
    return
  end

  -- Boton "Cambiar personaje" siempre disponible
  if B.botonPC and B.botonPC:touchpressed(id, x, y) then return end

  for i, b in ipairs(B.botonesHabilidad or {}) do
    if b:touchpressed(id, x, y) then
      J.intentarHabilidad(i)
      return
    end
  end

  if J.botonRodar and J.botonRodar:touchpressed(id, x, y) then
    J.accionRodar()
    return
  end
  if J.botonFrasco and J.botonFrasco:touchpressed(id, x, y) then
    J.accionFrasco()
    return
  end

  if B.modo == "arena" and B.botonVolver:touchpressed(id, x, y) then return end
  if B.modo == "sandbox" and B.bossCercanoIdx and B.botonPelea:touchpressed(id, x, y) then
    return
  end

  if B.joyMover:touchpressed(id, x, y) then return end
  if B.joyApuntar:touchpressed(id, x, y) then return end
end

function B.touchmoved(id, x, y)
  if B.panelPC then return end
  B.joyMover:touchmoved(id, x, y)
  B.joyApuntar:touchmoved(id, x, y)
end

function B.touchreleased(id, x, y)
  if B.panelPC then
    for _, b in ipairs(B.botonesPC) do
      b:touchreleased(id, x, y)
    end
    B.botonPCCerrar:touchreleased(id, x, y)
    return
  end

  if B.botonPC then B.botonPC:touchreleased(id, x, y) end

  for _, b in ipairs(B.botonesHabilidad or {}) do
    b:touchreleased(id, x, y)
  end
  if J.botonRodar  then J.botonRodar:touchreleased(id, x, y) end
  if J.botonFrasco then J.botonFrasco:touchreleased(id, x, y) end
  if B.modo == "arena" then B.botonVolver:touchreleased(id, x, y) end
  if B.modo == "sandbox" and B.bossCercanoIdx then
    B.botonPelea:touchreleased(id, x, y)
  end
  B.joyMover:touchreleased(id, x, y)
  B.joyApuntar:touchreleased(id, x, y)
end

function B.keypressed(key)
  if B.panelPC then
    if key == "escape" then B.panelPC = false end
    return
  end

  if key == "escape" then
    if B.modo == "arena" then
      B.iniciarSandbox()
    else
      Estados.cambiar("menu")
    end
  elseif key == "p" then
    B.panelPC = not B.panelPC
  elseif key == "space" or key == "lshift" then
    J.accionRodar()
  elseif key == "f" then
    J.accionFrasco()
  elseif key == "1" or key == "2" or key == "3" then
    J.intentarHabilidad(tonumber(key))
  end
end

return B