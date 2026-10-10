local E = require("src.entidades.enemigo.base")

function E:actualizarMurcielago(dt, mapa, objetivo)
  local datos = self.datos
  local velMult = self.velocidadMultiplicador or 1

  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end

  if self:probarAtaqueEspecial(objetivo) then return end

  self.ultimaDirX, self.ultimaDirY = dx / d, dy / d

  -- Wander erratico: cambia el objetivo cada cierto tiempo
  self.wanderTimer = self.wanderTimer - dt
  if self.wanderTimer <= 0 then
    self.wanderTimer = 0.5 + math.random() * 0.5
    self.wanderOffsetX = (math.random() - 0.5) * 60
    self.wanderOffsetY = (math.random() - 0.5) * 60
  end

  -- Altura de vuelo (bob)
  self.zTimer = self.zTimer + dt
  self.z = math.abs(math.sin(self.zTimer * 4)) * 4

  -- Se mueve hacia el objetivo + offset erratico. Atraviesa paredes.
  local targetX = objetivo.x + self.wanderOffsetX
  local targetY = objetivo.y + self.wanderOffsetY
  local tdx = targetX - self.x
  local tdy = targetY - self.y
  local tm = math.sqrt(tdx * tdx + tdy * tdy)
  if tm > 0.001 then
    local vel = datos.velocidad * velMult
    self.x = self.x + (tdx / tm) * vel * dt
    self.y = self.y + (tdy / tm) * vel * dt
  end
end

return E