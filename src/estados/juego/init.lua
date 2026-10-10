local J = require("src.estados.juego.estado")

require("src.estados.juego.nivel")
require("src.estados.juego.combate")
require("src.estados.juego.habilidades")
require("src.estados.juego.nuevos_heroes")
require("src.estados.juego.iluminacion")
require("src.estados.juego.update")
require("src.estados.juego.dibujo")
require("src.estados.juego.muerte_ui")
require("src.estados.juego.input")

return {
  entrar = J.entrar,
  actualizar = J.actualizar,
  dibujar = J.dibujar,
  touchpressed = J.touchpressed,
  touchmoved = J.touchmoved,
  touchreleased = J.touchreleased,
  keypressed = J.keypressed,
  mousepressed = function(x, y, b) J.touchpressed(-1, x, y) end,
  mousereleased = function(x, y, b) J.touchreleased(-1, x, y) end,
}