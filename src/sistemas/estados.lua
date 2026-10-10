local Shaders = require("src.utils.shaders")

local Estados = {}

local registrados = {}
local actual = nil

Estados.nombreActual = nil
Estados.nombreAnterior = nil

function Estados.registrar(nombre, estado)
  registrados[nombre] = estado
end

function Estados.inicializar()
  Estados.registrar("intro",   require("src.estados.intro"))
  Estados.registrar("menu",    require("src.estados.menu"))
  Estados.registrar("ajustes", require("src.estados.ajustes"))
  Estados.registrar("lobby",   require("src.estados.lobby"))
  Estados.registrar("carga",   require("src.estados.carga"))
  Estados.registrar("juego",   require("src.estados.juego"))
  Estados.registrar("beta",    require("src.estados.beta"))
  Estados.registrar("mp_lobby", require("src.estados.mp_lobby"))
end

function Estados.cambiar(nombre, ...)
  if actual and actual.salir then actual.salir() end
  Estados.nombreAnterior = Estados.nombreActual
  Estados.nombreActual = nombre
  actual = registrados[nombre]
  pcall(Shaders.perfilEstado, nombre)
  if actual and actual.entrar then actual.entrar(...) end
end

function Estados.actualizar(dt)
  if actual and actual.actualizar then actual.actualizar(dt) end
end

function Estados.dibujar()
  if actual and actual.dibujar then actual.dibujar() end
end

function Estados.touchpressed(id, x, y)
  if actual and actual.touchpressed then actual.touchpressed(id, x, y) end
end

function Estados.touchmoved(id, x, y)
  if actual and actual.touchmoved then actual.touchmoved(id, x, y) end
end

function Estados.touchreleased(id, x, y)
  if actual and actual.touchreleased then actual.touchreleased(id, x, y) end
end

function Estados.mousepressed(x, y, b)
  if actual and actual.mousepressed then actual.mousepressed(x, y, b) end
end

function Estados.mousereleased(x, y, b)
  if actual and actual.mousereleased then actual.mousereleased(x, y, b) end
end

function Estados.mousemoved(x, y)
  if actual and actual.mousemoved then actual.mousemoved(x, y) end
end

function Estados.keypressed(key)
  if actual and actual.keypressed then actual.keypressed(key) end
end

function Estados.keyreleased(key)
  if actual and actual.keyreleased then actual.keyreleased(key) end
end

function Estados.textinput(t)
  if actual and actual.textinput then actual.textinput(t) end
end

return Estados