local constantes = require("src.constantes")
local Estados    = require("src.sistemas.estados")
local Red        = require("src.red")

local MP = {}

local AZUL_BRILLO  = {0.55, 0.85, 1.00}
local DORADO       = {1.00, 0.80, 0.30}
local ROJO         = {1.00, 0.55, 0.55}
local VERDE        = {0.55, 1.00, 0.65}

local W = constantes.ANCHO_VIRTUAL
local H = constantes.ALTO_VIRTUAL

local estado = "menu"
local inputActivo = nil
local inputNombre = ""
local inputIp = ""

local indiceSeleccionado = 1
local usandoTeclado = false
local elementos = {}

local campoNombre = { x = 0, y = 0, w = 0, h = 0 }
local campoIp = { x = 0, y = 0, w = 0, h = 0 }

local btnCrear = { x = 0, y = 0, w = 0, h = 0 }
local btnUnirse = { x = 0, y = 0, w = 0, h = 0 }
local btnVolver = { x = 0, y = 0, w = 0, h = 0 }
local btnEmpezar = { x = 0, y = 0, w = 0, h = 0 }
local btnCancelar = { x = 0, y = 0, w = 0, h = 0 }

local mensajeEstado = nil
local tiempoEstado = 0

local function dentro(x, y, b)
  return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

local function layout()
  local cx = W / 2
  local bw = 220
  local bh = 28
  local y0 = 125

  campoNombre.x, campoNombre.y = cx - 110, 108
  campoNombre.w, campoNombre.h = 220, 22

  btnCrear.x, btnCrear.y = cx - bw / 2, y0
  btnCrear.w, btnCrear.h = bw, bh

  btnUnirse.x, btnUnirse.y = cx - bw / 2, y0 + bh + 8
  btnUnirse.w, btnUnirse.h = bw, bh

  btnVolver.x, btnVolver.y = cx - bw / 2, y0 + (bh + 8) * 2
  btnVolver.w, btnVolver.h = bw, bh

  campoIp.x, campoIp.y = cx - 110, H / 2 - 35
  campoIp.w, campoIp.h = 220, 22

  btnEmpezar.x, btnEmpezar.y = cx - bw / 2, H - 65
  btnEmpezar.w, btnEmpezar.h = bw, bh

  btnCancelar.x, btnCancelar.y = cx - bw / 2, H - 28
  btnCancelar.w, btnCancelar.h = bw, 20
end

local function recalcularElementos()
  elementos = {}
  if estado == "menu" then
    table.insert(elementos, { tipo = "campo", ref = campoNombre, id = "nombre" })
    table.insert(elementos, { tipo = "boton", ref = btnCrear, accion = "crear" })
    table.insert(elementos, { tipo = "boton", ref = btnUnirse, accion = "unirse" })
    table.insert(elementos, { tipo = "boton", ref = btnVolver, accion = "volver" })
  elseif estado == "host_esperando" then
    if Red.peerIp then
      table.insert(elementos, { tipo = "boton", ref = btnEmpezar, accion = "empezar" })
    end
    table.insert(elementos, { tipo = "boton", ref = btnCancelar, accion = "cancelar" })
  elseif estado == "cliente_escribiendo_ip" then
    table.insert(elementos, { tipo = "campo", ref = campoIp, id = "ip" })
    table.insert(elementos, { tipo = "boton", ref = btnEmpezar, accion = "conectar" })
    table.insert(elementos, { tipo = "boton", ref = btnCancelar, accion = "cancelar" })
  elseif estado == "cliente_conectando" then
    table.insert(elementos, { tipo = "boton", ref = btnCancelar, accion = "cancelar" })
  end
  if indiceSeleccionado > #elementos then indiceSeleccionado = 1 end
  if indiceSeleccionado < 1 then indiceSeleccionado = #elementos end
end

local function log(msg)
  if Red.logs then
    table.insert(Red.logs, msg)
    if #Red.logs > 6 then table.remove(Red.logs, 1) end
  end
  print("[MP] " .. msg)
end

local function accionCrear()
  local nombre = inputNombre
  if #nombre == 0 then nombre = "Host" end
  if Red.iniciarHost(nombre) then
    estado = "host_esperando"
    indiceSeleccionado = 1
    recalcularElementos()
  else
    mensajeEstado = "Error al iniciar host"
    tiempoEstado = 3
  end
end

local function accionUnirse()
  estado = "cliente_escribiendo_ip"
  inputActivo = "ip"
  indiceSeleccionado = 1
  recalcularElementos()
  love.keyboard.setTextInput(true)
end

local function accionVolver()
  Red.detener()
  Estados.cambiar("menu")
end

local function accionEmpezar()
  -- OJO: NO cerramos Red. El juego lo usara.
  Estados.cambiar("juego", 1, true)
