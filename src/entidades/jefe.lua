local Colisiones = require("src.sistemas.colisiones")

local Jefe = {}
Jefe.__index = Jefe

local GRAVEDAD = 900

function Jefe.nuevoSlimeRey(x, y)
  local j = setmetatable({}, Jefe)
  j.tipo = "slime_rey"
  j.nombre = "Sr. Babosius 3th"
  j.x, j.y = x, y
  j.hpMax = 300
  j.hp = 300
  j.radio = 22
  j.anchoDibujo = 56
  j.altoDibujo = 46
  j.vivo = true
  j.flashDanio = 0

  j.estado = "idle"
  j.timer = 1.0
  j.fase = 1

  j.z = 0
  j.vz = 0
  j.dirX, j.dirY = 0, 1
  j.objetivoX, j.objetivoY = x, y

  j.saltosSeguidos = 0
  j.maxSaltosSeguidos = 2
  j.tiempoDescanso = 0

  j.minionsInvocados = { false, false }

  j.anim = 0
  j.enfurecido = false
  j.danoOndaPendiente = false

  j.charcos = {}

  j.cooldownBolas = 0
  j.cooldownEscupitajo = 2.0

  -- Mira al jugador
  j.mirandoX = 0
  j.mirandoY = 0

  -- Particulas
  j.gooParticles = {}
  j.sweatParticles = {}

  -- Compatibilidad con la interfaz de los jefes nuevos
  j.recompensa = 30
  j.danoContacto = 1
  j.umbrales = { 0.66, 0.33 }
  j.barraSuperior = false   -- el Slime Rey tiene su propia barra sobre el cuerpo
  j.zonas = {}

  return j
end

function Jefe:recibirDanio(cantidad)
  if not self.vivo then return false end
  self.hp = self.hp - cantidad
  self.flashDanio = 0.12
  if self.hp <= 0 then
    self.hp = 0
    self.vivo = false
    return true
  end
  return false
end

