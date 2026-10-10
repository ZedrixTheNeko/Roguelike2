-- Rifle de plasma de Rex

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  -- Retroceso al disparar
  local retro = (p.cooldownDisparo > 0) and -1.5 or 0

  -- Cuerpo
  love.graphics.setColor(0.18, 0.22, 0.28)
  love.graphics.rectangle("fill", -3 + retro, -2.2, 16, 4.4, 1)

  -- Brillo superior
  love.graphics.setColor(0.30, 0.36, 0.44)
  love.graphics.rectangle("fill", -3 + retro, -2.2, 16, 1.5, 1)

  -- Linea de energia cian
  love.graphics.setColor(0.25, 0.95, 1.0, 0.9)
  love.graphics.rectangle("fill", 1 + retro, -0.4, 9, 1)

  -- Cañon
  love.graphics.setColor(0.12, 0.14, 0.18)
  love.graphics.rectangle("fill", 13 + retro, -1.2, 5, 2.4)

  -- Fogonazo
  if p.cooldownDisparo > (p.cooldownDisparoMax or 0.11) * 0.55 then
    love.graphics.setColor(1.0, 0.90, 0.40, 0.9)
    love.graphics.circle("fill", 20, 0, 3.2)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", 20, 0, 1.5)
  end

  -- Sobrecarga activa
  if p.sobrecargaT and p.sobrecargaT > 0 then
    love.graphics.setColor(1.0, 0.4, 0.1, 0.5 + 0.3 * math.sin(p.animTimer * 20))
    love.graphics.circle("line", 6, 0, 8)
  end

  love.graphics.pop()
end