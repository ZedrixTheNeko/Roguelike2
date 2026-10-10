-- ============================================================
-- ARMAS - Router
-- ============================================================
-- Decide que funcion de dibujo usar segun el tipo de arma del
-- jugador. Cada arma es un modulo que exporta una funcion:
--   function dibujar(p, arcoX, arcoY, arcoAng, tension)

local Armas = {}

-- Cargar todas las armas
Armas.arco             = require("src.entidades.jugador.armas.arco")
Armas.espada           = require("src.entidades.jugador.armas.espada")
Armas.grimorio         = require("src.entidades.jugador.armas.grimorio")
Armas.bumeran          = require("src.entidades.jugador.armas.bumeran")
Armas.lanza            = require("src.entidades.jugador.armas.lanza")
Armas.revolver         = require("src.entidades.jugador.armas.revolver")
Armas.katana           = require("src.entidades.jugador.armas.katana")
Armas.ballesta_plasma  = require("src.entidades.jugador.armas.ballesta_plasma")
Armas.lira             = require("src.entidades.jugador.armas.lira")
Armas.dagas            = require("src.entidades.jugador.armas.dagas")
Armas.martillo         = require("src.entidades.jugador.armas.martillo")
Armas.rifle            = require("src.entidades.jugador.armas.rifle")

function Armas.dibujar(p, arcoX, arcoY, arcoAng, tension)
  local fn = Armas[p.tipoArma]
  if fn then
    fn(p, arcoX, arcoY, arcoAng, tension)
  else
    -- Fallback: barrita gris
    love.graphics.push()
    love.graphics.translate(arcoX, arcoY)
    love.graphics.rotate(arcoAng)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", 0, -1, 12, 2)
    love.graphics.pop()
  end
end

return Armas