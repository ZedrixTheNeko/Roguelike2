-- ============================================================
-- JUGADOR - Dibujo
-- ============================================================
-- Cuerpo, arma rotada (delega al router de armas), orbes, roll, parry.

local Armas = require("src.entidades.jugador.armas.init")

local Dibujo = {}

-- ============================================================
-- DIBUJAR ARMA ROTADA (delega al router de armas)
-- ============================================================

function Dibujo:dibujarArmaRotada()
  local p = self
  local arcoX = p.x + p.ultimaDirX * 6
  local arcoY = p.y + p.ultimaDirY * 6
  local arcoAng = math.atan2(p.ultimaDirY, p.ultimaDirX)

  -- Animacion de swing para armas melee
  local tA = p.tipoArma
  if (tA == "espada" or tA == "dagas" or tA == "martillo"
      or tA == "katana" or tA == "lanza") and p.swingT and p.swingT > 0 then
    local k = 1 - p.swingT / (p.swingDur or 0.2)
    local amp
    if tA == "martillo" then amp = 2.6
    elseif tA == "katana" then amp = 2.2
    elseif tA == "lanza" then amp = 1.4
    else amp = 1.9 end
    arcoAng = arcoAng + (k - 0.5) * amp * (p.swingLado or 1)
  end

  local tension = 0
  if p.cooldownDisparo > 0 then
    tension = (p.cooldownDisparo / (p.cooldownDisparoMax or 0.28)) * 0.4
  end

  Armas.dibujar(p, arcoX, arcoY, arcoAng, tension)
end

-- ============================================================
-- DIBUJAR ORBES (Merlin)
-- ============================================================

function Dibujo:dibujarOrbes()
  if not self.orbsActivos then return end
  for _, o in ipairs(self.orbs) do
    local ang = o.angulo + self.orbsAngulo
    local ox = self.x + math.cos(ang) * o.radioOrbita
    local oy = self.y + math.sin(ang) * o.radioOrbita

    love.graphics.setColor(1, 0.55, 0.15, 0.25)
    love.graphics.circle("fill", ox, oy, o.radioBola + 3)
    love.graphics.setColor(1, 0.45, 0.10)
    love.graphics.circle("fill", ox, oy, o.radioBola)
    love.graphics.setColor(1, 0.90, 0.45)
    love.graphics.circle("fill", ox, oy, o.radioBola * 0.55)
    love.graphics.setColor(1, 1, 0.90, 0.9)
    love.graphics.circle("fill", ox, oy, o.radioBola * 0.25)
  end
end

-- ============================================================
-- DIBUJAR PRINCIPAL
-- ============================================================