end

local function accionConectar()
  if #inputIp >= 7 then
    local nombre = inputNombre
    if #nombre == 0 then nombre = "Cliente" end
    if Red.conectar(inputIp, nombre) then
      estado = "cliente_conectando"
      inputActivo = nil
      love.keyboard.setTextInput(false)
      indiceSeleccionado = 1
      recalcularElementos()
    else
      mensajeEstado = "Error al conectar"
      tiempoEstado = 3
    end
  else
    mensajeEstado = "IP muy corta"
    tiempoEstado = 2
  end
end

local function accionCancelar()
  Red.detener()
  estado = "menu"
  inputActivo = nil
  love.keyboard.setTextInput(false)
  indiceSeleccionado = 1
  recalcularElementos()
end

local function activarElemento()
  local el = elementos[indiceSeleccionado]
  if not el then return end
  if el.tipo == "campo" then
    inputActivo = el.id
    love.keyboard.setTextInput(true)
  elseif el.tipo == "boton" then
    if el.accion == "crear" then accionCrear()
    elseif el.accion == "unirse" then accionUnirse()
    elseif el.accion == "volver" then accionVolver()
    elseif el.accion == "empezar" then accionEmpezar()
    elseif el.accion == "conectar" then accionConectar()
    elseif el.accion == "cancelar" then accionCancelar()
    end
  end
end

-- ============================================================
-- CICLO DE VIDA
-- ============================================================
function MP.entrar()
  layout()
  estado = "menu"
  inputActivo = nil
  inputNombre = ""
  inputIp = ""
  mensajeEstado = nil
  tiempoEstado = 0
  indiceSeleccionado = 1
  usandoTeclado = false
  Red.detener()
  recalcularElementos()
end

function MP.salir()
  -- NO cerramos Red aqui. El juego lo necesita vivo.
  -- La Red se cierra cuando volvemos al menu principal.
end

function MP.actualizar(dt)
  Red.actualizar(dt)

  if tiempoEstado > 0 then
    tiempoEstado = tiempoEstado - dt
    if tiempoEstado <= 0 then
      mensajeEstado = nil
    end
  end

  if estado == "host_esperando" and Red.peerIp then
    mensajeEstado = "Cliente conectado: " .. Red.peerIp
    tiempoEstado = 999
    local teniaEmpezar = false
    for _, el in ipairs(elementos) do
      if el.accion == "empezar" then teniaEmpezar = true break end
    end
    if not teniaEmpezar then
      indiceSeleccionado = 1
      recalcularElementos()
    end
  end

  if estado == "cliente_conectando" then
    if Red.bufferSnapshots and #Red.bufferSnapshots > 0 then
      log("Snapshot recibido. Iniciando partida.")
      Estados.cambiar("juego", 1, true)
    end
  end
end

-- ============================================================
-- DIBUJO
-- ============================================================
local function dibujarBotonSimple(b, texto, colorBase, seleccionado)
  love.graphics.setColor(0.08, 0.12, 0.24, 0.92)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4)

  love.graphics.setColor(colorBase[1] * 0.4, colorBase[2] * 0.4, colorBase[3] * 0.4)
  love.graphics.rectangle("fill", b.x, b.y + b.h * 0.5, b.w, b.h * 0.5, 4)

  love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], seleccionado and 1 or 0.8)
  love.graphics.setLineWidth(seleccionado and 2 or 1.5)
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4)
  love.graphics.setLineWidth(1)

  if seleccionado and usandoTeclado then
    local t = love.timer.getTime()
    local pulso = 0.5 + 0.5 * math.sin(t * 6)
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.8 + pulso * 0.2)
    love.graphics.polygon("fill",
      b.x - 10, b.y + b.h / 2,
      b.x - 4, b.y + b.h / 2 - 5,
      b.x - 4, b.y + b.h / 2 + 5)
  end

  local f = love.graphics.getFont()
  local tw = f:getWidth(texto)
  local th = f:getHeight()
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.print(texto, b.x + (b.w - tw) / 2 + 1, b.y + (b.h - th) / 2 + 1)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(texto, b.x + (b.w - tw) / 2, b.y + (b.h - th) / 2)
end

