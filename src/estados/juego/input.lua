local J = require("src.estados.juego.estado")
local Estados = require("src.sistemas.estados")

J.esAndroid = love.system.getOS() == "Android"
J.teclasActivas = J.teclasActivas or {}
J.mouseDisparando = false
J.inputTeclado = nil

-- ============================================================
-- FUNCION QUE ACTUALIZA EL INPUT DE TECLADO (llamada desde update)
-- ============================================================
function J.actualizarInputTeclado()
  if J.esAndroid then return end
  if not J.robin then J.inputTeclado = nil return end
  if J.pausado or J.dialogoJoy or J.estadoFinNivel then
    J.inputTeclado = nil
    return
  end

  local dx, dy = 0, 0
  if J.teclasActivas["a"] or J.teclasActivas["left"] then dx = dx - 1 end
  if J.teclasActivas["d"] or J.teclasActivas["right"] then dx = dx + 1 end
  if J.teclasActivas["w"] or J.teclasActivas["up"] then dy = dy - 1 end
  if J.teclasActivas["s"] or J.teclasActivas["down"] then dy = dy + 1 end

  local m = math.sqrt(dx * dx + dy * dy)
  if m > 0 then dx, dy = dx / m, dy / m end

  J.inputTeclado = J.inputTeclado or {}
  J.inputTeclado.mx = dx
  J.inputTeclado.my = dy

  local sx, sy = love.mouse.getPosition()
  local Escalador = require("src.utils.escalador")
  local vx, vy = Escalador.aVirtual(sx, sy)
  local Z = J.zoomActual or 2
  local wx = vx / Z + (J.camXActual or 0)
  local wy = vy / Z + (J.camYActual or 0)

  local adx = wx - J.robin.x
  local ady = wy - J.robin.y
  if math.abs(adx) > 0.1 or math.abs(ady) > 0.1 then
    J.inputTeclado.angle = math.atan2(ady, adx)
  end

  J.inputTeclado.disparando = J.mouseDisparando
end

-- ============================================================
-- TOUCH
-- ============================================================
function J.touchpressed(id, x, y)
  if J.estadoFinNivel == "derrota" then
    local m = J.muerte
    if m.puedeAvanzar then
      if m.fase == "mensaje" then
        m.fase = "lapida"
        m.timer = 0
        m.puedeAvanzar = false
        m.lapidaY = -220
        m.lapidaVY = 0
        m.lapidaCayo = false
      elseif m.fase == "lapida" then
        Estados.cambiar("menu")
      end
    end
    return
  end

  if J.pausado then
    if J.botonReanudar:touchpressed(id, x, y) then return end
    if J.botonAjustesPausa:touchpressed(id, x, y) then return end
    if J.botonMenuPausa:touchpressed(id, x, y) then return end
    if J.botonGuardarSalir:touchpressed(id, x, y) then return end
    return
  end

  if J.dialogoJoy then
    if J.botonCuraSi:touchpressed(id, x, y) then return end
    if J.botonCuraNo:touchpressed(id, x, y) then return end
    return
  end

  if J.botonPausa:touchpressed(id, x, y) then
    J.pausado = true
    return
  end
  if not J.robin.vivo then return end

  if J.puedeInteractuar and J.botonInteractuar:touchpressed(id, x, y) then
    J.dialogoJoy = true
    return
  end

  for i, b in ipairs(J.botonesHabilidad or {}) do
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

  if J.joyMover:touchpressed(id, x, y) then return end
  if J.joyApuntar:touchpressed(id, x, y) then return end
end

function J.touchmoved(id, x, y)
  if J.estadoFinNivel == "derrota" then return end
  if J.pausado or J.dialogoJoy then return end
  J.joyMover:touchmoved(id, x, y)
  J.joyApuntar:touchmoved(id, x, y)
end

function J.touchreleased(id, x, y)
  if J.estadoFinNivel == "derrota" then return end

  if J.pausado then
    J.botonReanudar:touchreleased(id, x, y)
    J.botonAjustesPausa:touchreleased(id, x, y)
    J.botonMenuPausa:touchreleased(id, x, y)
    J.botonGuardarSalir:touchreleased(id, x, y)
    return
  end

  if J.dialogoJoy then
    J.botonCuraSi:touchreleased(id, x, y)
    J.botonCuraNo:touchreleased(id, x, y)
    return
  end

  J.botonInteractuar:touchreleased(id, x, y)
  J.botonPausa:touchreleased(id, x, y)
  for _, b in ipairs(J.botonesHabilidad or {}) do
    b:touchreleased(id, x, y)
  end
  if J.botonRodar then J.botonRodar:touchreleased(id, x, y) end
  if J.botonFrasco then J.botonFrasco:touchreleased(id, x, y) end
  J.joyMover:touchreleased(id, x, y)
  J.joyApuntar:touchreleased(id, x, y)
end

-- ============================================================
-- MOUSE (PC)
-- ============================================================
function J.mousepressed(x, y, b)
  if b == 1 then J.mouseDisparando = true end
end

function J.mousereleased(x, y, b)
  if b == 1 then J.mouseDisparando = false end
end

function J.mousemoved(x, y) end

-- ============================================================
-- TECLADO (PC)
-- ============================================================
function J.keypressed(key)
  if J.estadoFinNivel == "derrota" then return end

  if not J.pausado and not J.estadoFinNivel and J.robin then
    if key == "space" or key == "lshift" then
      J.accionRodar()
      return
    end
    if key == "f" then
      J.accionFrasco()
      return
    end
    if key == "e" then
      if J.puedeInteractuar then
        J.dialogoJoy = true
        return
      end
    end
    if key == "1" or key == "2" or key == "3" then
      J.intentarHabilidad(tonumber(key))
      return
    end
  end

  J.teclasActivas[key] = true

  if key == "escape" then
    if J.estadoFinNivel == "derrota" then return end
    if J.pausado then
      J.pausado = false
    else
      J.pausado = true
    end
  end
end

function J.keyreleased(key)
  J.teclasActivas[key] = false
end

return J