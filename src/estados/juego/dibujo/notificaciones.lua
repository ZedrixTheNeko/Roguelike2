local J = require("src.estados.juego.estado")

function J.dibujarNotificaciones()
  local f = love.graphics.getFont()
  for _, n in ipairs(J.notificaciones) do
    -- Alpha con tres tramos bien separados:
    --   fade in:  primeros 0.3s
    --   solido:   tramo medio
    --   fade out: ultimos 0.5s
    local alpha
    if n.vidaMax - n.vida < 0.3 then
      alpha = (n.vidaMax - n.vida) / 0.3
    elseif n.vida < 0.5 then
      alpha = n.vida / 0.5
    else
      alpha = 1
    end
    alpha = math.max(0, math.min(1, alpha))

    -- Sombra
    love.graphics.setColor(0, 0, 0, alpha * 0.6)
    local tw = f:getWidth(n.texto)
    love.graphics.print(n.texto, n.x - tw / 2 + 1, n.y + 1)

    -- Texto
    love.graphics.setColor(n.color[1], n.color[2], n.color[3], alpha)
    love.graphics.print(n.texto, n.x - tw / 2, n.y)
  end
end

return J