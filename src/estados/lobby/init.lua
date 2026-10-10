local L = require("src.estados.lobby.estado")

require("src.estados.lobby.mapa")
require("src.estados.lobby.decoraciones")
require("src.estados.lobby.tienda")
require("src.estados.lobby.mejoras")
require("src.estados.lobby.actualizar")
require("src.estados.lobby.dibujo")
require("src.estados.lobby.fx")
require("src.estados.lobby.selector")
require("src.estados.lobby.input")

return {
  entrar = L.entrar,
  actualizar = L.actualizar,
  dibujar = L.dibujar,
  touchpressed = L.touchpressed,
  touchmoved = L.touchmoved,
  touchreleased = L.touchreleased,
  keypressed = L.keypressed,
  mousepressed = function(x, y, b) L.touchpressed(-1, x, y) end,
  mousereleased = function(x, y, b) L.touchreleased(-1, x, y) end,
}