function Jefe:actualizar(dt, mapa, objetivo, enemigos, soltarMinion, soltarBolas, dispararBolasDirigidas)
  if not self.vivo then return end
  self.anim = self.anim + dt
  if self.flashDanio > 0 then self.flashDanio = self.flashDanio - dt end
  if self.cooldownBolas > 0 then self.cooldownBolas = self.cooldownBolas - dt end
  if self.cooldownEscupitajo > 0 then self.cooldownEscupitajo = self.cooldownEscupitajo - dt end

  -- Mira hacia el jugador
  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local m = math.sqrt(dx * dx + dy * dy)
  if m > 0.001 then
    self.mirandoX = dx / m
    self.mirandoY = dy / m
  end

  -- Charcos
  local i = 1
  while i <= #self.charcos do
    local c = self.charcos[i]
    c.vida = c.vida - dt
    if c.vida <= 0 then table.remove(self.charcos, i) else i = i + 1 end
  end

  -- Fases
  local frac = self.hp / self.hpMax
  local nuevaFase = 1
  if frac < 0.33 then nuevaFase = 3
  elseif frac < 0.66 then nuevaFase = 2 end
  if nuevaFase > self.fase then
    self.fase = nuevaFase
    self.enfurecido = true
    if self.fase == 3 then
      self.maxSaltosSeguidos = 3
    else
      self.maxSaltosSeguidos = 2
    end
  end

  if self.fase >= 2 and not self.minionsInvocados[1] then
    self.minionsInvocados[1] = true
    soltarMinion(2, self.x, self.y)
  end
  if self.fase >= 3 and not self.minionsInvocados[2] then
    self.minionsInvocados[2] = true
    soltarMinion(3, self.x, self.y)
  end

  -- Gotas de baba
  if math.random() < 0.4 then
    table.insert(self.gooParticles, {
      x = self.x + (math.random() - 0.5) * self.anchoDibujo * 0.8,
      y = self.y + self.altoDibujo * 0.2 - self.z,
      vy = 40 + math.random() * 60,
      vida = 1.2,
      radio = 1.5 + math.random() * 1.5,
    })
  end
  local ig = 1
  while ig <= #self.gooParticles do
    local p = self.gooParticles[ig]
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 200 * dt
    p.vida = p.vida - dt
    if p.vida <= 0 or p.y > self.y + self.altoDibujo then
      table.remove(self.gooParticles, ig)
    else
      ig = ig + 1
    end
  end

  -- Gotas de sudor en fase 3
  if self.fase == 3 then
    if math.random() < 0.5 then
      local lado = (math.random() > 0.5) and 1 or -1
      table.insert(self.sweatParticles, {
        x = self.x + lado * self.anchoDibujo * 0.3,
        y = self.y - self.altoDibujo * 0.4 - self.z,
        vx = lado * 30,
        vy = -40,
        vida = 0.9,
        radio = 1.2,
      })
    end
    local is = 1
    while is <= #self.sweatParticles do
      local p = self.sweatParticles[is]
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.vy = p.vy + 180 * dt
      p.vida = p.vida - dt
      if p.vida <= 0 then
        table.remove(self.sweatParticles, is)
      else
        is = is + 1
      end
    end
  end

  -- Logica de estado
  if self.estado == "idle" then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      if self.cooldownEscupitajo <= 0 and math.random() < 0.7 then
        self.estado = "escupiendo"
        self.timer = 0.5
        self.cooldownEscupitajo = 2.0 - math.min(0.7, self.fase * 0.25)
      else
        if self.tiempoDescanso > 0 then
          self.tiempoDescanso = 0
          self.saltosSeguidos = 0
        end
        self.estado = "windup"
        self.timer = 0.6
      end
    end

  elseif self.estado == "escupiendo" then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      if dispararBolasDirigidas then
        dispararBolasDirigidas(self.x, self.y - 10, self.mirandoX, self.mirandoY)
      end
      self.estado = "idle"
      self.timer = 0.5 + math.random() * 0.4
    end

  elseif self.estado == "windup" then
    self.objetivoX = objetivo.x
    self.objetivoY = objetivo.y
    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "saltando"
      self.timer = 0.7
      self.vz = 380
      local ddx = self.objetivoX - self.x
      local ddy = self.objetivoY - self.y
      local dm = math.sqrt(ddx*ddx + ddy*ddy)
      if dm > 0.001 then
        self.dirX, self.dirY = ddx/dm, ddy/dm
      else
        self.dirX, self.dirY = 0, 0
      end
    end

  elseif self.estado == "saltando" then
    self.timer = self.timer - dt
    self.vz = self.vz - GRAVEDAD * dt
    self.z = self.z + self.vz * dt

    local multiplicador
    if self.fase == 3 then multiplicador = 1.15
    elseif self.fase == 2 then multiplicador = 1.05
    else multiplicador = 1.0 end

    local vel = 180 * multiplicador
    local vx = self.dirX * vel * dt
    local vy = self.dirY * vel * dt

    -- Solo colisiona con paredes externas durante el salto
    local nx = self.x + vx
    if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa, true) then
      self.x = nx
    else
      self.dirX = 0
    end
    local ny = self.y + vy
    if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa, true) then
      self.y = ny
    else
      self.dirY = 0
    end

    if self.z <= 0 and self.vz < 0 then
      self.z = 0
      self.vz = 0
      self.estado = "aterrizando"
      self.timer = 0.35
      self.danoOndaPendiente = true

      -- Explosion de baba al aterrizar
      for k = 1, 8 do
        local angRnd = math.random() * math.pi * 2
        local velRnd = 40 + math.random() * 60
        table.insert(self.gooParticles, {
          x = self.x,
          y = self.y,
          vx = math.cos(angRnd) * velRnd,
          vy = math.sin(angRnd) * velRnd * 0.4 - 50,
          vida = 0.8,
          radio = 2 + math.random() * 2,
        })
      end

      if self.fase == 3 then
        table.insert(self.charcos, { x = self.x, y = self.y, vida = 6.0, radio = 26 })
        local angRnd = math.random() * math.pi * 2
        local distRnd = 30 + math.random() * 30
        table.insert(self.charcos, {
          x = self.x + math.cos(angRnd) * distRnd,
          y = self.y + math.sin(angRnd) * distRnd,
          vida = 6.0,
          radio = 22
        })
      elseif self.fase == 2 then
        table.insert(self.charcos, { x = self.x, y = self.y, vida = 6.0, radio = 26 })
      end
    end

  elseif self.estado == "aterrizando" then
    if self.danoOndaPendiente then
      self.danoOndaPendiente = false
      local adx = objetivo.x - self.x
      local ady = objetivo.y - self.y
      local ad = math.sqrt(adx*adx + ady*ady)
      if ad < 60 then
        objetivo:recibirDanio(2)
      end

      if self.cooldownBolas <= 0 then
        self.cooldownBolas = 0.8
        local cantidadBolas = (self.fase == 3) and 3 or ((self.fase == 2) and 2 or 1)
        soltarBolas(self.x, self.y, cantidadBolas)
      end
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
      if self.fase == 3 then
        self.saltosSeguidos = self.saltosSeguidos + 1
        if self.saltosSeguidos < self.maxSaltosSeguidos then
          self.estado = "windup"
          self.timer = 0.30
        else
          self.estado = "idle"
          self.timer = 1.8 + math.random() * 0.4
          self.tiempoDescanso = self.timer
          self.saltosSeguidos = 0
        end
      elseif self.fase == 2 then
        self.saltosSeguidos = self.saltosSeguidos + 1
        if self.saltosSeguidos < self.maxSaltosSeguidos then
          self.estado = "windup"
          self.timer = 0.35
        else
          self.estado = "idle"
          self.timer = 1.2 + math.random() * 0.4
          self.saltosSeguidos = 0
        end
      else
        self.estado = "idle"
        self.timer = 1.0 + math.random() * 0.6
      end
    end
  end
