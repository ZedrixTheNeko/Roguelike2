-- Arco de Robin

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  love.graphics.setColor(0.55, 0.40, 0.25)
  love.graphics.setLineWidth(2)
  love.graphics.arc("line", "open", 0, 0, 9, -math.pi / 2.2, math.pi / 2.2)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.70, 0.55, 0.35, 0.7)
  love.graphics.arc("line", "open", 0, 0, 7, -math.pi / 2.4, math.pi / 2.4)

  love.graphics.setColor(0.90, 0.90, 0.85)
  local cuerdaOffset = tension * 3
  love.graphics.line(3, -8, 3 - cuerdaOffset, 0, 3, 8)

  love.graphics.setColor(0.65, 0.45, 0.20)
  love.graphics.rectangle("fill", -1, -0.7, 8, 1.5)

  love.graphics.setColor(0.92, 0.92, 0.95)
  love.graphics.polygon("fill", 7, -2, 10, 0, 7, 2)

  love.graphics.pop()
end