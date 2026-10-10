local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local Mazmorra   = require("src.datos.mazmorra")
local textos     = require("src.datos.textos")
local sonidos    = require("src.datos.sonidos")
local Config     = require("src.datos.config")
local Jugador    = require("src.entidades.jugador")
local Enemigo    = require("src.entidades.enemigo")
local Proyectil  = require("src.entidades.proyectil")
local Drop       = require("src.entidades.drop")
local NPC        = require("src.entidades.npc")
local Jefes      = require("src.entidades.jefes")
local Biomas     = require("src.datos.biomas")
local Juice      = require("src.sistemas.juice")
local Sangre     = require("src.sistemas.sangre")
local FX         = require("src.sistemas.fx_habilidades")
local Joystick   = require("src.ui.joystick")
local BotonRedondo = require("src.ui.botonRedondo")
local Boton      = require("src.ui.boton")
local Colisiones = require("src.sistemas.colisiones")
local Pool       = require("src.utils.pool")
local Guardado   = require("src.datos.guardado")
local Red        = require("src.red")

local RW = J.RW
local RH = J.RH

function J.salaWorldPos(s)
  return s.mapa.offX or 0, s.mapa.offY or 0
end

local function estaCercaDePuerta(x, y, s)
  local rx, ry = s.mapa.offX, s.mapa.offY
  local t = 16
  local cx = math.floor(s.W / 2)
  local cy = math.floor(s.H / 2)
  local puertas = {}
  if s.puertas.arriba then
    table.insert(puertas, { x = rx + cx * t + t/2, y = ry + t / 2 })
  end
  if s.puertas.abajo then
    table.insert(puertas, { x = rx + cx * t + t/2, y = ry + s.H * t - t / 2 })
  end
  if s.puertas.izq then
    table.insert(puertas, { x = rx + t / 2, y = ry + cy * t + t/2 })
  end
  if s.puertas.der then
    table.insert(puertas, { x = rx + s.W * t - t / 2, y = ry + cy * t + t/2 })
  end
  for _, p in ipairs(puertas) do
    local dx = x - p.x
    local dy = y - p.y
    if dx * dx + dy * dy < 90 * 90 then return true end
  end
  return false
end

J.estaCercaDePuerta = estaCercaDePuerta

-- ============================================================
-- ENTRAR
-- ============================================================

function J.entrar(nivelInicial, nuevaPartida, continuar)
  if continuar then
    J.pausado = false
    return
  end
  J.nivel = nivelInicial or 1
  if nuevaPartida then J.robin = nil end
  J.iniciarNivel(J.nivel)
end

-- ============================================================
-- INICIAR NIVEL
-- ============================================================

