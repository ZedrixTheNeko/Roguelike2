local E = require("src.entidades.enemigo.base")

function E:dibujar()
  if not self.vivo then return end

  if self.esElite then
    self:dibujarAuraElite()
  end

  -- Enemigos clasicos
  if self.tipo == "slime_pequeno" then
    self:dibujarSlime()
  elseif self.tipo == "esqueleto_guardia" then
    self:dibujarEsqueleto()
  elseif self.tipo == "esqueleto_arquero" then
    self:dibujarArquero()
  elseif self.tipo == "rata_gigante" then
    self:dibujarRata()
  elseif self.tipo == "murcielago" then
    self:dibujarMurcielago()
  elseif self.tipo == "mago_oscuro" then
    self:dibujarMagoOscuro()
  elseif E.registroDibujo and E.registroDibujo[self.tipo] then
    -- Enemigos nuevos de los biomas
    E.registroDibujo[self.tipo](self)
  end

  if self.quemaduraTimer > 0 then self:dibujarQuemadura() end
  if self.stunTimer > 0 then self:dibujarStun() end

  -- Onda sonica del murcielago elite
  if self.ondaSonica then
    local a = math.max(0, 1 - self.ondaSonica.timer / 1.5)
    love.graphics.setColor(0.55, 0.75, 1.0, a * 0.7)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", self.ondaSonica.x, self.ondaSonica.y, self.ondaSonica.radio)
    love.graphics.setColor(0.75, 0.90, 1.0, a * 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.ondaSonica.x, self.ondaSonica.y, self.ondaSonica.radio - 8)
    love.graphics.setLineWidth(1)
  end

  -- Aviso de windup de ataque especial
  if self.habEstado == "windup" then
    local progreso = self.habTimer / 0.8
    love.graphics.setColor(1, 0.4, 0.2, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.x, self.y, 25 + progreso * 15)
    love.graphics.setColor(1, 0.6, 0.3, 0.3 + progreso * 0.3)
    love.graphics.circle("fill", self.x, self.y, 15)
    love.graphics.setLineWidth(1)
  end
end

-- ============ AURA DE ELITE ============

function E:dibujarAuraElite()
  local pulso = 0.5 + 0.5 * math.sin(self.animTimer * 4)
  local r = self.radio + 6 + pulso * 3

  love.graphics.setColor(1, 0.85, 0.30, 0.15 + pulso * 0.10)
  love.graphics.circle("fill", self.x, self.y, r + 4)

  love.graphics.setColor(1, 0.90, 0.40, 0.55 + pulso * 0.30)
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", self.x, self.y, r)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(1, 0.95, 0.60, 0.35 + pulso * 0.25)
  love.graphics.circle("line", self.x, self.y, r - 4)

  -- Estrella encima
  local yOffset = self.y - self.radio - 12
  local pulsoEstrella = 0.5 + 0.5 * math.sin(self.animTimer * 5)
  local tam = 4 + pulsoEstrella * 1.5

  love.graphics.setColor(1, 0.90, 0.30)
  love.graphics.polygon("fill",
    self.x, yOffset - tam,
    self.x + tam * 0.4, yOffset - tam * 0.4,
    self.x + tam, yOffset,
    self.x + tam * 0.4, yOffset + tam * 0.4,
    self.x, yOffset + tam,
    self.x - tam * 0.4, yOffset + tam * 0.4,
    self.x - tam, yOffset,
    self.x - tam * 0.4, yOffset - tam * 0.4)
  love.graphics.setColor(1, 1, 0.80)
  love.graphics.circle("fill", self.x, yOffset, tam * 0.4)
end

-- ============ EFECTOS DE ESTADO ============

function E:dibujarQuemadura()
  local pulso = 0.5 + 0.5 * math.sin(self.quemaduraFlash * 20)
  love.graphics.setColor(1, 0.45, 0.10, 0.20 + pulso * 0.20)
  love.graphics.circle("fill", self.x, self.y, self.radio + 4 + pulso * 2)
  love.graphics.setColor(1, 0.65, 0.20, 0.55 + pulso * 0.35)
  love.graphics.circle("line", self.x, self.y, self.radio + 3 + pulso * 2)
  for i = 1, 3 do
    local ang = self.animTimer * 4 + i * 2.1
    local fx = self.x + math.cos(ang) * self.radio * 0.6
    local fy = self.y - 2 - math.abs(math.sin(ang * 2)) * 6
    love.graphics.setColor(1, 0.55, 0.15, 0.75)
    love.graphics.circle("fill", fx, fy, 1.8)
    love.graphics.setColor(1, 0.90, 0.45, 0.9)
    love.graphics.circle("fill", fx, fy - 0.5, 0.9)
  end
