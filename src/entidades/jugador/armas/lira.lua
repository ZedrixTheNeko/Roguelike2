-- Lira de cuerdas lunares (Lyra)

return function(p, arcoX, arcoY, arcoAng, tension)
  local bob = math.sin(p.animTimer * 2.5) * 1

  love.graphics.push()
  love.graphics.translate(arcoX + 2, arcoY - 2 + bob)
  love.graphics.rotate(arcoAng * 0.5)

  -- Marco de madera
  love.graphics.setColor(0.45, 0.25, 0.15)
  love.graphics.polygon("line",
    -8, -6,
    -8, 8,
    0, 12,
    8, 8,
    8, -6)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line",
    -8, -6,
    -8, 8,
    0, 12,
    8, 8,
    8, -6)
  love.graphics.setLineWidth(1)

  -- Barra superior curva
  love.graphics.setColor(0.55, 0.35, 0.20)
  love.graphics.arc("line", "open", 0, -6, 8, math.pi, math.pi * 2)

  -- Cuerdas (5 lineas verticales)
  for i = 1, 5 do
    local x = -6 + (i - 1) * 3
    love.graphics.setColor(0.85, 0.85, 0.95, 0.85)
    love.graphics.line(x, -6, x, 8 - math.abs(x) * 0.3)
  end

  -- Cuerpo inferior (donde vibran)
  love.graphics.setColor(0.40, 0.20, 0.12)
  love.graphics.ellipse("fill", 0, 9, 6, 3)

  -- Detalles lunares decorativos
  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 3)
  love.graphics.setColor(0.85, 0.70, 1.0, 0.55 + pulso * 0.30)
  love.graphics.circle("fill", 0, -8, 2)

  love.graphics.setColor(1, 0.90, 1.0, 0.85)
  love.graphics.circle("fill", 0, -8, 1)

  -- Aura purpura alrededor de la lira
  love.graphics.setBlendMode("add")
  love.graphics.setColor(0.65, 0.45, 1.0, 0.15 + pulso * 0.10)
  love.graphics.circle("fill", 0, 0, 14)
  love.graphics.setBlendMode("alpha")

  -- Notas musicales flotando
  for i = 1, 3 do
    local ang = p.animTimer * 2 + i * 2.1
    local rx = math.cos(ang) * 10
    local ry = -10 - math.abs(math.sin(ang * 2)) * 6
    love.graphics.setColor(0.85, 0.70, 1.0, 0.6 - math.abs(math.sin(ang)) * 0.4)
    love.graphics.circle("fill", rx, ry, 1.2)
  end

  love.graphics.pop()
end