function J.iniciarNivel(n)
  J.nivel = n
  J.salas = Mazmorra.generar(n)
  J.salaIndice = 1
  J.salaActual = J.salas[1]

  -- MP: forzar que la sala 1 sea de combate (con enemigos)
  if Red.activo then
    J.salaActual.tipo = "combate"
    J.salaActual.visitada = false
    J.salaActual.limpiada = false
    J.salaActual.enemigos = {}
    J.salaActual.jefe = nil
  end

  local rx, ry = J.salaWorldPos(J.salaActual)
  local spawnX = rx + RW / 2
  local spawnY = ry + RH - 50

  -- En MP: host a la izquierda, cliente a la derecha
  if Red.activo then
    spawnX = rx + RW * 0.25
  end

  if not J.robin then
    J.robin = Jugador.nuevo(spawnX, spawnY)
  else
    J.robin.x, J.robin.y = spawnX, spawnY
    J.robin.vivo = true
    J.robin.invulnerable = 0
    J.robin.estado = "normal"
    J.robin.buffVelocidad = 0
    J.robin.slowTimer = 0
    J.robin.dashTimer = 0
    J.robin.cooldownDisparo = 0
    J.robin.tiempoSinDano = 0
    J.robin.tiempoRegenEscudo = 0
    J.robin:aplicarPersonaje()
  end

  -- ============================================================
  -- MP: crear ghost del jugador remoto si somos host
  -- ============================================================
  J.remotos = J.remotos or {}
  J.remotosEnemigos = J.remotosEnemigos or {}
  J.remotosProyectiles = J.remotosProyectiles or {}
  J.remotosEProyectiles = J.remotosEProyectiles or {}
  J.remotosDrops = J.remotosDrops or {}
  J.remotosJefe = nil

  if Red.activo and Red.esHost then
    J.remotos[1] = {
      id = 1, nombre = "Cliente",
      x = rx + RW * 0.75, y = spawnY,
      dir = 0, hp = 6, hpMax = 6,
      tipoArma = "arco",
      caminando = false, animTimer = 0,
      radio = 6, vivo = true,
    }
  else
    J.remotos = {}
  end

  Juice.reset()
  Juice.iniciarAmbiente(J.salaActual.bioma, rx, ry, RW, RH)
  Sangre.reset()
  FX.reset()
  Sangre.entrarSala(J.salaActual, rx, ry, RW, RH)
  if J.nivel == 1 or (J.nivel - 1) % 3 == 0 then
    Juice.banners(J.salaActual.bioma.nombre, "Nivel " .. J.nivel, 3.0, {0.85, 0.92, 1.0})
  end

  J.drops = {}
  J.cortes = {}
  J.designtegraciones = {}
  if J.robin then J.robin.dron = nil end
  J.cooldownsHabilidad = {0, 0, 0}
  J.notificaciones = {}
  J.accionEspecial = {
    tipo = nil, timer = 0, duracion = 0, fase = 1,
    objetivoX = 0, objetivoY = 0, enemigoObjetivo = nil,
    particulas = {}, golpeAplicado = {},
  }
  J.monedasConvertidas = 0
  J.gemasGanadas = 0
  J.gemasPerdidas = 0
  J.tiempoSlow = 0
  J.factorSlow = 1
  if J.reiniciarExtras then J.reiniciarExtras() end
  J.elitesRestantes = J.calcularElitesDelNivel(n)

  local escala = Config.get("escalaControles") or 1.0

  local jx, jy = 70, constantes.ALTO_VIRTUAL - 70
  J.joyMover = Joystick.nuevo(jx, jy, 52 * escala, 14 * escala,
    0, constantes.ALTO_VIRTUAL / 2,
    constantes.ANCHO_VIRTUAL / 2,
    constantes.ALTO_VIRTUAL / 2, "mover")

  local dx0 = constantes.ANCHO_VIRTUAL - 70
  local dy0 = constantes.ALTO_VIRTUAL - 70
  J.joyApuntar = Joystick.nuevo(dx0, dy0, 60 * escala, 38 * escala,
    constantes.ANCHO_VIRTUAL / 2, constantes.ALTO_VIRTUAL / 2,
    constantes.ANCHO_VIRTUAL / 2, constantes.ALTO_VIRTUAL / 2, "apuntar")

  local r = 26 * escala
  local ax = constantes.ANCHO_VIRTUAL - 90
  local ay = constantes.ALTO_VIRTUAL - 90

  J.botonesHabilidad = {
    BotonRedondo.nuevo(ax,          ay - 90, r, "1", {0.35, 0.55, 0.85}),
    BotonRedondo.nuevo(ax - 90,     ay,      r, "2", {0.55, 0.35, 0.75}),
    BotonRedondo.nuevo(ax - 70,     ay - 70, r, "3", {0.75, 0.45, 0.35}),
  }

  J.botonPausa = BotonRedondo.nuevo(constantes.ANCHO_VIRTUAL / 2, 20, 16, "II", {0.40, 0.40, 0.45})
  if J.crearBotonesExtra then J.crearBotonesExtra() end

  if J.robin.frascos then
    J.robin.frascos = math.min(J.robin.frascosMax or 3, J.robin.frascos + (J.nivel > 1 and 1 or 0))
  end

  J.botonInteractuar = BotonRedondo.nuevo(constantes.ANCHO_VIRTUAL - 130,
                                          constantes.ALTO_VIRTUAL - 220,
                                          30 * escala, "!", {0.95, 0.75, 0.30})

  J.poolFlechas         = J.poolFlechas         or Pool.nuevo(60,  function() return Proyectil.nuevo() end)
  J.poolFlechasEnemigas = J.poolFlechasEnemigas or Pool.nuevo(220, function() return Proyectil.nuevo() end)
  J.poolDrops           = J.poolDrops           or Pool.nuevo(80,  function() return Drop.nuevo() end)

  -- Joy solo en single-player
  if J.salaActual.tipo == "inicio" and not Red.activo then
    local rx2, ry2 = J.salaWorldPos(J.salaActual)
    J.salaActual.joy = NPC.nuevaJoy(rx2 + RW / 2 - 40, ry2 + RH / 2)
  end

  local bw, bh = 60, 22
  local cyD = constantes.ALTO_VIRTUAL / 2 + 30

  J.botonCuraSi = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - bw - 6, cyD, bw, bh, "Si", function()
    if J.robin.monedas >= J.salaActual.joy.precioCura then
      J.robin.monedas = J.robin.monedas - J.salaActual.joy.precioCura
      J.robin.hp = J.robin.hpMax
      if sonidos.cura then sonidos.cura:stop() sonidos.cura:play() end
    end
    J.dialogoJoy = false
  end)

  J.botonCuraNo = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 + 6, cyD, bw, bh, "No", function()
    J.dialogoJoy = false
  end)

  local bw2, bh2 = 140, 26
  local cx2 = constantes.ANCHO_VIRTUAL / 2 - bw2 / 2
  local y02 = 100

  J.botonReanudar     = Boton.nuevo(cx2, y02,          bw2, bh2, textos.pausa.reanudar, function() J.pausado = false end)
  J.botonAjustesPausa = Boton.nuevo(cx2, y02 + 34,     bw2, bh2, textos.pausa.ajustes,  function() Estados.cambiar("ajustes") end)
  J.botonMenuPausa    = Boton.nuevo(cx2, y02 + 34 * 2, bw2, bh2, textos.pausa.menu,     function() Estados.cambiar("menu") end)

  J.botonGuardarSalir = Boton.nuevo(cx2, y02 + 34 * 3, bw2, bh2, "Guardar y salir",
    function()
      local monedas = J.robin.monedas
      local gemasConvertidas = math.floor(monedas / 10)
      if gemasConvertidas > 0 then Guardado.agregarGemas(gemasConvertidas) end
      if J.robin.gemas > 0 then Guardado.agregarGemas(J.robin.gemas) end
      local stats = Guardado.get("estadisticas")
      stats.partidasJugadas = stats.partidasJugadas + 1
      stats.nivelesCompletados = stats.nivelesCompletados + (J.nivel - 1)
      Guardado.guardar()
      J.pausado = false
      Estados.cambiar("menu")
    end)

  J.pausado = false
  J.dialogoJoy = false
  J.estadoFinNivel = nil
  J.timerFinNivel = 0

  -- MP: poblar la sala con enemigos
  if Red.activo and J.salaActual.tipo == "combate" then
    J.poblarSala(J.salaActual)
  end