local function dibujarCampo(b, texto, activo, placeholder, seleccionado)
  love.graphics.setColor(0.05, 0.08, 0.15)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 3)

  if activo then
    love.graphics.setColor(DORADO)
  elseif seleccionado then
    love.graphics.setColor(1, 1, 0.8)
  else
    love.graphics.setColor(AZUL_BRILLO)
  end
  love.graphics.setLineWidth(activo and 2 or 1.5)
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 3)
  love.graphics.setLineWidth(1)

  if seleccionado and usandoTeclado and not activo then
    local t = love.timer.getTime()
    local pulso = 0.5 + 0.5 * math.sin(t * 6)
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.8 + pulso * 0.2)
    love.graphics.polygon("fill",
      b.x - 10, b.y + b.h / 2,
      b.x - 4, b.y + b.h / 2 - 5,
      b.x - 4, b.y + b.h / 2 + 5)
  end

  local mostrar = texto
  if #mostrar == 0 and placeholder then mostrar = placeholder end
  if activo then mostrar = mostrar .. "_" end

  love.graphics.setColor(1, 1, 1)
  local th = love.graphics.getFont():getHeight()
  love.graphics.print(mostrar, b.x + 8, b.y + (b.h - th) / 2)
end

function MP.dibujar()
  love.graphics.setColor(0.04, 0.06, 0.14)
  love.graphics.rectangle("fill", 0, 0, W, H)

  local f = love.graphics.getFont()
  local cx = W / 2

  love.graphics.setColor(AZUL_BRILLO)
  local titulo = "MULTIJUGADOR LOCAL"
  local twT = f:getWidth(titulo)
  love.graphics.print(titulo, cx - twT / 2, 20)

  love.graphics.setColor(0.5, 0.6, 0.8, 0.7)
  local sub = "WiFi local  -  Host autoritativo"
  local twS = f:getWidth(sub)
  love.graphics.print(sub, cx - twS / 2, 40)

  if estado == "menu" then
    love.graphics.setColor(0.9, 0.95, 1.0)
    love.graphics.print("Tu nombre:", cx - 110, 92)

    local selNombre = false
    local el = elementos[indiceSeleccionado]
    if el and el.tipo == "campo" and el.id == "nombre" then selNombre = true end

    dibujarCampo(campoNombre, inputNombre, inputActivo == "nombre", "Robin", selNombre)

    local selCrear, selUnirse, selVolver = false, false, false
    if el and el.tipo == "boton" then
      if el.accion == "crear" then selCrear = true
      elseif el.accion == "unirse" then selUnirse = true
      elseif el.accion == "volver" then selVolver = true end
    end

    dibujarBotonSimple(btnCrear, "CREAR PARTIDA (HOST)", VERDE, selCrear)
    dibujarBotonSimple(btnUnirse, "UNIRSE A PARTIDA", AZUL_BRILLO, selUnirse)
    dibujarBotonSimple(btnVolver, "VOLVER AL MENU", ROJO, selVolver)

  elseif estado == "host_esperando" then
    love.graphics.setColor(0.9, 0.95, 1.0)
    local msg1 = "Esperando cliente..."
    love.graphics.print(msg1, cx - f:getWidth(msg1) / 2, H / 2 - 60)

    love.graphics.setColor(DORADO)
    local msg2 = "Tu IP: " .. (Red.miIp or "?")
    love.graphics.print(msg2, cx - f:getWidth(msg2) / 2, H / 2 - 35)

    love.graphics.setColor(0.7, 0.8, 0.9)
    local msg3 = "Puerto: " .. Red.PUERTO
    love.graphics.print(msg3, cx - f:getWidth(msg3) / 2, H / 2 - 10)

    love.graphics.setColor(0.6, 0.9, 0.7)
    local msg4 = "El cliente debe escribir esta IP"
    love.graphics.print(msg4, cx - f:getWidth(msg4) / 2, H / 2 + 15)

    if Red.peerIp then
      love.graphics.setColor(VERDE)
      local msg5 = "Cliente conectado: " .. Red.peerIp
      love.graphics.print(msg5, cx - f:getWidth(msg5) / 2, H / 2 + 40)
    end

    for _, el in ipairs(elementos) do
      if el.accion == "empezar" then
        local sel = (elementos[indiceSeleccionado] == el)
        dibujarBotonSimple(btnEmpezar, "EMPEZAR PARTIDA", VERDE, sel)
      elseif el.accion == "cancelar" then
        local sel = (elementos[indiceSeleccionado] == el)
        dibujarBotonSimple(btnCancelar, "Cancelar", ROJO, sel)
      end
    end

  elseif estado == "cliente_escribiendo_ip" then
    love.graphics.setColor(0.9, 0.95, 1.0)
    love.graphics.print("IP del host:", cx - 110, H / 2 - 55)

    local selIp = false
    local el = elementos[indiceSeleccionado]
    if el and el.tipo == "campo" and el.id == "ip" then selIp = true end

    dibujarCampo(campoIp, inputIp, inputActivo == "ip", "192.168.x.x", selIp)

    for _, el2 in ipairs(elementos) do
      if el2.accion == "conectar" then
        local sel = (elementos[indiceSeleccionado] == el2)
        dibujarBotonSimple(btnEmpezar, "CONECTAR", VERDE, sel)
      elseif el2.accion == "cancelar" then
        local sel = (elementos[indiceSeleccionado] == el2)
        dibujarBotonSimple(btnCancelar, "Cancelar", ROJO, sel)
      end
    end

  elseif estado == "cliente_conectando" then
    love.graphics.setColor(0.9, 0.95, 1.0)
    local msg = "Conectando a " .. (Red.peerIp or "?") .. "..."
    love.graphics.print(msg, cx - f:getWidth(msg) / 2, H / 2 - 10)

    love.graphics.setColor(0.6, 0.8, 1.0)
    local msg2 = "Esperando primer snapshot del host..."
    love.graphics.print(msg2, cx - f:getWidth(msg2) / 2, H / 2 + 15)

    for _, el in ipairs(elementos) do
      if el.accion == "cancelar" then
        local sel = (elementos[indiceSeleccionado] == el)
        dibujarBotonSimple(btnCancelar, "Cancelar", ROJO, sel)
      end
    end
  end

  if mensajeEstado then
    love.graphics.setColor(DORADO)
    love.graphics.print(mensajeEstado, 8, 8)
  end

  if Red.logs and #Red.logs > 0 then
    love.graphics.setColor(0.5, 0.7, 0.9, 0.6)
    local ly = H - 15 - #Red.logs * 10
    for _, m in ipairs(Red.logs) do
      love.graphics.print(m, W - f:getWidth(m) * 0.7 - 8, ly, 0, 0.7, 0.7)
      ly = ly + 10
    end
  end