function Dibujo:dibujar()
  if not self.vivo then return end

  -- Parpadeo de invulnerabilidad (NO durante roll ni parry, ahi si se ve)
  if self.invulnerable > 0 and not self.rodando and not self.parryActivo
     and math.floor(self.invulnerable * 22) % 2 == 0 then
    return
  end

  local sx, sy = 0, 0
  if self.shakeTimer > 0 then
    sx = (math.random() - 0.5) * self.shakeMag * 2
    sy = (math.random() - 0.5) * self.shakeMag * 2
  end

  local cx, cy = self.x + sx, self.y + sy

  local bob
  if self.caminando then
    bob = math.abs(math.sin(self.animTimer * 10)) * 1.5
  else
    bob = math.sin(self.animTimer * 3) * 0.5
  end

  -- Colores con flash / slow
  local colTunica, colCapa, colPiel, colPelo
  if self.flashTimer > 0 and self.flashColor then
    colTunica = self.flashColor
    colCapa   = self.flashColor
    colPiel   = self.flashColor
    colPelo   = self.flashColor
  elseif self.slowTimer > 0 then
    colTunica = {self.colorTunica[1] * 0.9, self.colorTunica[2] * 0.95, self.colorTunica[3] * 0.5}
    colCapa   = {self.colorCapa[1] * 0.9, self.colorCapa[2] * 0.95, self.colorCapa[3] * 0.5}
    colPiel   = {self.colorPiel[1] * 0.9, self.colorPiel[2] * 0.95, self.colorPiel[3] * 0.7}
    colPelo   = {self.colorPelo[1] * 0.9, self.colorPelo[2] * 0.95, self.colorPelo[3] * 0.5}
  else
    colTunica = self.colorTunica
    colCapa   = self.colorCapa
    colPiel   = self.colorPiel
    colPelo   = self.colorPelo
  end

  local dy = cy - bob

  -- Sombra
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", cx, cy + 9, 6, 2.5)

  -- Animacion de roll (rotacion completa)
  if self.rodando then
    local prog = 1 - math.max(0, self.dashTimer) / 0.30
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(prog * math.pi * 2 * (self.rodarSigno or 1))
    love.graphics.scale(1, 0.85)
    love.graphics.translate(-cx, -cy)
  end

  -- Capa
  love.graphics.setColor(colCapa)
  love.graphics.polygon("fill", cx - 6, dy - 2, cx + 6, dy - 2, cx + 8, dy + 8, cx - 8, dy + 8)

  -- Piernas
  local piernaOffset = self.caminando and math.sin(self.animTimer * 10) * 2 or 0
  love.graphics.setColor({0.20, 0.15, 0.10})
  love.graphics.rectangle("fill", cx - 4, dy + 6, 3, 4 + piernaOffset)
  love.graphics.rectangle("fill", cx + 1, dy + 6, 3, 4 - piernaOffset)

  -- Tunica
  love.graphics.setColor(colTunica)
  love.graphics.polygon("fill", cx - 5, dy - 4, cx + 5, dy - 4, cx + 6, dy + 7, cx - 6, dy + 7)

  -- Detalle central de la tunica
  love.graphics.setColor(
    math.max(0, colTunica[1] - 0.15),
    math.max(0, colTunica[2] - 0.15),
    math.max(0, colTunica[3] - 0.15),
    0.9)
  love.graphics.rectangle("fill", cx - 0.5, dy - 3, 1, 9)

  -- Arma (delegada)
  self:dibujarArmaRotada()

  -- Brazos
  local brazoOffset = self.caminando and math.sin(self.animTimer * 10 + 1.5) * 1.5 or 0
  love.graphics.setColor(colTunica)
  love.graphics.polygon("fill", cx - 7, dy - 3, cx - 5, dy - 3, cx - 6, dy + 3 + brazoOffset)
  love.graphics.polygon("fill", cx + 5, dy - 3, cx + 7, dy - 3, cx + 6, dy + 3 - brazoOffset)

  -- Cabeza
  love.graphics.setColor(colPiel)
  love.graphics.circle("fill", cx, dy - 8, 5)

  -- Pelo
  love.graphics.setColor(colPelo)
  love.graphics.arc("fill", cx, dy - 9, 5, math.pi, math.pi * 2)
  love.graphics.rectangle("fill", cx - 5, dy - 9, 10, 2)

  -- Ojos (siguen direccion)
  local eyeX = self.ultimaDirX * 1.2
  local eyeY = self.ultimaDirY * 0.8
  love.graphics.setColor(0.10, 0.08, 0.12)
  love.graphics.circle("fill", cx - 2 + eyeX, dy - 8 + eyeY, 1)
  love.graphics.circle("fill", cx + 2 + eyeX, dy - 8 + eyeY, 1)

  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.circle("fill", cx - 2 + eyeX, dy - 8.5 + eyeY, 0.4)
  love.graphics.circle("fill", cx + 2 + eyeX, dy - 8.5 + eyeY, 0.4)

  if self.rodando then love.graphics.pop() end

  -- ============================================================
  -- AURAS Y EFECTOS
  -- ============================================================

  -- Aura del escudo
  if self.escudo > 0 then
    local pulso = 0.5 + 0.5 * math.sin(self.animTimer * 3)
    local a = 0.12 + 0.08 * pulso
    if self.flashTimer > 0 and self.flashColor and self.flashColor[3] > 0.9 then
      a = a + 0.25 * (self.flashTimer / 0.20)
    end
    love.graphics.setColor(0.45, 0.85, 1.0, a)
    love.graphics.circle("line", cx, cy, 14)
    love.graphics.setColor(0.45, 0.85, 1.0, a * 0.4)
    love.graphics.circle("line", cx, cy, 15)
  end

  -- Aura de velocidad
  if self.buffVelocidad > 0 then
    local pulso2 = 0.5 + 0.5 * math.sin(self.animTimer * 8)
    love.graphics.setColor(0.40, 0.95, 0.50, 0.15 + pulso2 * 0.15)
    love.graphics.circle("line", cx, cy, 12)
  end

  -- Aura de slow
  if self.slowTimer > 0 then
    local pulso3 = 0.5 + 0.5 * math.sin(self.animTimer * 5)
    love.graphics.setColor(0.55, 0.85, 0.30, 0.20 + pulso3 * 0.15)
    love.graphics.circle("line", cx, cy + 6, 10)
  end

  -- Aura de Sinfonia Belica (Lyra)
  if self.sinfoniaTimer and self.sinfoniaTimer > 0 then
    local pulso4 = 0.5 + 0.5 * math.sin(self.animTimer * 6)
    love.graphics.setColor(0.85, 0.55, 1.0, 0.20 + pulso4 * 0.20)
    love.graphics.circle("line", cx, cy, 16)
    love.graphics.setColor(1, 0.85, 1.0, 0.10 + pulso4 * 0.10)
    love.graphics.circle("line", cx, cy, 18)
  end

  -- Aura de dual wield (Coyote)
  if self.dualWield and self.dualWield > 0 then
    local pulso5 = 0.5 + 0.5 * math.sin(self.animTimer * 5)
    love.graphics.setColor(1, 0.85, 0.35, 0.10 + pulso5 * 0.08)
    love.graphics.circle("line", cx, cy, 17)
  end

  -- Anillo de parry (Sable)
  if self.parryActivo then
    local pulso6 = 0.5 + 0.5 * math.sin(self.animTimer * 25)
    love.graphics.setColor(0.6, 0.9, 1.0, 0.30 + 0.20 * pulso6)
    love.graphics.circle("fill", cx, cy, 20)
    love.graphics.setColor(0.85, 0.97, 1.0, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, 20)
    love.graphics.setLineWidth(1)
  end

  -- Orbes (Merlin)
  self:dibujarOrbes()
