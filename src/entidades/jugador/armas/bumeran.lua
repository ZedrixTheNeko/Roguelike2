-- Bumeran de Kael

return function(p, arcoX, arcoY, arcoAng, tension)
  local rotMano = p.animTimer * 1.5

  love.graphics.push()
  love.graphics.translate(arcoX + 4, arcoY)
  love.graphics.rotate(arcoAng + rotMano)

  -- Brazo 1
  love.graphics.setColor(0.20, 0.15, 0.12)
  love.graphics.polygon("fill",
    0, -1.5,
    -9, -8,
    -8, -3,
    0, 1.5)

  -- Brazo 2
  love.graphics.polygon("fill",
    0, -1.5,
    -9, 8,
    -8, 3,
    0, 1.5)

  -- Brillo interior
  love.graphics.setColor(0.55, 0.35, 0.20)
  love.graphics.polygon("fill",
    0, -0.5,
    -7, -6,
    -6.5, -3,
    0, 0.7)
  love.graphics.polygon("fill",
    0, -0.5,
    -7, 6,
    -6.5, 3,
    0, 0.7)

  -- Nucleo
  love.graphics.setColor(0.85, 0.55, 0.25)
  love.graphics.circle("fill", 0, 0, 2)

  -- Puntitas doradas
  love.graphics.setColor(1, 0.85, 0.40, 0.9)
  love.graphics.circle("fill", -9, -8, 1.5)
  love.graphics.circle("fill", -9, 8, 1.5)

  love.graphics.pop()
end