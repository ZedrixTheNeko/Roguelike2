-- Jefe 3: COLOSO DE MAGMA (Forja de Magma)
local Base = require("src.entidades.jefes.base")
local Juice = require("src.sistemas.juice")
local atan2 = math.atan2 or math.atan
local PI = math.pi

local C = setmetatable({}, { __index = Base })
C.__index = C

function C.nuevo(x, y, escala)
  local j = Base.crear(C, {
    tipo = "coloso_magma", nombre = "Coloso de Magma", subtitulo = "El Corazon de la Forja",
    x = x, y = y, hpMax = math.floor(560 * (escala or 1)), radio = 27,
    anchoDibujo = 70, altoDibujo = 76, recompensa = 50, danoContacto = 2, reduccionDanio = 0.2,
  })
  j.colorMuerte = { 1.0, 0.55, 0.15 }
  j.colorFase = { 1.0, 0.45, 0.1 }
  j.brazos = 0
  j.recienCarga = 0
  return j
end

function C:f() return (self.fase == 1 and 1) or (self.fase == 2 and 0.85) or 0.72 end

function C:iniciar(n, t)
  self.estado = "ataque"
  self.ataque = n
  self.timer = t
  self.sub = 0
  self.hecho = false
end

function C:elegir(objetivo)
  local d = self:distA(objetivo)
  local pool = {}
  if d < 120 then
    pool = { "golpe", "golpe", "golpe", "erupcion", "rocas" }
  elseif d < 210 then
    pool = { "rocas", "erupcion", "golpe", "carga" }
  else
    pool = { "rocas", "carga", "carga", "erupcion" }
  end
  if self.recienCarga > 0 then
    local p2 = {}
    for _, a in ipairs(pool) do
      if a ~= "carga" then p2[#p2 + 1] = a end
    end
    pool = p2
  end
  for _ = 1, 4 do
    local a = pool[math.random(#pool)]
    if a ~= self.ultimoAtaque then self.ultimoAtaque = a; return a end
  end
  return pool[1]
end

function C:alCambiarFase(nueva, ctx, mapa)
  self.brazos = 1
  self.danoContacto = 2
  self.reduccionDanio = (nueva == 3) and 0.1 or 0.2
  for _ = 1, nueva do
    local px, py = self:puntoEnArena(mapa, 30)
    self.charcos[#self.charcos + 1] = {
      x = px, y = py, radio = 24, vida = 7, dano = 1, tipo = "lava",
    }
  end
end

function C:duranteTransicion()
  if math.random() < 0.5 then
    Juice.chispas(self.x + (math.random() - 0.5) * 40, self.y - 10, 1, { 1, 0.6, 0.2 }, 70, 0.6)
  end
end

function C:actualizar(dt, mapa, objetivo, enemigos, ctx)
  if not self:tickBase(dt, mapa, objetivo, enemigos, ctx) then
    self.brazos = math.max(0, self.brazos - dt)
    return
  end
  if self.recienCarga > 0 then self.recienCarga = self.recienCarga - dt end
  local f = self:f()
  local d, ux, uy = self:distA(objetivo)

  if self.estado == "idle" then
    self.brazos = math.max(0, self.brazos - dt * 2)
    self.danoContacto = 2
    if d > 60 then self:mover(ux, uy, 34 + self.fase * 8, dt, mapa) end
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local a = self:elegir(objetivo)
      if a == "golpe" then self:iniciar(a, 0.85 * f)
      elseif a == "rocas" then self:iniciar(a, 0.7 * f)
      elseif a == "carga" then self:iniciar(a, 0.1)
      else self:iniciar(a, 0.6 * f) end
    end
    return
  end

  if self.estado == "aturdido" then
    self.timer = self.timer - dt
    self.danoContacto = 1
    if math.random() < 0.3 then
      Juice.chispas(self.x, self.y - 30, 1, { 1, 0.9, 0.3 }, 30, 0.5)
    end
    if self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.6
      self.reduccionDanio = (self.fase == 3) and 0.1 or 0.2
      self.multDanioRecibido = nil
    end
    return
  end

  self.timer = self.timer - dt
  local a = self.ataque

  if a == "golpe" then
    self.brazos = math.min(1, self.brazos + dt * 2.5)
    if self.sub == 0 then
      self.sub = 1
      self:agregarZona({
        tipo = "circulo", x = self.x, y = self.y + 6, r = 74,
        delay = 0.85 * f, dano = 3,
        color = { 1.0, 0.45, 0.1 }, sacudida = 5,
        alExplotar = function(s, z, ctx2)
          if s.fase >= 2 then
            local n = (s.fase == 3) and 12 or 8
            for i = 1, n do
              local ang = (i - 1) * PI * 2 / n + math.random() * 0.2
              ctx2.disparar(z.x, z.y, math.cos(ang), math.sin(ang), 110, 1, "bola_fuego")
            end
          end
          s.brazos = 0
        end,
      })
      self.timer = 0.85 * f + 0.9
    end
    if self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.8 * f
    end

  elseif a == "rocas" then
    self.brazos = math.min(1, self.brazos + dt * 3)
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      local n = 2 + self.fase * 2
      for i = 1, n do
        local px, py
        if i == 1 then
          px, py = objetivo.x, objetivo.y
        else
          local ang = math.random() * PI * 2
          local r = 30 + math.random() * 70
          px, py = objetivo.x + math.cos(ang) * r, objetivo.y + math.sin(ang) * r
        end
        self:agregarZona({
          tipo = "circulo", x = px, y = py, r = 26,
          delay = 1.0 * f, retraso = 0.14 * (i - 1),
          dano = 2, color = { 1.0, 0.55, 0.15 }, sacudida = 2,
          charco = (self.fase >= 2) and { radio = 24, vida = 5, dano = 1, tipo = "lava" } or nil,
        })
      end
      self.timer = 1.0 * f + 0.14 * n + 0.8
    elseif self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.8 * f
    end

  elseif a == "erupcion" then
    self.brazos = math.min(1, self.brazos + dt * 3)
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      local base = atan2(uy, ux)
      local filas = (self.fase == 3) and { -0.3, 0, 0.3 } or { 0 }
      for _, off in ipairs(filas) do
        for i = 1, 7 do
          self:agregarZona({
            tipo = "circulo",
            x = self.x + math.cos(base + off) * (40 + i * 32),
            y = self.y + math.sin(base + off) * (40 + i * 32),
            r = 24, delay = 0.7, retraso = 0.12 * i,
            dano = 2, color = { 1.0, 0.4, 0.1 }, sacudida = 1.5,
          })
        end
      end
      self.timer = 1.9
    elseif self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.7
    end

  elseif a == "carga" then
    if self.sub == 0 then
      self.sub = 1
      self.cdx, self.cdy = ux, uy
      self:agregarZona({
        tipo = "linea", x = self.x, y = self.y,
        ang = atan2(uy, ux), largo = 300, ancho = 46,
        delay = 0.95 * f, dano = 0, soloAviso = true,
        color = { 1.0, 0.3, 0.1 }, post = 0.1,
      })
      self.timer = 0.95 * f
      self.brazos = 0.5
    elseif self.sub == 1 then
      if self.timer <= 0 then
        self.sub = 2
        self.timer = 0.85
        self.danoContacto = 3
        Juice.sacudir(2, 0.3)
      end
    elseif self.sub == 2 then
      local bx, by = self:mover(self.cdx, self.cdy, 330, dt, mapa)
      if math.random() < 0.6 then
        Juice.humo(self.x, self.y + 14, 1, { 1.0, 0.5, 0.2 }, 0.4)
      end
      if bx or by then
        self.estado = "aturdido"
        self.timer = 2.6
        self.reduccionDanio = 0
        self.multDanioRecibido = 1.5
        self.recienCarga = 6
        self.danoContacto = 1
        Juice.sacudir(7, 0.5)
        Juice.explosion(self.x + self.cdx * 24, self.y + self.cdy * 24, { 1, 0.6, 0.2 }, 1.6)
        ctx.minion("espiritu_fuego", self.x - self.cdx * 40 + 20, self.y - self.cdy * 40)
      elseif self.timer <= 0 then
        self.sub = 3
        self.timer = 1.0
        self.danoContacto = 2
      end
    elseif self.sub == 3 then
      if self.timer <= 0 then
        self.estado = "idle"
        self.timer = 0.6
      end
    end
  end
end

function C:dibujarCuerpo(alpha, muerto)
  local x, y = self.x, self.y
  local t = self.anim
  local fl = self.flashDanio > 0
  local function c(r, g, b)
    if fl then love.graphics.setColor(1, 1, 1, alpha) else love.graphics.setColor(r, g, b, alpha) end
  end
  local br = self.brazos
  local paso = (self.estado == "idle") and math.sin(t * 4) * 2 or 0
  local rabia = (self.fase - 1) * 0.5

  love.graphics.setColor(0, 0, 0, 0.45 * alpha)
  love.graphics.ellipse("fill", x, y + 28, 38, 11)

  -- piernas
  c(0.20, 0.13, 0.12)
  love.graphics.rectangle("fill", x - 18, y + 8 + paso, 14, 20, 3)
  love.graphics.rectangle("fill", x + 4, y + 8 - paso, 14, 20, 3)

  -- brazos
  local alza = br * 30
  for lado = -1, 1, 2 do
    c(0.28, 0.18, 0.16)
    love.graphics.polygon("fill",
      x + lado * 22, y - 20,
      x + lado * 36, y - 14 - alza,
      x + lado * 40, y + 12 - alza,
      x + lado * 26, y + 14 - alza * 0.6)
    c(0.38, 0.25, 0.22)
    love.graphics.circle("fill", x + lado * 36, y + 14 - alza, 10)
    love.graphics.setColor(1, 0.5, 0.1, (0.4 + 0.3 * math.sin(t * 4)) * alpha)
    love.graphics.circle("fill", x + lado * 36, y + 14 - alza, 5)
  end

  -- torso
  c(0.26, 0.17, 0.15)
  love.graphics.polygon("fill",
    x - 24, y + 12,
    x - 28, y - 22,
    x - 12, y - 36,
    x + 12, y - 36,
    x + 28, y - 22,
    x + 24, y + 12)
  c(0.37, 0.25, 0.22)
  love.graphics.polygon("fill",
    x - 28, y - 22,
    x - 12, y - 36,
    x - 4, y - 36,
    x - 8, y + 12,
    x - 24, y + 12)

  -- nucleo
  local g = 0.6 + 0.4 * math.sin(t * 3)
  love.graphics.setColor(1, 0.4 + rabia * 0.2, 0.08, (0.35 + g * 0.25) * alpha)
  love.graphics.circle("fill", x, y - 8, 15 + g * 3)
  love.graphics.setColor(1, 0.65, 0.15, alpha)
  love.graphics.circle("fill", x, y - 8, 9)
  love.graphics.setColor(1, 0.95, 0.6, alpha)
  love.graphics.circle("fill", x, y - 8, 4)

  love.graphics.setColor(1, 0.45, 0.1, (0.6 + 0.3 * g) * alpha)
  love.graphics.setLineWidth(2)
  love.graphics.line(x - 16, y - 28, x - 10, y - 16, x - 18, y - 6, x - 12, y + 6)
  love.graphics.line(x + 18, y - 26, x + 10, y - 14, x + 16, y - 2)
  love.graphics.setLineWidth(1)

  -- cabeza
  c(0.30, 0.20, 0.18)
  love.graphics.rectangle("fill", x - 11, y - 52, 22, 17, 3)
  local ojo = self.estado == "aturdido" and { 0.4, 0.4, 0.4 } or { 1, 0.75 - rabia * 0.4, 0.15 }
  love.graphics.setColor(ojo[1], ojo[2], ojo[3], alpha)
  love.graphics.rectangle("fill", x - 8, y - 46, 5, 4)
  love.graphics.rectangle("fill", x + 3, y - 46, 5, 4)

  -- cuernos / corona de fuego
  love.graphics.setColor(0.22, 0.14, 0.12, alpha)
  love.graphics.polygon("fill", x - 11, y - 50, x - 16, y - 62, x - 6, y - 52)
  love.graphics.polygon("fill", x + 11, y - 50, x + 16, y - 62, x + 6, y - 52)

  if self.fase >= 2 then
    for i = -2, 2 do
      local h = 8 + math.sin(t * 9 + i) * 3
      love.graphics.setColor(1, 0.5, 0.1, 0.8 * alpha)
      love.graphics.polygon("fill",
        x + i * 5 - 3, y - 52,
        x + i * 5, y - 52 - h,
        x + i * 5 + 3, y - 52)
    end
  end

  if self.estado == "aturdido" then
    for i = 1, 3 do
      local a = t * 4 + i * 2.1
      love.graphics.setColor(1, 0.9, 0.3, alpha)
      love.graphics.circle("fill", x + math.cos(a) * 14, y - 62 + math.sin(a) * 4, 2.2)
    end
  end
end

return C