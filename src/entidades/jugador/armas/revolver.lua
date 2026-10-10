-- Revolver de Coyote
-- Si el buff dualWield esta activo, dibuja DOS revolveres.

local function dibujarUnRevolver(p, arcoX, arcoY, arcoAng, espejo)
  love.graphics.push()
  love.graphics.translate(arcoX, arcoY)
  love.graphics.rotate(arcoAng)
  if espejo then
    love.graphics.scale(1, -1)  -- espejo vertical
  end

  -- Canon
  love.graphics.setColor(0.25, 0.22, 0.28)
  love.graphics.rectangle("fill", 0, -1.8, 16, 3.6, 1)

  -- Brillo del canon
  love.graphics.setColor(0.55, 0.50, 0.60)
  love.graphics.rectangle("fill", 0, -1.8, 16, 1)

  -- Tambor
  love.graphics.setColor(0.35, 0.30, 0.35)
  love.graphics.circle("fill", -1, 0, 4)

  -- Camaras del tambor
  love.graphics.setColor(0.10, 0.08, 0.12)
  for i = 0, 5 do
    local a = i * math.pi / 3 + p.animTimer * 0.5
    love.graphics.circle("fill", -1 + math.cos(a) * 2, math.sin(a) * 2, 1)
  end

  -- Empunadura de madera
  love.graphics.setColor(0.40, 0.22, 0.12)
  love.graphics.polygon("fill",
    -3, 2,
    -8, 6,
    -10, 5,
    -4, -1)

  -- Detalle dorado
  love.graphics.setColor(0.75, 0.55, 0.20)
  love.graphics.polygon("line",
    -3, 2,
    -8, 6,
    -10, 5,
    -4, -1)

  -- Gatillo
  love.graphics.setColor(0.45, 0.40, 0.45)
  love.graphics.arc("line", "open", -1, 3, 3, 0.2, math.pi - 0.2)

  -- Brillito en la punta
  local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 6)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1, 0.85, 0.40, 0.20 + pulso * 0.20)
  love.graphics.circle("fill", 16, 0, 4 + pulso * 1.5)
  love.graphics.setBlendMode("alpha")

  love.graphics.pop()
end

return function(p, arcoX, arcoY, arcoAng, tension)
  local dualActivo = (p.dualWield or 0) > 0

  if dualActivo then
    -- Dos revolveres: uno arriba, uno abajo
    local perpX = math.cos(arcoAng + math.pi / 2) * 7
    local perpY = math.sin(arcoAng + math.pi / 2) * 7

    dibujarUnRevolver(p, arcoX + perpX, arcoY + perpY, arcoAng, false)
    dibujarUnRevolver(p, arcoX - perpX, arcoY - perpY, arcoAng, true)

    -- Aura dorada sutil alrededor del jugador
    local pulso = 0.5 + 0.5 * math.sin(p.animTimer * 5)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.85, 0.35, 0.08 + pulso * 0.06)
    love.graphics.circle("fill", p.x, p.y, 18 + pulso * 3)
    love.graphics.setBlendMode("alpha")
  else
    -- Un solo revolver
    dibujarUnRevolver(p, arcoX, arcoY, arcoAng, false)
  end
end