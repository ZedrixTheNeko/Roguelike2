-- Martillo sagrado de Thorin

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  -- Mango
  love.graphics.setColor(0.45, 0.30, 0.18)
  love.graphics.rectangle("fill", -2, -1.3, 17, 2.6)

  -- Cabeza del martillo
  love.graphics.setColor(0.60, 0.60, 0.68)
  love.graphics.rectangle("fill", 13, -6, 9, 12, 1.5)

  -- Brillo superior
  love.graphics.setColor(0.82, 0.82, 0.90)
  love.graphics.rectangle("fill", 13, -6, 9, 3, 1.5)

  -- Detalle dorado
  love.graphics.setColor(0.95, 0.80, 0.30)
  love.graphics.rectangle("fill", 15, -1, 5, 2)

  -- Aura
  love.graphics.setColor(1, 0.95, 0.60, 0.35)
  love.graphics.circle("fill", 17.5, 0, 9)

  love.graphics.pop()

  -- Escudo en el brazo opuesto
  local escX = p.x - p.ultimaDirX * 6 + p.ultimaDirY * 6
  local escY = p.y - p.ultimaDirY * 6 - p.ultimaDirX * 6 + 2
  love.graphics.setColor(0.70, 0.55, 0.20)
  love.graphics.circle("fill", escX, escY, 5.5)
  love.graphics.setColor(0.95, 0.85, 0.40)
  love.graphics.circle("line", escX, escY, 5.5)
end