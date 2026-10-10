local Autoapuntado = {}

-- Cono mucho mas amplio para que sea util
local ANGULO_CONO = math.rad(120)
local RANGO = 200

function Autoapuntado.calcular(x, y, dirBaseX, dirBaseY, enemigos)
  local mejor, mejorDist = nil, RANGO * RANGO
  local anguloBase = math.atan2(dirBaseY, dirBaseX)

  for _, e in ipairs(enemigos) do
    if e.vivo then
      local dx = e.x - x
      local dy = e.y - y
      local d2 = dx * dx + dy * dy
      if d2 <= mejorDist then
        local angE = math.atan2(dy, dx)
        local dif = math.abs(((angE - anguloBase + math.pi) % (math.pi * 2)) - math.pi)
        if dif <= ANGULO_CONO / 2 then
          mejor = e
          mejorDist = d2
        end
      end
    end
  end

  if mejor then
    local dx = mejor.x - x
    local dy = mejor.y - y
    local m = math.sqrt(dx * dx + dy * dy)
    return dx / m, dy / m
  end
  return dirBaseX, dirBaseY
end

return Autoapuntado