end

-- ============================================================
-- ELITES
-- ============================================================

function J.calcularElitesDelNivel(n)
  if n <= 3 then return 1
  elseif n <= 6 then return 3
  elseif n <= 9 then return 5
  elseif n <= 12 then return 7
  else return 10 end
end

-- ============================================================
-- CREAR ENEMIGO
-- ============================================================

local function crearEnemigoDeTipo(tipo, x, y)
  if tipo == "slime" or tipo == "slime_pequeno" then
    return Enemigo.nuevoSlime(x, y)
  elseif tipo == "guardia" then
    return Enemigo.nuevoEsqueleto(x, y)
  elseif tipo == "arquero" then
    return Enemigo.nuevoEsqueletoArquero(x, y)
  elseif tipo == "rata" then
    return Enemigo.nuevoRata(x, y)
  elseif tipo == "murcielago" then
    return Enemigo.nuevoMurcielago(x, y)
  elseif tipo == "mago" then
    return Enemigo.nuevoMagoOscuro(x, y)
  end
  return Enemigo.nuevoDeBioma(tipo, x, y)
end

J.crearEnemigoDeTipo = crearEnemigoDeTipo

-- ============================================================
-- OLEADAS
-- ============================================================

function J.spawnearOleada(s, cantidad)
  local rx, ry = J.salaWorldPos(s)
  local bioma = s.bioma or Biomas.paraNivel(J.nivel)
  local escalaVida = Biomas.escalaVida(J.nivel)
  s.elitesEnSala = s.elitesEnSala or 0
  local maxElitesEnSala = 3

  for i = 1, cantidad do
    local tipo = Biomas.elegirEnemigo(bioma, J.nivel)
    local x, y, intentos = 0, 0, 0
    repeat
      x = rx + love.math.random(3, s.W - 3) * 16
      y = ry + love.math.random(3, s.H - 3) * 16
      intentos = intentos + 1
      local lejos = true
      if J.robin then
        local ddx, ddy = x - J.robin.x, y - J.robin.y
        lejos = (ddx * ddx + ddy * ddy) > 110 * 110
      end
    until (not Colisiones.circuloConMapa(x, y, 14, s.mapa)
           and not estaCercaDePuerta(x, y, s) and lejos)
       or intentos > 60

    local enemigo = crearEnemigoDeTipo(tipo, x, y)
    if enemigo then
      enemigo.hpMax = math.floor(enemigo.hpMax * escalaVida)
      enemigo.hp = enemigo.hpMax

      local puedeSerElite = J.elitesRestantes > 0 and s.elitesEnSala < maxElitesEnSala
      if puedeSerElite and math.random() < 0.75 then
        enemigo:hacerElite()
        J.elitesRestantes = J.elitesRestantes - 1
        s.elitesEnSala = s.elitesEnSala + 1
      end

      Juice.anillo(x, y, 18, {0.9, 0.9, 1.0}, 0.4)
      table.insert(s.enemigos, enemigo)
    end
  end

  while J.elitesRestantes > 0 and s.elitesEnSala < maxElitesEnSala and #s.enemigos > 0 do
    local idx = love.math.random(1, #s.enemigos)
    local e = s.enemigos[idx]
    if e.vivo and not e.esElite then
      e:hacerElite()
      J.elitesRestantes = J.elitesRestantes - 1
      s.elitesEnSala = s.elitesEnSala + 1
    else
      break
    end
  end
end

-- ============================================================
-- CTX JEFE
-- ============================================================

function J.ctxJefe()
  if not J._ctxJefe then
    J._ctxJefe = {
      disparar = function(x, y, dx, dy, vel, dano, tipo)
        local p = J.poolFlechasEnemigas:obtener()
        if p then p:lanzar(x, y, dx, dy, vel, dano, true, tipo) end
      end,
      minion = function(tipo, x, y)
        local arx, ary = J.salaWorldPos(J.salaActual)
        x = math.max(arx + 40, math.min(arx + RW - 40, x))
        y = math.max(ary + 40, math.min(ary + RH - 40, y))
        local e = crearEnemigoDeTipo(tipo, x, y)
        if e then
          Juice.explosion(x, y, {0.8, 0.8, 1.0}, 0.8)
          table.insert(J.salaActual.enemigos, e)
        end
      end,
      banner = function(titulo, sub)
        Juice.banners(titulo, sub, 3.2, {1, 0.45, 0.35})
      end,
    }
  end
  return J._ctxJefe
end

-- ============================================================
-- POBLAR SALA
-- ============================================================

function J.poblarSala(s)
  if s.visitada or s.tipo == "inicio" then
    s.visitada = true
    return
  end
  s.visitada = true
  s.limpiada = false

  local rx, ry = J.salaWorldPos(s)

  if s.tipo == "jefe" then
    s.jefe = Jefes.crear(J.nivel, rx + RW/2, ry + RH/2 - 30)
    J.actualizarPuertas(s)
    return
  end

  local cantidad = 3 + math.min(3, math.floor(J.nivel / 4))
  s.oleadasRestantes = 0
  if J.nivel >= 10 then s.oleadasRestantes = 2
  elseif J.nivel >= 4 then s.oleadasRestantes = 1 end
  s.cantidadOleada = math.max(2, cantidad - 1)

  J.spawnearOleada(s, cantidad)
  J.actualizarPuertas(s)
end

-- ============================================================
-- AUTOAPUNTADO
-- ============================================================

function J.obtenerTodosEnemigos()
  local todos = {}
  for _, e in ipairs(J.salaActual.enemigos) do table.insert(todos, e) end
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    table.insert(todos, J.salaActual.jefe)
  end
  return todos
end

-- ============================================================
-- PUERTAS
-- ============================================================

function J.actualizarPuertas(s)
  local W, H = s.W, s.H
  local cx = math.floor(W/2)
  local cy = math.floor(H/2)
  local abierta = s.limpiada

  if s.puertas.arriba then
    s.mapa[1][cx]   = abierta and "D" or "#"
    s.mapa[1][cx+1] = abierta and "D" or "#"
  end
  if s.puertas.abajo then
    s.mapa[H][cx]   = abierta and "D" or "#"
    s.mapa[H][cx+1] = abierta and "D" or "#"
  end
  if s.puertas.izq then
    s.mapa[cy][1]   = abierta and "D" or "#"
    s.mapa[cy+1][1] = abierta and "D" or "#"
  end
  if s.puertas.der then
    s.mapa[cy][W]   = abierta and "D" or "#"
    s.mapa[cy+1][W] = abierta and "D" or "#"
  end
end

-- ============================================================
-- TRANSICION ENTRE SALAS (host controla, cliente no)
-- ============================================================

function J.comprobarTransicion()
  if Red.activo and not Red.esHost then return end

  local rx, ry = J.salaWorldPos(J.salaActual)
  local dentro = J.robin.x > rx and J.robin.x < rx + RW
             and J.robin.y > ry and J.robin.y < ry + RH
  if dentro then return end

  local nuevaSala = nil
  local dy = 0
  if J.robin.y < ry then
    if J.salaIndice < #J.salas and J.salaActual.limpiada then
      nuevaSala = J.salas[J.salaIndice + 1]
      dy = 1
    end
  elseif J.robin.y > ry + RH then
    if J.salaIndice > 1 then
      nuevaSala = J.salas[J.salaIndice - 1]
      dy = -1
    end
  end

  if nuevaSala then
    J.salaIndice = J.salaIndice + dy
    J.salaActual = nuevaSala
    J.poblarSala(J.salaActual)

    local arx, ary = J.salaWorldPos(J.salaActual)
    Juice.iniciarAmbiente(J.salaActual.bioma, arx, ary, RW, RH)
    Sangre.entrarSala(J.salaActual, arx, ary, RW, RH)

    local nrx, nry = J.salaWorldPos(J.salaActual)
    if dy == 1 then J.robin.y = nry + RH - 40
    elseif dy == -1 then J.robin.y = nry + 40 end
    J.robin.x = math.max(nrx + 30, math.min(nrx + RW - 30, J.robin.x))

    J.drops = {}
    for p in J.poolFlechas:iterarActivos() do J.poolFlechas:devolver(p) end
    for p in J.poolFlechasEnemigas:iterarActivos() do J.poolFlechasEnemigas:devolver(p) end
  else
    J.robin.x = math.max(rx + 20, math.min(rx + RW - 20, J.robin.x))
    J.robin.y = math.max(ry + 20, math.min(ry + RH - 20, J.robin.y))
  end
end

-- ============================================================
-- DROPS
-- ============================================================

function J.soltarDrop(x, y, tipo, cantidad)
  for i = 1, cantidad do
    local d = J.poolDrops:obtener()
    if d then
      d:lanzar(x, y, tipo, 1)
      table.insert(J.drops, d)
    end
  end
end

return J