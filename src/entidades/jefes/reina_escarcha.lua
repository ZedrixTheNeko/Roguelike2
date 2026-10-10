-- Jefe 4: REINA DE ESCARCHA (Glaciar Eterno)
local Base = require("src.entidades.jefes.base")
local Juice = require("src.sistemas.juice")
local atan2 = math.atan2 or math.atan
local PI = math.pi

local C = setmetatable({}, { __index = Base })
C.__index = C

function C.nuevo(x, y, escala)
  local j = Base.crear(C, {
    tipo = "reina_escarcha", nombre = "Reina de Escarcha", subtitulo = "La Dama del Glaciar Eterno",
    x = x, y = y, hpMax = math.floor(500 * (escala or 1)), radio = 18,
    anchoDibujo = 44, altoDibujo = 64, recompensa = 60, danoContacto = 1,
  })
  j.colorMuerte = { 0.6, 0.9, 1.0 }
  j.colorFase = { 0.5, 0.85, 1.0 }
  j.alpha = 1
  j.angVentisca = 0
  return j
end

local HIELO = { 0.55, 0.85, 1.0 }

function C:f() return (self.fase == 1 and 1) or (self.fase == 2 and 0.85) or 0.72 end

function C:iniciar(n, t)
  self.estado = "ataque"
  self.ataque = n
  self.timer = t
  self.sub = 0
  self.hecho = false
end

