-- Ballesta de plasma de Nyx-7

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  -- Cuerpo de la ballesta (metalico)
  love.graphics.setColor(0.35, 0.40, 0.50)
  love.graphics.rectangle("fill", -2, -2, 18, 4, 1)

  -- Detalle superior
  love.graphics.setColor(0.55, 0.60, 0.70)
  love.graphics.rectangle("fill", -2, -2, 18, 1)

  -- Guias laterales (los "brazos" de la ballesta)
  love.graphics.setColor(0.40, 0.45, 0.55)
  love.graphics.rectangle("fill", 10, -6, 3, 12, 1)

  -- Puntas con luz cian
  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 5)

  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.55, 0.90, 1.0, 0.30 + pulso * 0.20)
  love.graphics.circle("fill", 11.5, -5, 3)
  love.graphics.circle("fill", 11.5, 5, 3)
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(0.65, 0.95, 1.0)
  love.graphics.circle("fill", 11.5, -5, 1.5)
  love.graphics.circle("fill", 11.5, 5, 1.5)

  -- Mango ergonomico
  love.graphics.setColor(0.25, 0.28, 0.35)
  love.graphics.polygon("fill",
    -2, 2,
    -6, 6,
    -8, 4,
    -4, 0)

  -- Cargador/luz inferior
  love.graphics.setColor(0.20, 0.25, 0.35)
  love.graphics.rectangle("fill", -2, 3, 8, 3, 1)

  love.graphics.setColor(0.55, 0.85, 1.0, 0.5 + pulso * 0.4)
  love.graphics.rectangle("fill", -1, 4, 6, 1)

  -- Cañon principal brillante
  love.graphics.setColor(0.55, 0.85, 1.0, 0.4 + pulso * 0.3)
  love.graphics.rectangle("fill", 16, -1.5, 3, 3)

  love.graphics.setColor(0.85, 0.98, 1.0)
  love.graphics.rectangle("fill", 16, -1.5, 3, 1)

  love.graphics.pop()
end