-- Grimorio de Merlin
-- (El grimorio no va en la mano, flota al lado del jugador)

return function(p, arcoX, arcoY, arcoAng, tension)
  local bob = math.sin(p.animTimer * 3) * 1

  love.graphics.setColor(0.40, 0.30, 0.55)
  love.graphics.rectangle("fill", p.x + 7, p.y - 6 + bob, 8, 10, 1)

  love.graphics.setColor(0.85, 0.80, 0.55)
  love.graphics.rectangle("fill", p.x + 8, p.y - 5 + bob, 6, 2)

  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 4)
  love.graphics.setColor(0.70, 0.55, 1.0, 0.25 + pulso * 0.25)
  love.graphics.circle("line", p.x + 11, p.y - 1 + bob, 8)

  love.graphics.setColor(0.75, 0.65, 0.95, 0.7)
  love.graphics.rectangle("line", p.x + 7, p.y - 6 + bob, 8, 10, 1)
end