function C:elegir(objetivo, enemigos)
  local pool = { "ventisca", "lanza", "prision", "teleport" }
  if self.fase >= 2 then pool[#pool + 1] = "nova" end
  if self.fase >= 3 then pool[#pool + 1] = "nova"; pool[#pool + 1] = "ventisca" end
  for _ = 1, 4 do
    local a = pool[math.random(#pool)]
    if a ~= self.ultimoAtaque then self.ultimoAtaque = a; return a end
  end
  return pool[1]
end

function C:alCambiarFase(nueva, ctx)
  if nueva == 2 then
    ctx.minion("cristal_helado", self.x - 70, self.y + 20)
    ctx.minion("cristal_helado", self.x + 70, self.y + 20)
  end
  self.intangible = false
  self.alpha = 1
end

function C:duranteTransicion()
  if math.random() < 0.6 then
    Juice.chispas(self.x, self.y - 10, 1, HIELO, 80, 0.7)
  end
end

function C:actualizar(dt, mapa, objetivo, enemigos, ctx)
  if not self:tickBase(dt, mapa, objetivo, enemigos, ctx) then return end
  local f = self:f()
  local d, ux, uy = self:distA(objetivo)

  if self.estado == "idle" then
    self.alpha = 1
    -- mantiene distancia
    if d < 130 then self:mover(-ux, -uy, 55, dt, mapa)
    elseif d > 230 then self:mover(ux, uy, 45, dt, mapa)
    else self:mover(-uy, ux, 25, dt, mapa) end
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local a = self:elegir(objetivo, enemigos)
      if a == "ventisca" then self:iniciar(a, 0.6 * f)
      elseif a == "lanza" then self:iniciar(a, 0.2)
      elseif a == "prision" then self:iniciar(a, 0.3)
      elseif a == "teleport" then self:iniciar(a, 0.45)
      else self:iniciar(a, 0.7 * f) end
    end
    return
  end

  self.timer = self.timer - dt
  local a = self.ataque

  if a == "ventisca" then
    if self.timer <= 0 then
      if self.sub == 0 then
        self.sub = 1
        self.dur = 2.4
        self.cad = 0
      end
      self.dur = self.dur - dt
      self.cad = self.cad - dt
      if self.cad <= 0 and self.dur > 0 then
        self.cad = 0.13 * f
        local brazos = 2 + self.fase
        local dir = (self.fase == 3 and self.dur < 1.2) and -1 or 1
        self.angVentisca = self.angVentisca + 0.33 * dir
        for i = 1, brazos do
          local ang = self.angVentisca + (i - 1) * PI * 2 / brazos
          ctx.disparar(self.x, self.y, math.cos(ang), math.sin(ang), 112, 1, "esquirla_hielo")
        end
      end
      if self.dur <= 0 then
        self.sub = 0
        self.estado = "idle"
        self.timer = 1.0 * f
      end
    end

  elseif a == "lanza" then
    if self.sub == 0 then
      self.sub = 1
      local base = atan2(uy, ux)
      local n = (self.fase == 1 and 1) or (self.fase == 2 and 3 or 5)
      for i = 1, n do
        local off = (i - (n + 1) / 2) * 0.32
        self:agregarZona({
          tipo = "linea", x = self.x, y = self.y,
          ang = base + off, largo = 430, ancho = 20,
          delay = 0.85 * f, dano = 2, slow = 2,
          color = { 0.5, 0.85, 1.0 }, sacudida = 2,
        })
      end
      self.timer = 0.85 * f + 0.8
    elseif self.timer <= 0 then
      self.sub = 0
      self.estado = "idle"
      self.timer = 0.9 * f
    end

  elseif a == "prision" then
    if self.sub == 0 then
      self.sub = 1
      local n = (self.fase >= 3) and 2 or 1
      for i = 1, n do
        local px, py = objetivo.x, objetivo.y
        if i == 2 then
          local ang = math.random() * PI * 2
          px, py = px + math.cos(ang) * 60, py + math.sin(ang) * 60
        end
        self:agregarZona({
          tipo = "circulo", x = px, y = py, r = 52,
          delay = 1.15 * f, retraso = 0.25 * (i - 1),
          dano = 1, slow = 3,
          color = { 0.6, 0.9, 1.0 }, sacudida = 2,
          charco = { radio = 40, vida = 4, dano = 0, slow = 1.5, tipo = "hielo" },
        })
      end
      self.timer = 1.4 * f + 0.7
    elseif self.timer <= 0 then
      self.sub = 0
      self.estado = "idle"
      self.timer = 0.8 * f
    end

  elseif a == "teleport" then
    if self.sub == 0 then
      -- desvanecerse y dejar estalagmitas
      self.alpha = math.max(0, self.timer / 0.45)
      if self.timer <= 0 then
        self:agregarZona({
          tipo = "circulo", x = self.x, y = self.y, r = 46,
          delay = 0.9 * f, dano = 2,
          color = { 0.6, 0.9, 1.0 }, sacudida = 2,
        })
        Juice.explosion(self.x, self.y, HIELO, 1.2)
        local px, py
        for _ = 1, 12 do
          px, py = self:puntoEnArena(mapa, 20)
          local dx, dy = px - objetivo.x, py - objetivo.y
          if math.sqrt(dx * dx + dy * dy) > 130 then break end
        end
        self.x, self.y = px, py
        self.sub = 1
        self.timer = 0.4
        self.intangible = true
      end
    elseif self.sub == 1 then
      self.alpha = 1 - math.max(0, self.timer / 0.4)
      if self.timer <= 0 then
        self.alpha = 1
        self.intangible = false
        self:agregarZona({
          tipo = "circulo", x = self.x, y = self.y, r = 38,
          delay = 0.7 * f, dano = 1,
          color = { 0.6, 0.9, 1.0 }, sacudida = 1.5,
        })
        self.sub = 2
        self.timer = 0.5
      end
    elseif self.timer <= 0 then
      self.sub = 0
      -- ataque inmediato tras teletransportarse
      local sig = (math.random() < 0.5) and "lanza" or "ventisca"
      if sig == "lanza" then
        self:iniciar("lanza", 0.2)
      else
        self:iniciar("ventisca", 0.3)
      end
    end

  elseif a == "nova" then
    if self.timer <= 0 then
      if self.sub < 2 then
        local n = 28
        local huecos = 3
        local base = math.random() * PI * 2 + self.sub * (PI / huecos)
        for i = 0, n - 1 do
          local ang = base + i * PI * 2 / n
          -- 3 huecos de seguridad
          local pos = (i / n) * huecos
          local frac = pos - math.floor(pos)
          if not (frac < 0.22) then
            ctx.disparar(self.x, self.y, math.cos(ang), math.sin(ang), 105, 1, "esquirla_hielo")
          end
        end
        Juice.anillo(self.x, self.y, 60, HIELO, 0.5)
        Juice.sacudir(2, 0.2)
        self.sub = self.sub + 1
        self.timer = 0.8 * f
      else
        self.sub = 0
        self.estado = "idle"
        self.timer = 1.2 * f
      end
    end
  end
end

function C:dibujarCuerpo(alpha, muerto)
  local al = alpha * (self.alpha or 1)
  local t = self.anim
  local x = self.x
  local flot = math.sin(t * 2) * 3
  local y = self.y + flot - 8
  local fl = self.flashDanio > 0
  local function c(r, g, b, a)
    if fl then
      love.graphics.setColor(1, 1, 1, al)
    else
      love.graphics.setColor(r, g, b, (a or 1) * al)
    end
  end

  love.graphics.setColor(0, 0, 0, 0.3 * al)
  love.graphics.ellipse("fill", self.x, self.y + 24, 18 - flot, 5)

  -- aura
  love.graphics.setColor(0.5, 0.85, 1.0, (0.10 + 0.05 * math.sin(t * 3)) * al)
  love.graphics.circle("fill", x, y, 36)
  love.graphics.setColor(0.8, 0.95, 1.0, 0.5 * al)
  for i = 1, 6 do
    local a = t * 0.8 + i * PI / 3
    local rx, ry = x + math.cos(a) * 32, y + math.sin(a) * 32
    love.graphics.line(rx - 3, ry, rx + 3, ry)
    love.graphics.line(rx, ry - 3, rx, ry + 3)
  end

  -- vestido
  local ond = math.sin(t * 3) * 3
  c(0.40, 0.65, 0.90, 0.95)
  love.graphics.polygon("fill",
    x - 8, y - 8,
    x + 8, y - 8,
    x + 18 + ond, y + 28,
    x + 8, y + 22,
    x, y + 30,
    x - 8, y + 22,
    x - 18 - ond, y + 28)
  c(0.75, 0.92, 1.0, 0.9)
  love.graphics.polygon("fill",
    x - 8, y - 8,
    x, y - 8,
    x - 1, y + 28,
    x - 12, y + 26)
  c(0.25, 0.45, 0.75)
  love.graphics.polygon("fill",
    x - 9, y - 8,
    x + 9, y - 8,
    x + 6, y + 2,
    x - 6, y + 2)

  -- cabello
  c(0.88, 0.96, 1.0)
  love.graphics.polygon("fill",
    x - 8, y - 20,
    x + 8, y - 20,
    x + 11, y + 10 + ond,
    x + 7, y - 6,
    x - 7, y - 6,
    x - 11, y + 10 - ond)

  -- cara
  c(0.90, 0.95, 1.0)
  love.graphics.circle("fill", x, y - 16, 7)
  love.graphics.setColor(0.2, 0.5, 0.9, al)
  love.graphics.circle("fill", x - 2.5, y - 16, 1.2)
  love.graphics.circle("fill", x + 2.5, y - 16, 1.2)
  love.graphics.setColor(0.5, 0.2, 0.5, al)
  love.graphics.line(x - 1.5, y - 12, x + 1.5, y - 12)

  -- corona de cristales
  for i = -2, 2 do
    local h = 9 - math.abs(i) * 2
    c(0.7, 0.93, 1.0)
    love.graphics.polygon("fill",
      x + i * 3.5 - 2, y - 21,
      x + i * 3.5, y - 21 - h,
      x + i * 3.5 + 2, y - 21)
  end

  -- baculo
  local bx = x + 22
  love.graphics.setColor(0.7, 0.85, 0.95, al)
  love.graphics.setLineWidth(2)
  love.graphics.line(bx, y - 22, bx - 2, y + 24)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.6, 0.9, 1.0, al)
  love.graphics.polygon("fill",
    bx - 4, y - 24,
    bx, y - 36,
    bx + 4, y - 24,
    bx, y - 20)
  love.graphics.setColor(1, 1, 1, (0.5 + 0.4 * math.sin(t * 6)) * al)
  love.graphics.circle("fill", bx, y - 27, 2)

  -- brazo
  c(0.40, 0.65, 0.90)
  love.graphics.line(x + 8, y - 4, bx - 1, y - 8)
end

return C