end

function E:dibujarStun()
  local baseY = self.y - self.datos.altoDibujo / 2 - 8
  for i = 1, 3 do
    local ang = self.animTimer * 3 + (i - 1) * (math.pi * 2 / 3)
    local sx = self.x + math.cos(ang) * 10
    local sy = baseY + math.sin(ang) * 2 - 2
    love.graphics.setColor(1, 0.90, 0.20)
    love.graphics.circle("fill", sx, sy, 2.5)
    love.graphics.setColor(1, 1, 0.70)
    love.graphics.circle("fill", sx, sy, 1.4)
  end
end

-- ============ DIBUJO POR TIPO ============

function E:dibujarSlime()
  local datos = self.datos
  local offsetZ = 0
  local squashY, squashX = 1, 1
  if self.estado == "saltando" then
    offsetZ = -math.sin(self.saltoProgreso * math.pi) * 5
    if self.saltoProgreso < 0.15 then squashY = 1.3; squashX = 0.8 end
    if self.saltoProgreso > 0.4 and self.saltoProgreso < 0.6 then squashY = 0.85; squashX = 1.1 end
  end
  local cx = self.x
  local cy = self.y + offsetZ
  local w = datos.anchoDibujo * squashX * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * squashY * (self.esElite and 1.3 or 1)
  love.graphics.setColor(0, 0, 0, 0.30)
  local sombraEscala = 1 - math.min(0.5, -offsetZ / 20)
  love.graphics.ellipse("fill", self.x, self.y + 4, (w / 3) * sombraEscala, 3 * sombraEscala)

  if self.flashDanio > 0 then love.graphics.setColor(1, 1, 1)
  else love.graphics.setColor(0.35, 0.75, 0.90) end
  love.graphics.ellipse("fill", cx, cy, w / 2, h / 2)

  love.graphics.setColor(1, 1, 1, 0.40)
  love.graphics.ellipse("fill", cx - w / 6, cy - h / 4, w / 5, h / 6)

  love.graphics.setColor(0.20, 0.55, 0.75, 0.5)
  love.graphics.ellipse("line", cx, cy, w / 2 - 0.5, h / 2 - 0.5)

  love.graphics.setColor(0.10, 0.10, 0.15)
  love.graphics.circle("fill", cx - 2, cy - 1, 1.2)
  love.graphics.circle("fill", cx + 2, cy - 1, 1.2)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("fill", cx - 1.7, cy - 1.5, 0.5)
  love.graphics.circle("fill", cx + 2.3, cy - 1.5, 0.5)
end

