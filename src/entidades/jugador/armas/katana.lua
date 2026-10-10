-- Katana de Shen

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  -- Hoja curva (ligeramente arqueada hacia arriba)
  love.graphics.setColor(0.92, 0.95, 1.00)
  love.graphics.polygon("fill",
    -1, -1.5,
    22, -2.5,
    22, 1.0,
    -1, 1.5)

  -- Brillo de la hoja
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.polygon("fill",
    0, -1.0,
    21, -1.8,
    21, -0.5,
    0, 0.8)

  -- Filo brillante inferior
  love.graphics.setColor(0.75, 0.85, 1.0)
  love.graphics.line(0, 1.2, 22, 0.7)

  -- Guarda (tsuba) redonda
  love.graphics.setColor(0.15, 0.12, 0.18)
  love.graphics.circle("fill", -3, 0, 4)
  love.graphics.setColor(0.45, 0.35, 0.25)
  love.graphics.circle("line", -3, 0, 4)

  -- Mango envuelto
  love.graphics.setColor(0.20, 0.10, 0.10)
  love.graphics.rectangle("fill", -14, -1.5, 10, 3, 1)

  -- Detalles del mango (cintas)
  love.graphics.setColor(0.55, 0.30, 0.30)
  for i = 0, 3 do
    love.graphics.rectangle("fill", -13 + i * 3, -1.5, 1.5, 3)
  end

  -- Aura azulada en el filo
  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 5)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.55, 0.80, 1.0, 0.10 + pulso * 0.10)
  love.graphics.polygon("fill",
    -1, -2.5,
    22, -3.5,
    22, 2.0,
    -1, 2.5)
  love.graphics.setBlendMode("alpha")

  love.graphics.pop()
end