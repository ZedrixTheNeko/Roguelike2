-- Espada de Conan

return function(p, arcoX, arcoY, arcoAng, tension)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)

  love.graphics.setColor(0.90, 0.90, 0.95)
  love.graphics.rectangle("fill", 0, -1.5, 18, 3)

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.rectangle("fill", 0, -1.5, 18, 1)

  love.graphics.setColor(0.55, 0.40, 0.25)
  love.graphics.rectangle("fill", -4, -2.5, 5, 5)

  love.graphics.pop()
end