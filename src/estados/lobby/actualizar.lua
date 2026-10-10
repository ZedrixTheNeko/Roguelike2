local L          = require("src.estados.lobby.estado")
local Estados    = require("src.sistemas.estados")
local constantes = require("src.constantes")

local t = constantes.TILE

local function actualizarParticulasCambio(lista, dt)
  local i = 1
  while i <= #lista do
    local p = lista[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 60 * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then
      table.remove(lista, i)
    else
      i = i + 1
    end
  end
end

function L.actualizar(dt)
  if L.fxActualizar then L.fxSeguro(L.fxActualizar, dt) end
  L.tGlobal = L.tGlobal + dt
  L.tiempoEstado = L.tiempoEstado + dt

  -- Scroll del selector
  if L.estado == "seleccion" then
    require("src.estados.lobby.selector").actualizarSelector(dt)
  end

  -- ============================================================
  -- TRANSICION DE SALIDA
  -- ============================================================
  if L.saliendo then
    L.timerSalida = L.timerSalida + dt
    L.fadeAlpha = math.min(1, L.timerSalida / L.duracionSalida)

    if L.timerSalida >= L.duracionSalida then
      L.saliendo = false
      L.timerSalida = 0
      L.fadeAlpha = 0

      local destino = L.destinoSalida or "menu"
      L.destinoSalida = nil

      if destino == "juego" then
        Estados.cambiar("juego", 1, true)
      else
        Estados.cambiar(destino)
      end
      return
    end
    return
  end

  -- ============================================================
  -- ANIMACION DE CAMBIO DE PERSONAJE
  -- ============================================================
  if L.cambioPersonaje.activo then
    local cp = L.cambioPersonaje
    cp.timer = cp.timer + dt

    if cp.fase == "desintegrando" then
      if math.random() < 0.85 then
        table.insert(cp.particulasViejas,
          L.crearParticulaCambio(L.robin.x, L.robin.y, "viejo"))
      end
      if math.random() < 0.85 then
        table.insert(cp.particulasViejas,
          L.crearParticulaCambio(L.robin.x, L.robin.y, "viejo"))
      end
      if cp.timer >= 0.7 then
        cp.fase = "esperando"
        cp.timer = 0
      end

    elseif cp.fase == "esperando" then
      if cp.timer >= 0.3 then
        cp.fase = "apareciendo"
        cp.timer = 0
      end

    elseif cp.fase == "apareciendo" then
      if math.random() < 0.9 then
        table.insert(cp.particulasNuevas,
          L.crearParticulaCambio(L.capsulaX, L.capsulaY - 8, "nuevo"))
      end
      if math.random() < 0.9 then
        table.insert(cp.particulasNuevas,
          L.crearParticulaCambio(L.capsulaX, L.capsulaY - 8, "nuevo"))
      end

      if cp.timer >= 0.4 and not cp.movido then
        cp.movido = true
        L.robin.x = L.capsulaX
        L.robin.y = L.capsulaY + 14
        if cp.personajeNuevo then
          local Personajes = require("src.datos.personajes")
          Personajes.actual = cp.personajeNuevo
          L.robin:aplicarPersonaje()
          L.robin:resetearVida()
        end
      end

      if cp.timer >= 1.0 then
        cp.activo = false
        cp.fase = "desintegrando"
        cp.timer = 0
        cp.movido = false
        cp.personajeNuevo = nil
      end
    end

    actualizarParticulasCambio(cp.particulasViejas, dt)
    actualizarParticulasCambio(cp.particulasNuevas, dt)

    local Z = L.zoom
    local anchoVis = constantes.ANCHO_VIRTUAL / Z
    local altoVis  = constantes.ALTO_VIRTUAL  / Z
    local objetivoX = L.robin.x - anchoVis / 2
    local objetivoY = L.robin.y - altoVis  / 2
    local factor = math.min(1, dt * 8)
    L.camX = L.camX + (objetivoX - L.camX) * factor
    L.camY = L.camY + (objetivoY - L.camY) * factor
    return
  end

  -- ============================================================
  -- SI ESTAMOS EN SELECCION, NO PROCESAR MOVIMIENTO
  -- ============================================================
  if L.estado == "seleccion" then return end

  -- Toques decorativos
  local it2 = 1
  while it2 <= #L.toques do
    local tg = L.toques[it2]
    tg.vida = tg.vida - dt
    tg.radio = tg.radio + 100 * dt
    if tg.vida <= 0 then
      table.remove(L.toques, it2)
    else
      it2 = it2 + 1
    end
  end

  -- ============================================================
  -- PARTICULAS
  -- ============================================================
  L.timerMagica = L.timerMagica - dt
  if L.timerMagica <= 0 then
    L.timerMagica = 0.4 + math.random() * 0.5
    if #L.particulasMagicas < L.MAX_LUCIERNAGAS then
      table.insert(L.particulasMagicas, L.crearParticulaMagica())
    end
  end

  local im = 1
  while im <= #L.particulasMagicas do
    local p = L.particulasMagicas[im]
    p.x = p.x + p.vx * dt + math.sin(L.tGlobal * 1.6 + p.fase) * 10 * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 or p.y < -20 then
      table.remove(L.particulasMagicas, im)
    else
      im = im + 1
    end
  end

  if math.random() < 0.8 and #L.particulasAmbiente < L.MAX_AMBIENTE then
    local p = L.crearParticulaAmbiente()
    p.maxVida = p.vida
    table.insert(L.particulasAmbiente, p)
  end
  local j = 1
  while j <= #L.particulasAmbiente do
    local p = L.particulasAmbiente[j]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then
      table.remove(L.particulasAmbiente, j)
    else
      j = j + 1
    end
  end

  L.timerRuna = L.timerRuna - dt
  if L.timerRuna <= 0 then
    L.timerRuna = 1.2 + math.random() * 1.6
    if #L.runas < L.MAX_RUNAS then
      table.insert(L.runas, L.crearRuna())
    end
  end

  local iru = 1
  while iru <= #L.runas do
    local r = L.runas[iru]
    r.vida = r.vida + dt
    r.fase = r.fase + dt * r.velocidadPulso
    if r.boost and r.boost > 0 then
      r.boost = math.max(0, r.boost - dt * 2.5)
    end
    if r.vida >= r.maxVida then
      table.remove(L.runas, iru)
    else
      iru = iru + 1
    end
  end

  if math.random() < 0.4 and #L.particulasPortal < 20 then
    table.insert(L.particulasPortal, {
      x = L.portalX + (math.random() - 0.5) * 30,
      y = L.portalY + 6,
      vy = -20 - math.random() * 20,
      vida = 1.2,
      radio = 1 + math.random() * 1.8,
    })
  end
  local i = 1
  while i <= #L.particulasPortal do
    local p = L.particulasPortal[i]
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then table.remove(L.particulasPortal, i) else i = i + 1 end
  end

  -- ============================================================
  -- MOVIMIENTO + CAMARA
  -- ============================================================
  if L.estado == "explorando" then
    if L.joyMover.activo then
      L.robin:actualizar(dt,
        L.joyMover.dx * L.joyMover.magnitud,
        L.joyMover.dy * L.joyMover.magnitud,
        L.mapa)
    else
      L.robin:actualizar(dt, 0, 0, L.mapa)
    end

    -- Deteccion de salida por distancia
    local dxP = L.robin.x - L.puertaSalidaX
    local dyP = L.robin.y - L.puertaSalidaY
    if dxP * dxP + dyP * dyP < 32 * 32 then
      L.saliendo = true
      L.timerSalida = 0
      L.destinoSalida = "menu"
      return
    end

    L.interactuableCercano = nil
    local mejorD = 999999
    for _, it in ipairs(L.interactuables) do
      local dx = L.robin.x - it.x
      local dy = L.robin.y - it.y
      local d = dx * dx + dy * dy
      if d < it.radio * it.radio and d < mejorD then
        mejorD = d
        L.interactuableCercano = it
      end
    end

    if L.interactuableCercano then
      local texto = "Hablar"
      local tipo = L.interactuableCercano.tipo
      if tipo == "portal" then texto = "Entrar"
      elseif tipo:match("^pilar_") then texto = "Examinar"
      elseif tipo == "joy" then texto = "Hablar"
      elseif tipo == "soul_master" then texto = "Mejorar"
      elseif tipo == "libro" then texto = "Leer"
      elseif tipo == "computadora" then texto = "Usar"
      elseif tipo == "capsula" then texto = "Examinar" end

      L.botonInteractuar.texto = texto
      L.botonInteractuar.oculto = false
      L.botonInteractuar.x = constantes.ANCHO_VIRTUAL / 2 - 90
      L.botonInteractuar.y = 60
    else
      L.botonInteractuar.oculto = true
    end

    local Z = L.zoom
    local anchoVis = constantes.ANCHO_VIRTUAL / Z
    local altoVis  = constantes.ALTO_VIRTUAL  / Z

    local objetivoX = L.robin.x - anchoVis / 2 + (L.fxLookX or 0)
    local objetivoY = L.robin.y - altoVis  / 2 + (L.fxLookY or 0)

    local factor = math.min(1, dt * 8)
    L.camX = L.camX + (objetivoX - L.camX) * factor
    L.camY = L.camY + (objetivoY - L.camY) * factor

    local maxX = L.anchoMundo - anchoVis
    local maxY = L.altoMundo - altoVis
    if maxX < 0 then
      L.camX = L.anchoMundo / 2 - anchoVis / 2
    else
      L.camX = math.max(0, math.min(L.camX, maxX))
    end
    if maxY < 0 then
      L.camY = L.altoMundo / 2 - altoVis / 2
    else
      L.camY = math.max(0, math.min(L.camY, maxY))
    end
  end
end

return L