end

-- ============================================================
-- DIBUJADO
-- ============================================================

function Jefe:colorCuerpo()
  if self.flashDanio > 0 then
    return {1, 1, 1}
  elseif self.estado == "windup" then
    return {1, 0.55, 0.55}
  elseif self.estado == "escupiendo" then
    return {0.75, 0.95, 0.65}
  elseif self.fase == 3 then
    if self.tiempoDescanso > 0 then
      return {0.42, 0.68, 0.55}
    else
      -- Enfurecido: tirando a rojizo
      return {0.62, 0.85, 0.42}
    end
  elseif self.fase == 2 then
    return {0.42, 0.82, 0.55}
  else
    return {0.35, 0.78, 0.62}
  end
end

function Jefe:colorSombra()
  if self.flashDanio > 0 then
    return {0.85, 0.85, 0.85}
  elseif self.fase == 3 and self.tiempoDescanso <= 0 then
    return {0.20, 0.45, 0.30}
  else
    return {0.18, 0.42, 0.35}
  end
end

function Jefe:dibujar()
  if not self.vivo then return end

  local cx = self.x
  local cy = self.y - self.z
  local w, h = self.anchoDibujo, self.altoDibujo

  -- ============ SOMBRA EN EL SUELO ============
  love.graphics.setColor(0, 0, 0, 0.40)
  local sombraEscala = 1 - math.min(0.7, self.z / 120)
  love.graphics.ellipse("fill", self.x, self.y + 14, w/2 * sombraEscala, 7 * sombraEscala)

  -- ============ CHARCOS ============
  for _, c in ipairs(self.charcos) do
    local a = math.min(1, c.vida / 1.5)
    local pulso = 0.85 + 0.15 * math.sin(self.anim * 5 + c.x * 0.1)
    love.graphics.setColor(0.30, 0.85, 0.40, 0.5 * a * pulso)
    love.graphics.ellipse("fill", c.x, c.y + 4, c.radio, c.radio * 0.4)
    love.graphics.setColor(0.50, 0.95, 0.55, 0.75 * a)
    love.graphics.ellipse("line", c.x, c.y + 4, c.radio, c.radio * 0.4)
    -- Burbujas
    for b = 1, 3 do
      local angB = self.anim * 2 + b * 2.1 + c.x
      local distB = math.sin(angB) * c.radio * 0.5
      love.graphics.setColor(0.85, 1.0, 0.90, 0.6 * a)
      love.graphics.circle("fill", c.x + distB, c.y + 2, 1.5)
    end
  end

  -- ============ AURA ============
  if self.fase >= 2 then
    local pulso = 0.5 + 0.5 * math.sin(self.anim * 8)
    if self.fase == 3 then
      if self.tiempoDescanso > 0 then
        love.graphics.setColor(0.5, 0.7, 1.0, 0.20 + pulso * 0.15)
      else
        love.graphics.setColor(1, 0.25, 0.20, 0.22 + pulso * 0.18)
      end
    else
      love.graphics.setColor(0.95, 0.75, 0.30, 0.15 + pulso * 0.12)
    end
    love.graphics.circle("fill", cx, cy, w/2 + 12)
  end

  -- ============ WOBBLE (animacion idle) ============
  local wobbleX = math.sin(self.anim * 3) * 0.03
  local wobbleY = math.cos(self.anim * 3) * 0.03
  local sx, sy = 1 + wobbleX, 1 - wobbleY

  if self.estado == "windup" then
    sx, sy = 1.15, 0.85
  elseif self.estado == "aterrizando" then
    sx, sy = 1.20, 0.80
  elseif self.estado == "escupiendo" then
    sx, sy = 0.88, 1.18
  end

  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.scale(sx, sy)

  local colorCuerpo = self:colorCuerpo()
  local colorSombra = self:colorSombra()

  -- ============ CUERPO CON MULTIPLES CAPAS ============

  -- Sombra interior (borde inferior)
  love.graphics.setColor(colorSombra)
  love.graphics.ellipse("fill", 0, h * 0.06, w/2, h/2)

  -- Cuerpo principal
  love.graphics.setColor(colorCuerpo)
  love.graphics.ellipse("fill", 0, 0, w/2 - 1, h/2 - 1)

  -- Brillo superior grande
  love.graphics.setColor(1, 1, 1, 0.35)
  love.graphics.ellipse("fill", -w/8, -h/4, w/3.5, h/5)

  -- Brillo secundario
  love.graphics.setColor(1, 1, 1, 0.20)
  love.graphics.ellipse("fill", w/6, -h/6, w/8, h/10)

  -- Highlight pequeño (specular)
  love.graphics.setColor(1, 1, 1, 0.55)
  love.graphics.circle("fill", -w/4, -h/3, 2)
  love.graphics.circle("fill", -w/6, -h/3 - 3, 1)

  -- Borde interior oscuro (volumen)
  love.graphics.setColor(colorSombra[1], colorSombra[2], colorSombra[3], 0.6)
  love.graphics.ellipse("line", 0, 0, w/2 - 2, h/2 - 2)

  -- ============ CARA ============

  -- Ojos con pupilas que siguen al jugador
  local eyeBaseX = -6
  local eyeBaseY = -3
  local eyeOffset = 1.8

  -- Cuencas de los ojos
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.circle("fill", eyeBaseX, eyeBaseY, 4)
  love.graphics.circle("fill", -eyeBaseX, eyeBaseY, 4)

  -- Pupilas
  love.graphics.setColor(0.08, 0.08, 0.12)
  love.graphics.circle("fill", eyeBaseX + self.mirandoX * eyeOffset, eyeBaseY + self.mirandoY * eyeOffset, 2.2)
  love.graphics.circle("fill", -eyeBaseX + self.mirandoX * eyeOffset, eyeBaseY + self.mirandoY * eyeOffset, 2.2)

  -- Brillo de las pupilas
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("fill",
    eyeBaseX + self.mirandoX * eyeOffset - 0.8,
    eyeBaseY + self.mirandoY * eyeOffset - 0.8, 0.6)
  love.graphics.circle("fill",
    -eyeBaseX + self.mirandoX * eyeOffset - 0.8,
    eyeBaseY + self.mirandoY * eyeOffset - 0.8, 0.6)

  -- Cejas (mas enojadas segun fase)
  if self.fase >= 2 then
    love.graphics.setColor(colorSombra)
    if self.fase == 3 and self.tiempoDescanso <= 0 then
      -- Muy enojado: cejas inclinadas fuertemente
      love.graphics.polygon("fill", eyeBaseX - 4, eyeBaseY - 5, eyeBaseX + 1, eyeBaseY - 2, eyeBaseX + 1, eyeBaseY - 4)
      love.graphics.polygon("fill", -eyeBaseX - 1, eyeBaseY - 2, -eyeBaseX + 4, eyeBaseY - 5, -eyeBaseX - 1, eyeBaseY - 4)
    else
      -- Enojado
      love.graphics.polygon("fill", eyeBaseX - 3.5, eyeBaseY - 4.5, eyeBaseX + 1, eyeBaseY - 3, eyeBaseX + 1, eyeBaseY - 4)
      love.graphics.polygon("fill", -eyeBaseX - 1, eyeBaseY - 3, -eyeBaseX + 3.5, eyeBaseY - 4.5, -eyeBaseX - 1, eyeBaseY - 4)
    end
  end

  -- ============ BOCA ============
  love.graphics.setColor(0.10, 0.10, 0.15, 0.85)
  if self.estado == "escupiendo" then
    -- Boca abierta grande
    love.graphics.ellipse("fill", 0, 6, 5, 4)
    love.graphics.setColor(0.40, 0.90, 0.55)
    love.graphics.ellipse("fill", 0, 6, 3, 2.5)
  elseif self.fase == 3 and self.tiempoDescanso <= 0 then
    -- Sonrisa malvada
    love.graphics.arc("line", "open", 0, 4, 6, 0.2, math.pi - 0.2)
    love.graphics.arc("line", "open", 0, 6, 8, 0.3, math.pi - 0.3)
  else
    -- Sonrisa normal
    love.graphics.arc("line", "open", 0, 4, 5, 0.2, math.pi - 0.2)
  end

  love.graphics.pop()

  -- ============ CORONA ============
  love.graphics.push()
  love.graphics.translate(cx, cy - h/2 + 2 + math.sin(self.anim * 2) * 0.5)

  -- Base de la corona
  love.graphics.setColor(0.75, 0.55, 0.10)
  love.graphics.rectangle("fill", -16, 0, 32, 4, 1)
  love.graphics.setColor(0.95, 0.75, 0.20)
  love.graphics.rectangle("fill", -16, 0, 32, 2, 1)

  -- Puntas de la corona (3 picos)
  love.graphics.setColor(0.95, 0.80, 0.20)
  love.graphics.polygon("fill", -16, 0, -12, -12, -8, 0)
  love.graphics.polygon("fill", -5, 0, 0, -15, 5, 0)
  love.graphics.polygon("fill", 8, 0, 12, -12, 16, 0)

  -- Brillo en los picos
  love.graphics.setColor(1, 0.95, 0.55)
  love.graphics.polygon("fill", -15, 0, -12, -11, -10, 0)
  love.graphics.polygon("fill", -3, 0, 0, -14, 3, 0)
  love.graphics.polygon("fill", 10, 0, 12, -11, 15, 0)

  -- Gemas en los picos
  love.graphics.setColor(0.90, 0.15, 0.25)
  love.graphics.circle("fill", -12, -10, 1.8)
  love.graphics.setColor(0.30, 0.85, 0.95)
  love.graphics.circle("fill", 0, -12, 2)
  love.graphics.setColor(0.90, 0.15, 0.25)
  love.graphics.circle("fill", 12, -10, 1.8)

  -- Brillo de las gemas
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.circle("fill", -12.5, -10.5, 0.6)
  love.graphics.circle("fill", -0.5, -12.5, 0.7)
  love.graphics.circle("fill", 11.5, -10.5, 0.6)

  -- Banda decorativa
  love.graphics.setColor(0.55, 0.35, 0.10)
  love.graphics.rectangle("fill", -16, 2, 32, 1)

  love.graphics.pop()

  -- ============ GOTAS DE BABA ============
  for _, p in ipairs(self.gooParticles) do
    local a = math.min(1, p.vida * 2)
    love.graphics.setColor(0.45, 0.85, 0.55, a * 0.85)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(0.75, 0.98, 0.80, a * 0.9)
    love.graphics.circle("fill", p.x - p.radio * 0.3, p.y - p.radio * 0.3, p.radio * 0.4)
  end

  -- ============ GOTAS DE SUDOR (fase 3) ============
  for _, p in ipairs(self.sweatParticles) do
    local a = math.min(1, p.vida * 2)
    love.graphics.setColor(0.70, 0.90, 1.0, a * 0.9)
    love.graphics.circle("fill", p.x, p.y, p.radio)
  end

  -- ============ BARRA DE VIDA ============
  local bw, bh = 140, 6
  local bx = self.x - bw/2
  local by = self.y - h/2 - self.z - 22
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", bx - 1, by - 1, bw + 2, bh + 2)
  love.graphics.setColor(0.25, 0.10, 0.10)
  love.graphics.rectangle("fill", bx, by, bw, bh)
  local frac = self.hp / self.hpMax
  love.graphics.setColor(0.85, 0.20, 0.25)
  love.graphics.rectangle("fill", bx, by, bw * frac, bh)
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.rectangle("line", bx, by, bw, bh)

  love.graphics.setColor(1, 1, 1)
  local txt = self.nombre
  local f = love.graphics.getFont()
  local tw = f:getWidth(txt)
  love.graphics.print(txt, self.x - tw/2, by - 14)

  if self.fase >= 2 then
    local iy = by + bh + 4
    for i = 1, self.maxSaltosSeguidos do
      local cx2 = self.x - (self.maxSaltosSeguidos * 5) + (i - 1) * 10 + 5
      if i <= self.saltosSeguidos then
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.circle("fill", cx2, iy + 3, 2.5)
      else
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.circle("line", cx2, iy + 3, 2.5)
      end
    end
  end
end

function Jefe:colisiona(x, y, r)
  if not self.vivo then return false end
  if self.z > 20 then return false end
  local dx = self.x - x
  local dy = self.y - y
  local rr = self.radio + r
  return dx*dx + dy*dy < rr*rr
end

return Jefe