function E:dibujarEsqueleto()
  local datos = self.datos
  local w = datos.anchoDibujo * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * (self.esElite and 1.3 or 1)
  local shakeX, shakeY = 0, 0
  if self.flashDanio > 0 then
    shakeX = (math.random() - 0.5) * 2
    shakeY = (math.random() - 0.5) * 2
  end
  local cx, cy = self.x + shakeX, self.y + shakeY
  local bob = math.sin(self.animTimer * 6) * 0.8

  love.graphics.setColor(0, 0, 0, 0.30)
  love.graphics.ellipse("fill", self.x, self.y + h / 2 - 1, w / 2.5, 3)

  local colHueso, colDetalle
  if self.flashDanio > 0 then colHueso, colDetalle = {1,1,1}, {1,1,1}
  elseif self.estado == "windup_corte" or self.estado == "windup_estocada" or self.habEstado == "windup" then
    colHueso, colDetalle = {1,0.60,0.50}, {1,0.65,0.55}
  else colHueso, colDetalle = {0.95,0.92,0.82}, {0.88,0.85,0.75} end

  local dy = cy + bob
  love.graphics.setColor(colHueso)
  love.graphics.rectangle("fill", cx - 5, dy + 4, 3, 7)
  love.graphics.rectangle("fill", cx + 2, dy + 4, 3, 7)
  love.graphics.setColor(colDetalle)
  love.graphics.rectangle("fill", cx - 5, dy + 7, 3, 1)
  love.graphics.rectangle("fill", cx + 2, dy + 7, 3, 1)

  love.graphics.setColor(colHueso)
  love.graphics.rectangle("fill", cx - 5, dy + 2, 10, 4, 1)
  love.graphics.rectangle("fill", cx - 1, dy - 8, 2, 11)
  love.graphics.setColor(colDetalle)
  for i = 0, 2 do
    local ry = dy - 6 + i * 3
    love.graphics.rectangle("fill", cx - 6, ry, 12, 1.5)
  end

  love.graphics.setColor(colHueso)
  love.graphics.circle("fill", cx, dy - 12, 5.5)
  love.graphics.setColor(colDetalle)
  love.graphics.rectangle("fill", cx - 3.5, dy - 8.5, 7, 2.5)

  local ox = self.ultimaDirX * 1.2
  local oy = self.ultimaDirY * 1.0
  love.graphics.setColor(0.10, 0.05, 0.10)
  love.graphics.circle("fill", cx - 2 + ox, dy - 12 + oy, 1.8)
  love.graphics.circle("fill", cx + 2 + ox, dy - 12 + oy, 1.8)
  love.graphics.setColor(0.90, 0.15, 0.15)
  love.graphics.circle("fill", cx - 2 + ox, dy - 12 + oy, 1)
  love.graphics.circle("fill", cx + 2 + ox, dy - 12 + oy, 1)

  local sw = 15
  local sx = cx + w / 2 - 3
  local sy = dy - 2

  if self.estado == "windup_corte" or self.estado == "windup_estocada" or self.habEstado == "windup" then
    love.graphics.setColor(0.90, 0.90, 0.95)
    love.graphics.rectangle("fill", sx - 1.5, sy - sw, 3, sw)
    love.graphics.setColor(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", sx - 3, sy - 1, 6, 4, 1)
  elseif self.estado == "atacando_corte" or self.estado == "atacando_estocada" or self.habEstado == "activo" then
    love.graphics.setColor(1, 0.95, 0.70, 0.85)
    love.graphics.polygon("fill", sx - 6, sy - 3, sx + sw + 6, sy, sx - 6, sy + 3)
    love.graphics.setColor(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", sx - 6, sy - 2, 5, 5, 1)
  else
    love.graphics.setColor(0.90, 0.90, 0.95)
    love.graphics.rectangle("fill", sx, sy - 1, sw, 2.5)
    love.graphics.setColor(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", sx - 3, sy - 2, 4, 4.5, 1)
  end
end

function E:dibujarArquero()
  local datos = self.datos
  local w = datos.anchoDibujo * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * (self.esElite and 1.3 or 1)
  local shakeX, shakeY = 0, 0
  if self.flashDanio > 0 then
    shakeX = (math.random() - 0.5) * 2
    shakeY = (math.random() - 0.5) * 2
  end
  local cx, cy = self.x + shakeX, self.y + shakeY
  local bob = math.sin(self.animTimer * 6) * 0.8

  love.graphics.setColor(0, 0, 0, 0.30)
  love.graphics.ellipse("fill", self.x, self.y + h / 2 - 1, w / 2.5, 3)

  local colHueso, colDetalle
  if self.flashDanio > 0 then colHueso, colDetalle = {1,1,1}, {1,1,1}
  elseif self.habEstado == "windup" then colHueso, colDetalle = {1,0.60,0.50}, {1,0.65,0.55}
  else colHueso, colDetalle = {0.92,0.88,0.78}, {0.85,0.80,0.70} end

  local dy = cy + bob
  love.graphics.setColor(colHueso)
  love.graphics.rectangle("fill", cx - 4, dy + 3, 3, 6)
  love.graphics.rectangle("fill", cx + 1, dy + 3, 3, 6)
  love.graphics.rectangle("fill", cx - 5, dy + 1, 10, 3, 1)
  love.graphics.rectangle("fill", cx - 1, dy - 7, 2, 9)
  love.graphics.setColor(colDetalle)
  for i = 0, 2 do
    local ry = dy - 5 + i * 3
    love.graphics.rectangle("fill", cx - 5, ry, 10, 1.5)
  end

  love.graphics.setColor(colHueso)
  love.graphics.circle("fill", cx, dy - 11, 5)
  love.graphics.setColor(colDetalle)
  love.graphics.rectangle("fill", cx - 3, dy - 8, 6, 2)

  local ox = self.ultimaDirX * 1.2
  local oy = self.ultimaDirY * 1.0
  love.graphics.setColor(0.10, 0.10, 0.12)
  love.graphics.circle("fill", cx - 2 + ox, dy - 11 + oy, 1.6)
  love.graphics.circle("fill", cx + 2 + ox, dy - 11 + oy, 1.6)
  love.graphics.setColor(0.30, 0.95, 0.35)
  love.graphics.circle("fill", cx - 2 + ox, dy - 11 + oy, 0.9)
  love.graphics.circle("fill", cx + 2 + ox, dy - 11 + oy, 0.9)

  local arcX = cx + w / 2 - 1
  local arcY = dy - 1
  love.graphics.setColor(0.55, 0.40, 0.25)
  love.graphics.setLineWidth(2)
  love.graphics.arc("line", "open", arcX, arcY, 9, -math.pi / 2.4, math.pi / 2.4)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.85, 0.85, 0.80)
  love.graphics.line(arcX + 3, arcY - 8, arcX + 3, arcY + 8)
end

function E:dibujarRata()
  local datos = self.datos
  local w = datos.anchoDibujo * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * (self.esElite and 1.3 or 1)
  local shakeX = 0
  if self.flashDanio > 0 then shakeX = (math.random() - 0.5) * 2 end
  local cx, cy = self.x + shakeX, self.y

  love.graphics.setColor(0, 0, 0, 0.30)
  love.graphics.ellipse("fill", self.x, self.y + h / 2, w / 2.5, 2.5)

  local colCuerpo = self.flashDanio > 0 and {1,1,1} or {0.42, 0.30, 0.22}
  local colOscuro = self.flashDanio > 0 and {1,1,1} or {0.28, 0.18, 0.12}

  -- Cola
  love.graphics.setColor(colOscuro)
  local colaAng = math.sin(self.animTimer * 8) * 0.4
  local colaX = cx - self.ultimaDirX * 10
  local colaY = cy - self.ultimaDirY * 10
  love.graphics.setLineWidth(2)
  love.graphics.line(colaX, colaY, colaX - 8, colaY + colaAng * 5)
  love.graphics.setLineWidth(1)

  -- Cuerpo
  love.graphics.setColor(colCuerpo)
  love.graphics.ellipse("fill", cx, cy, w / 2 - 1, h / 2)

  -- Cabeza
  love.graphics.setColor(colCuerpo)
  love.graphics.circle("fill", cx + self.ultimaDirX * 5, cy + self.ultimaDirY * 5, 5)

  -- Orejas
  love.graphics.setColor(colOscuro)
  love.graphics.circle("fill", cx + self.ultimaDirX * 3 - 3, cy - 4, 2)
  love.graphics.circle("fill", cx + self.ultimaDirX * 3 + 3, cy - 4, 2)

  -- Ojos rojos
  love.graphics.setColor(0.95, 0.15, 0.15)
  love.graphics.circle("fill", cx + self.ultimaDirX * 6 - 2, cy - 1, 1)
  love.graphics.circle("fill", cx + self.ultimaDirX * 6 + 2, cy - 1, 1)

  -- Patas
  love.graphics.setColor(colOscuro)
  love.graphics.rectangle("fill", cx - 4, cy + h / 2 - 1, 2, 3)
  love.graphics.rectangle("fill", cx + 3, cy + h / 2 - 1, 2, 3)
end

function E:dibujarMurcielago()
  local datos = self.datos
  local w = datos.anchoDibujo * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * (self.esElite and 1.3 or 1)
  local cx = self.x
  local cy = self.y - self.z

  -- Sombra
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", self.x, self.y + h / 2, w / 3, 2.5)

  local colCuerpo = self.flashDanio > 0 and {1,1,1} or {0.25, 0.15, 0.35}
  local colAla = self.flashDanio > 0 and {1,1,1} or {0.35, 0.22, 0.45}

  local alaAngulo = math.sin(self.animTimer * 14) * 0.6

  -- Ala izquierda
  love.graphics.setColor(colAla)
  love.graphics.polygon("fill",
    cx - 2, cy,
    cx - 12, cy - 4 + alaAngulo * 4,
    cx - 10, cy + 2 + alaAngulo * 3,
    cx - 3, cy + 3)

  -- Ala derecha
  love.graphics.setColor(colAla)
  love.graphics.polygon("fill",
    cx + 2, cy,
    cx + 12, cy - 4 - alaAngulo * 4,
    cx + 10, cy + 2 - alaAngulo * 3,
    cx + 3, cy + 3)

  -- Cuerpo
  love.graphics.setColor(colCuerpo)
  love.graphics.ellipse("fill", cx, cy, 5, 6)

  -- Orejas
  love.graphics.setColor(colCuerpo)
  love.graphics.polygon("fill", cx - 3, cy - 5, cx - 5, cy - 9, cx - 1, cy - 6)
  love.graphics.polygon("fill", cx + 3, cy - 5, cx + 5, cy - 9, cx + 1, cy - 6)

  -- Ojos
  love.graphics.setColor(0.95, 0.35, 0.35)
  love.graphics.circle("fill", cx - 2, cy - 2, 1)
  love.graphics.circle("fill", cx + 2, cy - 2, 1)
end

function E:dibujarMagoOscuro()
  local datos = self.datos
  local w = datos.anchoDibujo * (self.esElite and 1.3 or 1)
  local h = datos.altoDibujo * (self.esElite and 1.3 or 1)
  local shakeX, shakeY = 0, 0
  if self.flashDanio > 0 then
    shakeX = (math.random() - 0.5) * 2
    shakeY = (math.random() - 0.5) * 2
  end
  local cx, cy = self.x + shakeX, self.y + shakeY
  local bob = math.sin(self.animTimer * 3) * 0.8

  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", self.x, self.y + h / 2 - 2, w / 2.5, 3)

  local colTunica = self.flashDanio > 0 and {1,1,1} or {0.20, 0.08, 0.28}
  local colCapa = self.flashDanio > 0 and {1,1,1} or {0.12, 0.05, 0.18}

  local dy = cy + bob

  -- Capa
  love.graphics.setColor(colCapa)
  love.graphics.polygon("fill",
    cx - 8, dy - 6,
    cx + 8, dy - 6,
    cx + 12, dy + 12,
    cx - 12, dy + 12)

  -- Tunica
  love.graphics.setColor(colTunica)
  love.graphics.polygon("fill",
    cx - 6, dy - 4,
    cx + 6, dy - 4,
    cx + 7, dy + 8,
    cx - 7, dy + 8)

  -- Runas del pecho
  love.graphics.setColor(0.75, 0.30, 0.95, 0.7)
  love.graphics.rectangle("fill", cx - 1, dy - 2, 2, 8)
  love.graphics.circle("fill", cx, dy + 3, 2)
  love.graphics.setColor(1, 0.55, 1.0)
  love.graphics.circle("fill", cx, dy + 3, 1)

  -- Capucha
  love.graphics.setColor(colCapa)
  love.graphics.polygon("fill",
    cx - 7, dy - 6,
    cx + 7, dy - 6,
    cx, dy - 15)

  -- Cara
  love.graphics.setColor(0.05, 0.02, 0.08)
  love.graphics.circle("fill", cx, dy - 8, 5)

  -- Ojos brillantes
  local pulsoOjos = 0.5 + 0.5 * math.sin(self.animTimer * 5)
  love.graphics.setColor(0.95, 0.20, 0.20, 0.7 + pulsoOjos * 0.3)
  love.graphics.circle("fill", cx - 2, dy - 8, 1.2)
  love.graphics.circle("fill", cx + 2, dy - 8, 1.2)
  love.graphics.setColor(1, 0.85, 0.55)
  love.graphics.circle("fill", cx - 2, dy - 8, 0.5)
  love.graphics.circle("fill", cx + 2, dy - 8, 0.5)

  -- Aura de carga
  if self.cargando or self.habEstado == "windup" then
    local progreso
    if self.cargando then
      progreso = 1 - (self.cargaTimer / 0.8)
    else
      progreso = self.habTimer / 1.0
    end
    local colorAura = (self.habEspecial == "lluvia_bolas")
                      and {0.85, 0.20, 1.0}
                      or  {0.75, 0.25, 0.95}

    love.graphics.setColor(colorAura[1], colorAura[2], colorAura[3], 0.30 + progreso * 0.4)
    love.graphics.circle("line", cx, dy - 8, 8 + progreso * 4)
    love.graphics.setColor(colorAura[1], colorAura[2] + 0.3, colorAura[3], 0.5 + progreso * 0.4)
    love.graphics.circle("fill", cx, dy - 8, 2 + progreso * 4)

    for i = 1, 3 do
      local ang = self.animTimer * 6 + i * 2.1
      local px = cx + math.cos(ang) * (8 + progreso * 3)
      local py = dy - 8 + math.sin(ang) * (8 + progreso * 3)
      love.graphics.setColor(0.85, 0.45, 1.0, 0.8)
      love.graphics.circle("fill", px, py, 1.5)
    end
  end

  -- Baston
  local bastonAng = math.atan2(self.ultimaDirY, self.ultimaDirX)
  love.graphics.push()
  love.graphics.translate(cx + self.ultimaDirX * 8, dy + self.ultimaDirY * 4)
  love.graphics.rotate(bastonAng + math.pi / 2)
  love.graphics.setColor(0.35, 0.20, 0.15)
  love.graphics.rectangle("fill", -1, -12, 2, 20)
  local pulsoGema = 0.5 + 0.5 * math.sin(self.animTimer * 4)
  love.graphics.setColor(0.75, 0.25, 0.95, 0.6 + pulsoGema * 0.4)
  love.graphics.circle("fill", 0, -13, 3)
  love.graphics.setColor(1, 0.60, 1.0, 0.9)
  love.graphics.circle("fill", 0, -13, 1.5)
  love.graphics.pop()
end

return E