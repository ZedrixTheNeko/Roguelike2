local Escalador = require("src.utils.escalador")
local Estados = require("src.sistemas.estados")
local sonidos = require("src.datos.sonidos")
local Config = require("src.datos.config")
local Guardado = require("src.datos.guardado")
local Consola = require("src.utils.consola")
local Shaders = require("src.utils.shaders")

local usarTouch = false

function love.load()
  Consola.instalar()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(0, 0, 0)
  Escalador.inicializar()
  Config.cargar()
  Guardado.cargar()
  local okSh, errSh = pcall(Shaders.inicializar)
  if not okSh then print("[SHADER] error al inicializar: " .. tostring(errSh)) end
  Estados.inicializar()
  sonidos.cargar()
  Estados.cambiar("intro")
end

function love.update(dt)
  Estados.actualizar(dt)
  pcall(Shaders.actualizar, dt)
  Guardado.actualizar(dt)
  Consola.actualizar(dt)
end

function love.draw()
  Escalador.iniciar()
  Estados.dibujar()
  Escalador.terminar()
  if Config.get("debugConsola") then
    Consola.dibujar(love.graphics.getWidth(), love.graphics.getHeight())
  end
end

function love.resize(w, h) Escalador.recalcular(w, h) end

function love.touchpressed(id, x, y)
  usarTouch = true
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.touchpressed(id, vx, vy)
end

function love.touchmoved(id, x, y)
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.touchmoved(id, vx, vy)
end

function love.touchreleased(id, x, y)
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.touchreleased(id, vx, vy)
end

function love.mousepressed(x, y, b)
  if usarTouch then return end
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.mousepressed(vx, vy, b)
end

function love.mousereleased(x, y, b)
  if usarTouch then return end
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.mousereleased(vx, vy, b)
end

function love.mousemoved(x, y)
  if usarTouch then return end
  local vx, vy = Escalador.aVirtual(x, y)
  Estados.mousemoved(vx, vy)
end

function love.keypressed(key) Estados.keypressed(key) end
function love.keyreleased(key) Estados.keyreleased(key) end
function love.textinput(t) Estados.textinput(t) end
function love.quit() Guardado.guardar() end