end

-- ============================================================
-- DIBUJAR SIN ARMA (para el lobby/preview/selector)
-- ============================================================

function Dibujo:dibujarSinArma(x, y, escala)
  escala = escala or 1
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(escala, escala)

  local bob = math.sin(love.timer.getTime() * 3) * 0.5
  local dy = -bob

  -- Sombra
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", 0, 9, 6, 2.5)

  -- Capa
  love.graphics.setColor(self.colorCapa)
  love.graphics.polygon("fill", -6, dy - 2, 6, dy - 2, 8, dy + 8, -8, dy + 8)

  -- Piernas
  love.graphics.setColor(0.20, 0.15, 0.10)
  love.graphics.rectangle("fill", -4, dy + 6, 3, 4)
  love.graphics.rectangle("fill", 1, dy + 6, 3, 4)

  -- Tunica
  love.graphics.setColor(self.colorTunica)
  love.graphics.polygon("fill", -5, dy - 4, 5, dy - 4, 6, dy + 7, -6, dy + 7)

  -- Detalle central
  love.graphics.setColor(
    math.max(0, self.colorTunica[1] - 0.15),
    math.max(0, self.colorTunica[2] - 0.15),
    math.max(0, self.colorTunica[3] - 0.15),
    0.9)
  love.graphics.rectangle("fill", -0.5, dy - 3, 1, 9)

  -- Cabeza
  love.graphics.setColor(self.colorPiel)
  love.graphics.circle("fill", 0, dy - 8, 5)

  -- Pelo
  love.graphics.setColor(self.colorPelo)
  love.graphics.arc("fill", 0, dy - 9, 5, math.pi, math.pi * 2)

  -- Ojos (con parpadeo)
  local blink = (math.floor(love.timer.getTime() * 0.5) % 5 == 0)
                and (love.timer.getTime() % 0.5 < 0.15)
  if blink then
    love.graphics.setColor(0.10, 0.08, 0.12)
    love.graphics.rectangle("fill", -3, dy - 8, 2, 0.6)
    love.graphics.rectangle("fill", 1, dy - 8, 2, 0.6)
  else
    love.graphics.setColor(0.10, 0.08, 0.12)
    love.graphics.circle("fill", -2, dy - 8, 1)
    love.graphics.circle("fill", 2, dy - 8, 1)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", -2.2, dy - 8.3, 0.3)
    love.graphics.circle("fill", 1.8, dy - 8.3, 0.3)
  end

  love.graphics.pop()
end

return Dibujo