end

-- ============================================================
-- INPUT
-- ============================================================
function MP.touchpressed(id, x, y)
  for i, el in ipairs(elementos) do
    if el.tipo == "boton" and dentro(x, y, el.ref) then
      indiceSeleccionado = i
      usandoTeclado = false
      activarElemento()
      return
    end
  end
  for i, el in ipairs(elementos) do
    if el.tipo == "campo" and dentro(x, y, el.ref) then
      indiceSeleccionado = i
      usandoTeclado = false
      inputActivo = el.id
      love.keyboard.setTextInput(true)
      return
    end
  end
end

function MP.touchreleased(id, x, y) end

function MP.keypressed(key)
  if key == "escape" then
    if inputActivo then
      inputActivo = nil
      love.keyboard.setTextInput(false)
      return
    end
    if estado ~= "menu" then
      accionCancelar()
    else
      Estados.cambiar("menu")
    end
    return
  end

  if inputActivo == "nombre" then
    if key == "return" or key == "kpenter" then
      inputActivo = nil
      love.keyboard.setTextInput(false)
    elseif key == "backspace" then
      inputNombre = inputNombre:sub(1, -2)
    elseif key == "tab" then
      inputActivo = nil
      love.keyboard.setTextInput(false)
      indiceSeleccionado = indiceSeleccionado + 1
      if indiceSeleccionado > #elementos then indiceSeleccionado = 1 end
    end
    return
  end

  if inputActivo == "ip" then
    if key == "return" or key == "kpenter" then
      inputActivo = nil
      love.keyboard.setTextInput(false)
      accionConectar()
    elseif key == "backspace" then
      inputIp = inputIp:sub(1, -2)
    elseif key == "tab" then
      inputActivo = nil
      love.keyboard.setTextInput(false)
      indiceSeleccionado = indiceSeleccionado + 1
      if indiceSeleccionado > #elementos then indiceSeleccionado = 1 end
    end
    return
  end

  if key == "up" or key == "w" then
    usandoTeclado = true
    indiceSeleccionado = indiceSeleccionado - 1
    if indiceSeleccionado < 1 then indiceSeleccionado = #elementos end
  elseif key == "down" or key == "s" then
    usandoTeclado = true
    indiceSeleccionado = indiceSeleccionado + 1
    if indiceSeleccionado > #elementos then indiceSeleccionado = 1 end
  elseif key == "return" or key == "kpenter" or key == "space" then
    activarElemento()
  end
end

function MP.keyreleased(key) end

function MP.textinput(t)
  if inputActivo == "nombre" then
    if #inputNombre < 12 and t:match("^[%w_]+$") then
      inputNombre = inputNombre .. t
    end
  elseif inputActivo == "ip" then
    if t:match("^[%d%.]+$") and #inputIp < 15 then
      inputIp = inputIp .. t
    end
  end
end

function MP.mousepressed(x, y, b) MP.touchpressed(-1, x, y) end
function MP.mousereleased(x, y, b) MP.touchreleased(-1, x, y) end

function MP.mousemoved(x, y)
  for i, el in ipairs(elementos) do
    if el.tipo == "boton" and dentro(x, y, el.ref) then
      indiceSeleccionado = i
      usandoTeclado = false
      return
    end
  end
end

return MP