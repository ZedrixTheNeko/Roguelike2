local J          = require("src.estados.juego.estado")
local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local textos     = require("src.datos.textos")
local sonidos    = require("src.datos.sonidos")
local Config     = require("src.datos.config")
local Enemigo    = require("src.entidades.enemigo")
local Autoapuntado = require("src.sistemas.autoapuntado")
local Guardado   = require("src.datos.guardado")
local HUD        = require("src.ui.hud")
local Juice      = require("src.sistemas.juice")
local Sangre     = require("src.sistemas.sangre")
local FX         = require("src.sistemas.fx_habilidades")
local Red        = require("src.red")

function J.actualizar(dt)
  -- ============================================================
  -- HUD
  -- ============================================================
  HUD.actualizar(dt, J.robin)
  J.botonPausa:actualizar(dt)

  -- Notificaciones flotantes
  local iN = 1
  while iN <= #J.notificaciones do
    local n = J.notificaciones[iN]
    n.vida = n.vida - dt
    n.y = n.y - 20 * dt
    if n.vida <= 0 then
      table.remove(J.notificaciones, iN)
    else
      iN = iN + 1
    end
  end

  -- Actualizar input de teclado (PC)
  if J.actualizarInputTeclado then J.actualizarInputTeclado() end

  -- ============================================================
  -- RED (siempre al inicio, en ambos roles)
  -- ============================================================
  if Red.activo then
    Red.actualizar(dt)
  end

  if J.pausado then return end
  if J.dialogoJoy then return end

  -- ============================================================
  -- Juice (numeros, particulas, ambiente, banner) + hit-stop
  -- ============================================================
  Juice.actualizar(dt)
  if Juice.hitStop > 0 then
    Juice.hitStop = Juice.hitStop - dt
    return
  end
  pcall(Sangre.actualizar, dt, J.robin)
  pcall(FX.actualizar, dt)

  -- ============================================================
  -- MODO CLIENTE MP: prediccion local + return temprano
  -- ============================================================
  if Red.activo and not Red.esHost then
    local movX, movY = 0, 0
    if J.joyMover and J.joyMover.activo then
      movX = J.joyMover.dx * J.joyMover.magnitud
      movY = J.joyMover.dy * J.joyMover.magnitud
    end
    if J.inputTeclado then
      movX = movX + (J.inputTeclado.mx or 0)
      movY = movY + (J.inputTeclado.my or 0)
      local m = math.sqrt(movX * movX + movY * movY)
      if m > 1 then movX, movY = movX / m, movY / m end
    end
    local shoot = (J.joyApuntar and J.joyApuntar.disparando)
                  or (J.inputTeclado and J.inputTeclado.disparando) or false
    local angle = 0
    if J.inputTeclado and J.inputTeclado.angle then
      angle = J.inputTeclado.angle
    elseif J.joyApuntar and J.joyApuntar.activo and J.joyApuntar.magnitud > 0.05 then
      angle = math.atan2(J.joyApuntar.dy, J.joyApuntar.dx)
    end

    Red.enviarInput(movX, movY, shoot, angle, false)

    if J.robin then
      J.robin:actualizar(dt, movX, movY, J.salaActual.mapa)
      if J.inputTeclado and J.inputTeclado.angle then
        J.robin.ultimaDirX = math.cos(J.inputTeclado.angle)
        J.robin.ultimaDirY = math.sin(J.inputTeclado.angle)
      elseif J.joyApuntar and J.joyApuntar.activo and J.joyApuntar.magnitud > 0.05 then
        J.robin.ultimaDirX = J.joyApuntar.dx
        J.robin.ultimaDirY = J.joyApuntar.dy
      end
    end

    return
  end

  -- ============================================================
  -- SLOW MOTION (Coyote habilidad 3)
  -- ============================================================
  local slowActivo = (J.tiempoSlow and J.tiempoSlow > 0)
  local dtMundo = dt

  if slowActivo then
    J.tiempoSlow = J.tiempoSlow - dt
    if J.tiempoSlow <= 0 then
      J.tiempoSlow = 0
      J.factorSlow = 1
    end
    dtMundo = dt * (J.factorSlow or 0.3)
  end

  for i = 1, 3 do
    if J.cooldownsHabilidad[i] > 0 then
      J.cooldownsHabilidad[i] = J.cooldownsHabilidad[i] - dt
    end
  end

  for _, b in ipairs(J.botonesHabilidad or {}) do
    b:actualizar(dt)
  end
  if J.botonRodar then J.botonRodar:actualizar(dt) end
  if J.botonFrasco then J.botonFrasco:actualizar(dt) end

  if J.salaActual.joy then J.salaActual.joy:actualizar(dt) end

  local i = 1
  while i <= #J.cortes do
    local c = J.cortes[i]
    if not c.fxHecho then
      c.fxHecho = true
      pcall(FX.desdeCorte, c)
    end
    c.vida = c.vida - dt
    if c.vida <= 0 then table.remove(J.cortes, i) else i = i + 1 end
  end

  J.actualizarAccionEspecial(dt)
  if J.actualizarExtras then J.actualizarExtras(dt) end

  -- Dron centinela (Nyx-7)
  if J.robin.dron and J.robin.dron.activo then
    local d = J.robin.dron
    d.timer = d.timer - dt
    d.angulo = d.angulo + dt * 2.5
    d.cooldownDisparo = d.cooldownDisparo - dt

    if d.timer <= 0 then
      d.activo = false
    elseif d.cooldownDisparo <= 0 then
      local mejor = nil
      local mejorD = 300 * 300
      for _, e in ipairs(J.salaActual.enemigos) do
        if e.vivo then
          local dx = e.x - J.robin.x
          local dy = e.y - J.robin.y
          local dd = dx * dx + dy * dy
          if dd < mejorD then mejorD = dd mejor = e end
        end
      end
      if J.salaActual.jefe and J.salaActual.jefe.vivo then
        local dx = J.salaActual.jefe.x - J.robin.x
        local dy = J.salaActual.jefe.y - J.robin.y
        local dd = dx * dx + dy * dy
        if dd < mejorD then mejorD = dd mejor = J.salaActual.jefe end
      end
      if mejor then
        local dx = mejor.x - J.robin.x
        local dy = mejor.y - J.robin.y
        local m = math.sqrt(dx * dx + dy * dy)
        if m > 0.001 then
          local p = J.poolFlechas:obtener()
          if p then
            p:lanzar(J.robin.x, J.robin.y, dx / m, dy / m, 400, d.dano, false, "bala_plasma")
          end
        end
        d.cooldownDisparo = d.cadencia
      end
    end
  end

  local ides = 1
  while ides <= #J.designtegraciones do
    local p = J.designtegraciones[ides]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 60 * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then table.remove(J.designtegraciones, ides) else ides = ides + 1 end
  end

  -- ============================================================
  -- HOST MP: aplicar input remoto al "ghost" del cliente
  -- ============================================================
  if Red.activo and Red.esHost and J.remotos and J.remotos[1] then
    local r = J.remotos[1]
    local ix, iy = Red.inputRemoto.x, Red.inputRemoto.y
    local m = math.sqrt(ix * ix + iy * iy)
    if m > 0.01 then
      local vel = 100
      r.x = r.x + ix * vel * dt
      r.y = r.y + iy * vel * dt
      r.dir = math.atan2(iy, ix)
      r.caminando = true
    else
      r.caminando = false
    end
    r.animTimer = (r.animTimer or 0) + dt
  end

  -- ============================================================
  -- PANTALLA DE MUERTE
  -- ============================================================
  if J.estadoFinNivel then
    J.timerFinNivel = J.timerFinNivel + dt
    if J.estadoFinNivel == "derrota" then
      J.actualizarMuerte(dt)
    elseif J.timerFinNivel > 2.5 then
      Estados.cambiar("carga", J.nivel + 1)
    end
    return
  end

  if not J.robin.vivo then
    if J.estadoFinNivel ~= "derrota" then
      local monedas = J.robin.monedas
      local gemasConvertidas = math.floor(monedas / 10)
      if gemasConvertidas > 0 then
        Guardado.agregarGemas(gemasConvertidas)
        J.gemasGanadas = gemasConvertidas
      end
      if J.robin.gemas > 0 then Guardado.agregarGemas(J.robin.gemas) end

      local gemasActuales = Guardado.get("gemas")
      local perdidas = math.floor(gemasActuales * 0.5)
      if perdidas > 0 then
        Guardado.datos.gemas = gemasActuales - perdidas
        local mack = Guardado.get("mack")
        table.insert(mack.inventario, { tipo = "gema", cantidad = perdidas, nivel = J.nivel })
      end
      J.gemasPerdidas = perdidas

      local stats = Guardado.get("estadisticas")
      stats.partidasJugadas = stats.partidasJugadas + 1
      stats.nivelesCompletados = stats.nivelesCompletados + (J.nivel - 1)
      Guardado.guardar()

      J.estadoFinNivel = "derrota"
      J.timerFinNivel = 0
      J.resetearMuerte()
    end
    return
  end

  -- ============================================================
  -- MOVIMIENTO DEL JUGADOR (tactil + teclado)
  -- ============================================================
  local movimientoBloqueado = J.accionEspecial.bloqueaMovimiento == true

  local movX, movY = 0, 0
  if J.joyMover.activo and not movimientoBloqueado then
    movX = J.joyMover.dx * J.joyMover.magnitud
    movY = J.joyMover.dy * J.joyMover.magnitud
  end
  if J.inputTeclado and not movimientoBloqueado then
    movX = movX + (J.inputTeclado.mx or 0)
    movY = movY + (J.inputTeclado.my or 0)
    local m = math.sqrt(movX * movX + movY * movY)
    if m > 1 then movX, movY = movX / m, movY / m end
  end
  local evento = J.robin:actualizar(dt, movX, movY, J.salaActual.mapa)

  -- Apuntado: joystick tactil o mouse
  if J.joyApuntar.activo and J.joyApuntar.magnitud > 0.05 and not movimientoBloqueado then
    J.robin.ultimaDirX, J.robin.ultimaDirY = J.joyApuntar.dx, J.joyApuntar.dy
  end
  if J.inputTeclado and J.inputTeclado.angle then
    J.robin.ultimaDirX = math.cos(J.inputTeclado.angle)
    J.robin.ultimaDirY = math.sin(J.inputTeclado.angle)
  end

  if evento == "dashFin" then
    J.robin.buffVelocidad = J.robin.buffDuracion or 5
  end

  -- Disparo: joystick O mouse
  local disparando = J.joyApuntar.disparando
                     or (J.inputTeclado and J.inputTeclado.disparando)
  if disparando and J.robin:puedeDisparar()
     and J.robin.recurso >= J.robin.costeAtaque and not movimientoBloqueado then
    local dirX, dirY = J.robin.ultimaDirX, J.robin.ultimaDirY
    local ta = J.robin.tipoArma
    if ta ~= "espada" and ta ~= "dagas" and ta ~= "martillo" and ta ~= "katana" then
      if Config.get("autoAim") then
        local todos = J.obtenerTodosEnemigos()
        dirX, dirY = Autoapuntado.calcular(J.robin.x, J.robin.y, dirX, dirY, todos)
      end
    end
    J.dispararEnDireccion(dirX, dirY)
  end

  for i2 = #J.bufferFlechas, 1, -1 do J.bufferFlechas[i2] = nil end
  for p in J.poolFlechas:iterarActivos() do
    J.bufferFlechas[#J.bufferFlechas + 1] = p
  end

  -- Enemigos
  for _, e in ipairs(J.salaActual.enemigos) do
    e:actualizar(dtMundo, J.salaActual.mapa, J.robin, J.bufferFlechas)
  end

  -- Jefe
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    jf:actualizar(dtMundo, J.salaActual.mapa, J.robin, J.salaActual.enemigos, J.ctxJefe())
  end

  -- Ataques de enemigos
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.disparos and #e.disparos > 0 then
      for _, sh in ipairs(e.disparos) do
        local pn = J.poolFlechasEnemigas:obtener()
        if pn then
          pn:lanzar(sh.x, sh.y, sh.dx, sh.dy, sh.vel, sh.dano, true, sh.tipo)
        end
      end
      e.disparos = {}
    end
    if e.quiereDisparar then
      e.quiereDisparar = false
      local p = J.poolFlechasEnemigas:obtener()
      if p then
        if e.tipo == "mago_oscuro" then
          p:lanzar(e.x, e.y, e.disparoDirX, e.disparoDirY,
            e.datos.velocidadProyectil or 140,
            (e.datos.danoProyectil or 2) * (e.danoMultiplicador or 1),
            true, "bola_oscura")
        else
          p:lanzar(e.x, e.y, e.disparoDirX, e.disparoDirY,
            e.datos.velocidadFlecha or 180,
            (e.datos.danoFlecha or 1) * (e.danoMultiplicador or 1),
            true, "flecha")
        end
      end
    end
    if e.quiereDispararAbanico then
      e.quiereDispararAbanico = false
      for k = -1, 1 do
        local key = "flecha_" .. (k + 2)
        local datos = e.habExtraData and e.habExtraData[key]
        if datos then
          local p = J.poolFlechasEnemigas:obtener()
          if p then
            p:lanzar(e.x, e.y, datos.dirX, datos.dirY,
              e.datos.velocidadFlecha or 180,
              (e.datos.danoFlecha or 1) * (e.danoMultiplicador or 1),
              true, "flecha")
          end
          e.habExtraData[key] = nil
        end
      end
    end
    if e.quiereDispararLluvia then
      e.quiereDispararLluvia = false
      if e.habExtraData and e.habExtraData.bolas then
        for _, bola in ipairs(e.habExtraData.bolas) do
          local p = J.poolFlechasEnemigas:obtener()
          if p then
            p:lanzar(bola.x, bola.y - 60, 0, 1, 200,
              (e.datos.danoProyectil or 2) * (e.danoMultiplicador or 1),
              true, "bola_oscura")
          end
        end
        e.habExtraData.bolas = nil
      end
    end
  end

  -- Proyectiles del jugador vs enemigos
  for p in J.poolFlechas:iterarActivos() do
    local impacto = false
    for _, e in ipairs(J.salaActual.enemigos) do
      if e.vivo then
        local dx, dy = e.x - p.x, e.y - p.y
        local r = e.radio + p.radio
        if dx*dx + dy*dy < r*r and not (p.golpeados and p.golpeados[e]) then
          if p.golpeados then p.golpeados[e] = true end
          local dano = p.dano
          if e.marcadoMultiplicador and e.marcadoTimer and e.marcadoTimer > 0 then
            dano = dano * e.marcadoMultiplicador
          end
          if p.vx then pcall(Sangre.hint, p.vx, p.vy) end
          local murio = e:recibirDanio(dano)
          if sonidos.impacto then sonidos.impacto:stop() sonidos.impacto:play() end
          if p.aplicaQuemadura then e:aplicarQuemadura(5.0) end
          if murio then
            if sonidos.muerte_enemigo then sonidos.muerte_enemigo:stop() sonidos.muerte_enemigo:play() end
            local cantidad = e.datos.monedasAlMorir
            if e.esElite then cantidad = cantidad * 2 end
            J.soltarDrop(e.x, e.y, "moneda", cantidad)
          end
          if p.tipo == "orbe_fuego" then
            J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
          end
          if not p.perforante then impacto = true end
          if not p.perforante or not p.golpeados then break end
        end
      end
    end
    if not impacto and J.salaActual.jefe and J.salaActual.jefe.vivo then
      local jf = J.salaActual.jefe
      local dx, dy = jf.x - p.x, jf.y - p.y
      local r = jf.radio + p.radio
      if dx*dx + dy*dy < r*r and not (p.golpeados and p.golpeados[jf]) then
        if p.golpeados then p.golpeados[jf] = true end
        local dano = p.dano
        if jf.marcadoMultiplicador and jf.marcadoTimer and jf.marcadoTimer > 0 then
          dano = dano * jf.marcadoMultiplicador
        end
        jf:recibirDanio(dano)
        if sonidos.impacto then sonidos.impacto:stop() sonidos.impacto:play() end
        if p.tipo == "orbe_fuego" then
          J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
        end
        if not p.perforante then impacto = true end
      end
    end
    if impacto then J.poolFlechas:devolver(p) end
  end

  -- Orbes de Merlin
  if J.robin.orbsActivos then
    for _, o in ipairs(J.robin.orbs) do
      local ang = o.angulo + J.robin.orbsAngulo
      local ox = J.robin.x + math.cos(ang) * o.radioOrbita
      local oy = J.robin.y + math.sin(ang) * o.radioOrbita
      for _, e in ipairs(J.salaActual.enemigos) do
        if e.vivo and e.orbeCooldown <= 0 then
          local dx, dy = e.x - ox, e.y - oy
          local r = e.radio + o.radioBola
          if dx*dx + dy*dy < r*r then
            local murio = e:recibirDanio(o.dano)
            e:aplicarQuemadura(5.0)
            e.orbeCooldown = 0.5
            if sonidos.impacto then sonidos.impacto:stop() sonidos.impacto:play() end
            if murio then
              if sonidos.muerte_enemigo then sonidos.muerte_enemigo:stop() sonidos.muerte_enemigo:play() end
              local cantidad = e.datos.monedasAlMorir
              if e.esElite then cantidad = cantidad * 2 end
              J.soltarDrop(e.x, e.y, "moneda", cantidad)
            end
          end
        end
      end
      if J.salaActual.jefe and J.salaActual.jefe.vivo then
        local jf = J.salaActual.jefe
        local dx, dy = jf.x - ox, jf.y - oy
        local r = jf.radio + o.radioBola
        if dx*dx + dy*dy < r*r then jf:recibirDanio(o.dano * 0.5) end
      end
    end
  end

  -- Proyectiles enemigos vs jugador
  for p in J.poolFlechasEnemigas:iterarActivos() do
    local dx, dy = J.robin.x - p.x, J.robin.y - p.y
    local r = J.robin.radio + p.radio
    if dx*dx + dy*dy < r*r then
      local recibio = J.robin:recibirDanio(p.dano)
      if recibio and sonidos.danio_jugador then
        sonidos.danio_jugador:stop() sonidos.danio_jugador:play()
      end
      if p.efecto == "slow" then J.robin:aplicarSlow(3.0) end
      J.poolFlechasEnemigas:devolver(p)
    end
  end

  -- Contacto cuerpo a cuerpo
  for _, e in ipairs(J.salaActual.enemigos) do
    local dc = e.contactoDano
    if dc == nil then dc = e.datos.danoContacto end
    if e.vivo and dc and dc > 0 then
      local dx, dy = e.x - J.robin.x, e.y - J.robin.y
      local r = e.radio + J.robin.radio
      if dx*dx + dy*dy < r*r then
        local dano = dc * (e.danoMultiplicador or 1)
        local recibio = J.robin:recibirDanio(dano)
        if recibio and sonidos.danio_jugador then
          sonidos.danio_jugador:stop() sonidos.danio_jugador:play()
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe:colisiona(J.robin.x, J.robin.y, J.robin.radio) then
    local recibio = J.robin:recibirDanio(J.salaActual.jefe.danoContacto or 1)
    if recibio and sonidos.danio_jugador then
      sonidos.danio_jugador:stop() sonidos.danio_jugador:play()
    end
  end

  if J.salaActual.jefe then
    for _, c in ipairs(J.salaActual.jefe.charcos) do
      local dx, dy = J.robin.x - c.x, J.robin.y - c.y
      if dx*dx + dy*dy < (c.radio * 0.7)^2 then
        if (c.dano or 1) > 0 then J.robin:recibirDanio(c.dano or 1) end
        if c.slow then J.robin:aplicarSlow(c.slow) end
      end
    end
  end

  -- Actualizar proyectiles
  for p in J.poolFlechas:iterarActivos() do
    if not p:actualizar(dt, J.salaActual.mapa) then
      if p.tipo == "orbe_fuego" then
        J.explotarOrbeFuego(p.x, p.y, p.radioExplosion, p.danoExplosion)
      end
      J.poolFlechas:devolver(p)
    end
  end
  for p in J.poolFlechasEnemigas:iterarActivos() do
    if not p:actualizar(dtMundo, J.salaActual.mapa) then
      J.poolFlechasEnemigas:devolver(p)
    end
  end

  -- Drops
  local idx = 1
  while idx <= #J.drops do
    local d = J.drops[idx]
    local resultado = d:actualizar(dtMundo, J.robin, J.salaActual.mapa)
    if resultado == true then
      local cant = d.cantidad or 1
      if d.tipo == "moneda" then
        J.robin.monedas = J.robin.monedas + cant
      else
        J.robin.gemas = J.robin.gemas + cant
      end
      J.poolDrops:devolver(d)
      table.remove(J.drops, idx)
    elseif resultado == "expirado" then
      J.poolDrops:devolver(d)
      table.remove(J.drops, idx)
    else
      idx = idx + 1
    end
  end

  -- Limpieza de sala
  if not J.salaActual.limpiada then
    local vivos = false
    for _, e in ipairs(J.salaActual.enemigos) do
      if e.vivo then vivos = true break end
    end
    if J.salaActual.jefe and J.salaActual.jefe.vivo then vivos = true end

    if not vivos and (J.salaActual.oleadasRestantes or 0) > 0 then
      J.salaActual.oleadasRestantes = J.salaActual.oleadasRestantes - 1
      J.spawnearOleada(J.salaActual, J.salaActual.cantidadOleada or 3)
      J.agregarNotificacion("Nueva oleada!", J.robin.x, J.robin.y - 40, {1, 0.6, 0.35})
      Juice.sacudir(2, 0.3)
      vivos = true
    end

    if not vivos then
      J.salaActual.limpiada = true
      J.actualizarPuertas(J.salaActual)
      if sonidos.nivel_completo then
        sonidos.nivel_completo:stop() sonidos.nivel_completo:play()
      end

      if J.salaActual.tipo == "jefe" and J.salaActual.jefe and not J.salaActual.jefe.vivo then
        if not J.salaActual.jefeRecompensado then
          J.salaActual.jefeRecompensado = true
          local recompensa = J.salaActual.jefe.recompensa or 30
          Guardado.agregarGemas(recompensa)
          Juice.banners("JEFE DERROTADO", J.salaActual.jefe.nombre or "", 3.0, {1, 0.85, 0.30})
          J.robin.frascos = math.min(J.robin.frascosMax or 3, (J.robin.frascos or 0) + 1)
          J.agregarNotificacion("PORTADOR DERROTADO", J.robin.x, J.robin.y - 45, {1, 0.85, 0.30})
          J.agregarNotificacion("+" .. recompensa .. " gemas", J.robin.x, J.robin.y - 25, {0.30, 0.90, 0.95})
          local stats = Guardado.get("estadisticas")
          stats.jefesDerrotados = stats.jefesDerrotados + 1
          Guardado.guardar()
          local total = Guardado.get("gemas") or 0
          J.agregarNotificacion("Total: " .. total .. " gemas", J.robin.x, J.robin.y - 5, {0.85, 0.85, 0.90})
        end
      end

      if J.salaActual.tipo == "jefe" or J.salaIndice == #J.salas then
        local rx, ry = J.salaWorldPos(J.salaActual)
        J.salaActual.portalSalida = { x = rx + J.RW / 2, y = ry + J.RH / 2, timer = 0 }
      end
    end
  end

  -- Portal
  if J.salaActual.portalSalida then
    local p = J.salaActual.portalSalida
    p.timer = p.timer + dt
    local dx, dy = J.robin.x - p.x, J.robin.y - p.y
    if dx*dx + dy*dy < 30*30 then
      if sonidos.portal_entrar then sonidos.portal_entrar:stop() sonidos.portal_entrar:play() end
      Estados.cambiar("carga", J.nivel + 1)
      return
    end
  end

  J.comprobarTransicion()

  J.puedeInteractuar = false
  if J.salaActual.joy then
    local cerca = J.salaActual.joy:cerca(J.robin)
    J.puedeInteractuar = cerca and not J.dialogoJoy
    J.salaActual.joy.resaltado = cerca
  end
end

-- ============================================================
-- ACTUALIZAR PANTALLA DE MUERTE
-- ============================================================
function J.actualizarMuerte(dt)
  local m = J.muerte
  m.timer = m.timer + dt
  m.rojoPulso = m.rojoPulso + dt

  if m.fase == "mensaje" then
    if m.timer > 2.0 then m.puedeAvanzar = true end
  elseif m.fase == "lapida" then
    if not m.lapidaCayo then
      m.lapidaVY = m.lapidaVY + 1200 * dt
      m.lapidaY = m.lapidaY + m.lapidaVY * dt
      if m.lapidaY >= 0 then
        m.lapidaY = 0
        m.lapidaVY = 0
        m.lapidaCayo = true
        m.shakeTimer = 0.35
        m.shakeMag = 8
        for i = 1, 20 do
          local ang = (i / 20) * math.pi * 2
          local vel = 40 + math.random() * 60
          table.insert(m.particulas, {
            x = 320, y = 240,
            vx = math.cos(ang) * vel, vy = math.sin(ang) * vel - 30,
            vida = 0.8 + math.random() * 0.4,
            radio = 1.5 + math.random() * 2,
          })
        end
      end
    end
    if m.shakeTimer > 0 then m.shakeTimer = m.shakeTimer - dt end
    local i = 1
    while i <= #m.particulas do
      local p = m.particulas[i]
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.vy = p.vy + 300 * dt
      p.vida = p.vida - dt
      if p.vida <= 0 then table.remove(m.particulas, i) else i = i + 1 end
    end
    if m.lapidaCayo and m.timer > 4.5 then m.puedeAvanzar = true
    else m.puedeAvanzar = false end
  end
end

return J