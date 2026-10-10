-- Lanza de Odin (Brunilda)

return function(p, arcoX, arcoY, arcoAng, tension)
  local bob = math.sin(p.animTimer * 2) * 0.5

  -- Retroceso cuando esta en cooldown
  local retroceso = 0
  if p.cooldownDisparo > 0 then
    retroceso = (p.cooldownDisparo / (p.cooldownDisparoMax or 0.45)) * 4
  end

  love.graphics.push()
  love.graphics.translate(arcoX - retroceso, arcoY + bob)
  love.graphics.rotate(arcoAng)

  -- Mango de madera oscura
  love.graphics.setColor(0.35, 0.20, 0.10)
  love.graphics.rectangle("fill", -12, -1.2, 26, 2.4, 1)

  -- Detalle dorado
  love.graphics.setColor(0.75, 0.55, 0.20)
  love.graphics.rectangle("fill", -10, -0.6, 4, 1.2)
  love.graphics.rectangle("fill", -3, -0.6, 4, 1.2)
  love.graphics.rectangle("fill", 4, -0.6, 4, 1.2)

  -- Anillo metalico
  love.graphics.setColor(0.85, 0.80, 0.65)
  love.graphics.circle("fill", -12, 0, 2)

  -- Punta de la lanza
  love.graphics.setColor(0.90, 0.90, 0.95)
  love.graphics.polygon("fill",
    14, -3.5,
    22, 0,
    14, 3.5)

  -- Brillo de la hoja
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.polygon("fill",
    15, -1.5,
    20, 0,
    15, 1.5)

  -- Base de la hoja
  love.graphics.setColor(0.55, 0.55, 0.65)
  love.graphics.rectangle("fill", 11, -2.5, 4, 5, 1)

  -- Detalles dorados
  love.graphics.setColor(0.90, 0.70, 0.25)
  love.graphics.rectangle("fill", 11, -2.5, 4, 1)

  -- Aura dorada en la punta
  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 4)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1, 0.85, 0.35, 0.15 + pulso * 0.10)
  love.graphics.circle("fill", 20, 0, 6 + pulso * 2)
  love.graphics.setBlendMode("alpha")

  love.graphics.pop()
end