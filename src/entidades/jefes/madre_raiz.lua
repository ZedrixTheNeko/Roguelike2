-- Jefe 2: MADRE RAIZ (Bosque Maldito)
local Base = require("src.entidades.jefes.base")
local Juice = require("src.sistemas.juice")
local atan2 = math.atan2 or math.atan
local PI = math.pi

local C = setmetatable({}, { __index = Base })
C.__index = C

function C.nuevo(x, y, escala)
  local j = Base.crear(C, {
    tipo = "madre_raiz", nombre = "Madre Raiz", subtitulo = "Guardiana del Bosque Maldito",
    x = x, y = y, hpMax = math.floor(430 * (escala or 1)), radio = 24,
    anchoDibujo = 64, altoDibujo = 70, recompensa = 40, danoContacto = 2,
  })
  j.colorMuerte = { 0.5, 0.9, 0.3 }
  j.colorFase = { 0.6, 1.0, 0.3 }
  j.brazos = 0
  j.ataque = nil
  j.paso = 0
  return j
end

local VERDE = { 0.55, 0.90, 0.25 }

function C:escalaTiempo()
  return (self.fase == 1 and 1) or (self.fase == 2 and 0.85) or 0.7
end

function C:elegir(objetivo, enemigos)
  local d = self:distA(objetivo)
  local pool = { "raices", "esporas" }
  if d < 140 then pool[#pool + 1] = "latigazo"; pool[#pool + 1] = "latigazo" end
  if self.fase >= 2 and self:contarEnemigos(enemigos) < 4 then pool[#pool + 1] = "brotes" end
  if self.fase >= 3 then pool[#pool + 1] = "estampida" end
  for _ = 1, 4 do
    local a = pool[math.random(#pool)]
    if a ~= self.ultimoAtaque then self.ultimoAtaque = a; return a end
  end
  return pool[1]
end

function C:alCambiarFase(nueva, ctx)
  if nueva == 2 then
    ctx.minion("arana_venenosa", self.x - 40, self.y + 40)
    ctx.minion("arana_venenosa", self.x + 40, self.y + 40)
  end
  if nueva == 3 then
    ctx.minion("hongo_toxico", self.x - 50, self.y + 30)
    ctx.minion("hongo_toxico", self.x + 50, self.y + 30)
  end
  self.brazos = 1
end

function C:duranteTransicion(dt)
  if math.random() < 0.4 then
    Juice.humo(self.x + (math.random() - 0.5) * 50, self.y, 1, { 0.5, 0.8, 0.3 }, 0.8)
  end
end

function C:iniciar(nombre, dur)
  self.estado = "ataque"
  self.ataque = nombre
  self.timer = dur
  self.sub = 0
  self.hecho = false
end

function C:actualizar(dt, mapa, objetivo, enemigos, ctx)
  if not self:tickBase(dt, mapa, objetivo, enemigos, ctx) then
    self.brazos = math.max(0, self.brazos - dt)
    return
  end
  local f = self:escalaTiempo()
  local d, ux, uy = self:distA(objetivo)

  if self.estado == "idle" then
    self.brazos = math.max(0, self.brazos - dt * 2)
    if d > 70 then self:mover(ux, uy, 26 + self.fase * 6, dt, mapa) end
    self.paso = self.paso + dt
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local a = self:elegir(objetivo, enemigos)
      if a == "raices" then self:iniciar(a, 0.6 * f)
      elseif a == "latigazo" then self:iniciar(a, 0.1)
      elseif a == "esporas" then self:iniciar(a, 0.5); self.sub = 0
      elseif a == "brotes" then self:iniciar(a, 0.9)
      else self:iniciar(a, 0.6 * f) end
    end
    return
  end

  -- estado ataque
  self.timer = self.timer - dt
  local a = self.ataque

  if a == "raices" then
    self.brazos = math.min(1, self.brazos + dt * 3)
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      local n = 4 + self.fase * 2
      for i = 1, n do
        local px, py
        if i == 1 then
          px, py = objetivo.x, objetivo.y
        else
          local ang = math.random() * PI * 2
          local r = 35 + math.random() * 55
          px, py = objetivo.x + math.cos(ang) * r, objetivo.y + math.sin(ang) * r
        end
        self:agregarZona({
          tipo = "circulo", x = px, y = py, r = 24,
          delay = 0.95 * f, retraso = 0.1 * (i - 1),
          dano = 2, color = { 0.45, 0.85, 0.2 }, sacudida = 1.5,
          charco = (self.fase >= 3) and { radio = 22, vida = 4, dano = 1, tipo = "veneno" } or nil,
        })
      end
      self.timer = 1.4 * f + 0.1 * n
    elseif self.timer <= 0 and self.hecho then
      self.hecho = false
      self.estado = "idle"
      self.timer = 0.8 * f
    end

  elseif a == "latigazo" then
    if self.sub == 0 then
      self.sub = 1
      local ang = atan2(uy, ux)
      self.angLatigo = ang
      self:agregarZona({
        tipo = "cono", x = self.x, y = self.y, r = 112, ang = ang, apertura = math.rad(42),
        delay = 0.75 * f, dano = 2, color = { 0.75, 0.9, 0.3 }, sacudida = 2.5,
      })
      if self.fase >= 2 then
        self:agregarZona({
          tipo = "cono", x = self.x, y = self.y, r = 112, ang = ang + PI, apertura = math.rad(42),
          delay = 0.75 * f, retraso = 0.55, dano = 2, color = { 0.75, 0.9, 0.3 }, sacudida = 2.5,
        })
      end
      self.timer = 0.75 * f + (self.fase >= 2 and 0.55 or 0) + 0.7
    elseif self.timer > 0.7 then
      self.brazos = math.min(1, self.brazos + dt * 2)
    else
      self.brazos = math.max(0, self.brazos - dt * 4)
    end
    if self.timer <= 0 then
      self.sub = 0
      self.estado = "idle"
      self.timer = 0.9 * f
    end

  elseif a == "esporas" then
    self.brazos = math.min(1, self.brazos + dt * 2)
    if self.timer <= 0 then
      if self.sub < self.fase then
        local n = 12
        local base = self.sub * 0.26 + math.random() * 0.1
        for i = 1, n do
          local ang = base + (i - 1) * PI * 2 / n
          ctx.disparar(self.x, self.y, math.cos(ang), math.sin(ang), 85 + self.sub * 12, 1, "espora")
        end
        Juice.humo(self.x, self.y, 6, { 0.6, 0.85, 0.3 }, 0.8)
        self.sub = self.sub + 1
        self.timer = 0.55 * f
      else
        self.sub = 0
        self.estado = "idle"
        self.timer = 1.1 * f
      end
    end

  elseif a == "brotes" then
    self.brazos = math.min(1, self.brazos + dt * 2)
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      ctx.minion("arana_venenosa", self.x - 36, self.y + 34)
      ctx.minion("arana_venenosa", self.x + 36, self.y + 34)
      if self.fase >= 3 then
        ctx.minion("lobo_sombra", self.x, self.y + 50)
      end
      Juice.explosion(self.x, self.y + 30, VERDE, 1)
      self.timer = 1.3
    elseif self.timer <= 0 then
      self.hecho = false
      self.estado = "idle"
      self.timer = 0.9
    end

  elseif a == "estampida" then
    self.brazos = math.min(1, self.brazos + dt * 3)
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      local base = atan2(uy, ux)
      for l = -1, 1 do
        local ang = base + l * 0.42
        for i = 1, 7 do
          self:agregarZona({
            tipo = "circulo",
            x = self.x + math.cos(ang) * (45 + i * 30),
            y = self.y + math.sin(ang) * (45 + i * 30),
            r = 20, delay = 0.7, retraso = 0.09 * i,
            dano = 2, color = { 0.55, 0.9, 0.25 }, sacudida = 1,
          })
        end
      end
      self.timer = 1.9
    elseif self.timer <= 0 then
      self.hecho = false
      self.estado = "idle"
      self.timer = 0.7
    end
  end
end

function C:dibujarCuerpo(alpha, muerto)
  local x, y = self.x, self.y
  local t = self.anim
  local f = self.fase
  local fl = self.flashDanio > 0
  local function c(r, g, b)
    if fl then love.graphics.setColor(1, 1, 1, alpha) else love.graphics.setColor(r, g, b, alpha) end
  end
  local corr = (f - 1) * 0.5 -- corrupcion

  love.graphics.setColor(0, 0, 0, 0.4 * alpha)
  love.graphics.ellipse("fill", x, y + 26, 34, 10)

  -- raices
  for i = 1, 7 do
    local a = (i - 4) * 0.5
    local w = math.sin(t * 2 + i) * 3
    c(0.22 + corr * 0.15, 0.14, 0.09)
    love.graphics.polygon("fill",
      x + a * 10, y + 14,
      x + a * 30 + w, y + 28,
      x + a * 36 + w, y + 30,
      x + a * 14, y + 20)
  end

  -- brazos (ramas)
  local br = self.brazos
  local sway = math.sin(t * 1.5) * 2
  for lado = -1, 1, 2 do
    c(0.26 + corr * 0.15, 0.17, 0.10)
    love.graphics.setLineWidth(7)
    local hx = x + lado * (34 + br * 10)
    local hy = y + 8 - br * 44 + sway
    love.graphics.line(x + lado * 14, y - 4, x + lado * 26, y - 14 - br * 16, hx, hy)
    love.graphics.setLineWidth(3)
    for k = -1, 1 do
      love.graphics.line(hx, hy, hx + lado * 8, hy - 8 + k * 7)
    end
    love.graphics.setLineWidth(1)
    c(0.34, 0.24, 0.14)
    love.graphics.circle("fill", hx, hy, 5)
  end

  -- tronco
  c(0.30 + corr * 0.2, 0.20, 0.12)
  love.graphics.polygon("fill",
    x - 18, y + 22,
    x - 22, y - 8,
    x - 14, y - 34,
    x + 14, y - 34,
    x + 22, y - 8,
    x + 18, y + 22)
  c(0.40 + corr * 0.2, 0.28, 0.17)
  love.graphics.polygon("fill",
    x - 14, y - 34,
    x - 4, y - 34,
    x - 6, y + 22,
    x - 18, y + 22,
    x - 22, y - 8)
  love.graphics.setColor(0.14, 0.09, 0.05, 0.7 * alpha)
  for i = 1, 4 do
    love.graphics.line(x - 12 + i * 6, y - 28, x - 13 + i * 6, y + 18)
  end

  -- savia brillante
  local g = 0.5 + 0.5 * math.sin(t * 3)
  love.graphics.setColor(0.6 + corr * 0.4, 0.95 - corr * 0.5, 0.25, (0.35 + g * 0.3) * alpha)
  love.graphics.line(x + 6, y - 26, x + 10, y - 8, x + 6, y + 10)

  -- cara
  love.graphics.setColor(0.08, 0.05, 0.03, alpha)
  love.graphics.ellipse("fill", x - 8, y - 16, 5, 6)
  love.graphics.ellipse("fill", x + 8, y - 16, 5, 6)
  local ec = fl and { 1, 1, 1 } or { 1.0, 0.85 - corr * 0.6, 0.2 }
  love.graphics.setColor(ec[1], ec[2], ec[3], alpha)
  love.graphics.circle("fill", x - 8, y - 16, 2.4)
  love.graphics.circle("fill", x + 8, y - 16, 2.4)

  love.graphics.setColor(0.08, 0.05, 0.03, alpha)
  local boca = (self.estado == "ataque") and 6 or 3
  love.graphics.ellipse("fill", x, y - 4, 8, boca)
  love.graphics.setColor(0.85, 0.8, 0.6, alpha)
  for i = -2, 2 do
    love.graphics.polygon("fill",
      x + i * 3 - 1, y - 4 - boca,
      x + i * 3 + 1, y - 4 - boca,
      x + i * 3, y - 1 - boca + 3)
  end

  -- copa
  local cols = {
    { 0.14, 0.38, 0.14 }, { 0.20, 0.46, 0.18 }, { 0.28, 0.55, 0.22 },
  }
  if f == 3 then
    cols = { { 0.45, 0.20, 0.15 }, { 0.55, 0.28, 0.15 }, { 0.65, 0.35, 0.18 } }
  end
  for i = 1, 7 do
    local a = (i / 7) * PI * 2 + math.sin(t + i) * 0.1
    local lx = x + math.cos(a) * 20
    local ly = y - 42 + math.sin(a) * 9
    local cc = cols[(i % 3) + 1]
    c(cc[1], cc[2], cc[3])
    love.graphics.circle("fill", lx, ly, 10)
  end
  c(cols[3][1], cols[3][2], cols[3][3])
  love.graphics.circle("fill", x, y - 48 + math.sin(t * 2) * 1, 12)
end

return C