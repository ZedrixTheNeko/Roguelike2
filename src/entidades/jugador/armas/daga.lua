-- Dagas gemelas de Shadow

return function(p, arcoX, arcoY, arcoAng, tension)
  local est = (p.swingT and p.swingT > 0) and 3 or 0

  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  for lado = -1, 1, 2 do
    love.graphics.push()
    local estLado = est * (lado == (p.swingLado or 1) and 1 or 0)
    love.graphics.translate(estLado, lado * 4)

    -- Aura morada
    love.graphics.setColor(0.65, 0.40, 0.95, 0.30)
    love.graphics.polygon("fill", 0, -2, 13, 0, 0, 2)

    -- Hoja
    love.graphics.setColor(0.90, 0.92, 1.0)
    love.graphics.polygon("fill", 0, -1.4, 11, 0, 0, 1.4)

    -- Mango
    love.graphics.setColor(0.35, 0.22, 0.45)
    love.graphics.rectangle("fill", -3, -1, 3, 2)

    -- Brillo
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.line(1, -0.4, 9, 0)

    love.graphics.pop()
  end

  love.graphics.pop()
end