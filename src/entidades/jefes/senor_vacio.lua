-- Jefe 5: SOBERANO DEL VACIO (Santuario del Vacio) - jefe final, 4 fases
local Base = require("src.entidades.jefes.base")
local Juice = require("src.sistemas.juice")
local atan2 = math.atan2 or math.atan
local PI = math.pi

local C = setmetatable({}, { __index = Base })
C.__index = C

function C.nuevo(x, y, escala)
  local j = Base.crear(C, {
    tipo = "soberano_vacio", nombre = "Soberano del Vacio", subtitulo = "El Portador Final",
    x = x, y = y, hpMax = math.floor(720 * (escala or 1)), radio = 19,
    anchoDibujo = 50, altoDibujo = 66, recompensa = 100, danoContacto = 1,
    umbrales = { 0.75, 0.5, 0.25 }, intro = 2.8,
  })
  j.colorMuerte = { 0.75, 0.4, 1.0 }
  j.colorFase = { 0.7, 0.3, 1.0 }
  j.orbes = {}
  j.alpha = 1
  j.hx, j.hy = x, y
  j.agujero = nil
  return j
end

local VIOLETA = { 0.7, 0.35, 1.0 }

function C:f()
  return (self.fase == 1 and 1) or (self.fase == 2 and 0.9)
      or (self.fase == 3 and 0.78) or 0.66
end

function C:iniciar(n, t)
  self.estado = "ataque"
  self.ataque = n
  self.timer = t
  self.sub = 0
  self.hecho = false
end

function C:elegir(objetivo, enemigos)
  local pool = { "combo", "combo", "orbes", "lluvia" }
  if self.fase >= 2 then pool[#pool + 1] = "agujero" end
  if self.fase >= 3 and self:contarEnemigos(enemigos) < 3 then
    pool[#pool + 1] = "invocar"
  end
  if self.fase >= 4 then
    pool[#pool + 1] = "combo"
    pool[#pool + 1] = "agujero"
  end
  for _ = 1, 4 do
    local a = pool[math.random(#pool)]
    if a ~= self.ultimoAtaque then
      self.ultimoAtaque = a
      return a
    end
  end
  return pool[1]
end

function C:alCambiarFase(nueva, ctx, mapa)
  self.orbes = {}
  self.agujero = nil
  self.alpha = 1
  self.intangible = false
  if nueva == 4 then
    Juice.flash(0.6, 0.2, 1.0, 0.5, 0.7)
  end
end

function C:duranteTransicion()
  if math.random() < 0.7 then
    Juice.chispas(self.x, self.y, 2, VIOLETA, 110, 0.7)
  end
end

function C:lanzarOrbe(ctx, ang, vel)
  ctx.disparar(self.x, self.y, math.cos(ang), math.sin(ang), vel, 1, "orbe_vacio")
end

function C:actualizar(dt, mapa, objetivo, enemigos, ctx)
  local previo = self.agujero
  if not self:tickBase(dt, mapa, objetivo, enemigos, ctx) then
    if self.estado == "intro" then
      self.alpha = 1 - math.max(0, self.timer / 2.8)
    end
    return
  end
  local f = self:f()
  local d, ux, uy = self:distA(objetivo)

  -- orbes orbitando
  for _, o in ipairs(self.orbes) do
    o.ang = o.ang + dt * 3
  end

  if self.estado == "idle" then
    self.alpha = 1
    if d > 120 then
      self:mover(ux, uy, 55 + self.fase * 8, dt, mapa)
    elseif d < 70 then
      self:mover(-ux, -uy, 45, dt, mapa)
    end
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local a = self:elegir(objetivo, enemigos)
      if a == "combo" then self:iniciar(a, 0.3)
      elseif a == "orbes" then self:iniciar(a, 0.2)
      elseif a == "lluvia" then self:iniciar(a, 0.5 * f)
      elseif a == "agujero" then self:iniciar(a, 0.6)
      else self:iniciar(a, 0.9) end
    end
    return
  end

  self.timer = self.timer - dt
  local a = self.ataque

  if a == "combo" then
    -- sub 0: arremeter | 1..n: tajos | final: recuperar
    local golpes = 2 + ((self.fase >= 3) and 1 or 0) + ((self.fase >= 4) and 1 or 0)

    if self.sub == 0 then
      if self.timer <= 0 then
        -- teletransporte corto junto al jugador
        Juice.chispas(self.x, self.y, 10, VIOLETA, 120, 0.4)
        local ang = atan2(uy, ux)
        local tx, ty = objetivo.x - math.cos(ang) * 58, objetivo.y - math.sin(ang) * 58
        local Col = require("src.sistemas.colisiones")
        if not Col.circuloConMapa(tx, ty, self.radio, mapa, true) then
          self.x, self.y = tx, ty
        end
        Juice.chispas(self.x, self.y, 10, VIOLETA, 120, 0.4)
        self.sub = 1
        self.timer = 0.12
      end

    elseif self.sub <= golpes then
      if self.timer <= 0 then
        local ultimo = (self.sub == golpes)
        local dd, vx, vy = self:distA(objetivo)
        local ang = atan2(vy, vx)
        local av = 0.5 * f

        if ultimo then
          self:agregarZona({
            tipo = "linea", x = self.x, y = self.y, ang = ang,
            largo = 150, ancho = 34,
            delay = av + 0.12, dano = 3,
            color = { 0.8, 0.4, 1.0 }, sacudida = 4,
            alExplotar = function(s, z)
              s:mover(math.cos(z.ang), math.sin(z.ang), 600, 0.1, mapa)
            end,
          })
          self.timer = av + 0.12 + 1.0
        else
          self:agregarZona({
            tipo = "cono", x = self.x, y = self.y, ang = ang,
            apertura = math.rad(48), r = 82,
            delay = av, dano = 2,
            color = { 0.8, 0.4, 1.0 }, sacudida = 2.5,
            alExplotar = function(s, z)
              s:mover(math.cos(z.ang), math.sin(z.ang), 500, 0.05, mapa)
            end,
          })
          self.timer = av + 0.15
        end
        self.sub = self.sub + 1
      end

    else
      if self.timer <= 0 then
        self.sub = 0
        self.estado = "idle"
        self.timer = 0.8 * f
      end
    end

  elseif a == "orbes" then
    local n = (self.fase >= 3) and 8 or 6
    if self.sub == 0 then
      if self.timer <= 0 then
        self.orbes = {}
        for i = 1, n do
          self.orbes[i] = { ang = (i - 1) * PI * 2 / n }
        end
        self.sub = 1
        self.timer = 1.0 * f
      end
    elseif self.sub == 1 then
      if self.timer <= 0 then
        self.sub = 2
        self.timer = 0
      end
    elseif self.sub == 2 then
      if self.timer <= 0 then
        local o = table.remove(self.orbes)
        if o then
          local ox = self.x + math.cos(o.ang) * 30
          local oy = self.y + math.sin(o.ang) * 30
          local dx, dy = objetivo.x - ox, objetivo.y - oy
          local m = math.sqrt(dx * dx + dy * dy)
          if m < 0.01 then m = 1 end
          ctx.disparar(ox, oy, dx / m, dy / m, 150 + self.fase * 14, 1, "orbe_vacio")
          self.timer = 0.2 * f
        else
          self.sub = 0
          self.estado = "idle"
          self.timer = 1.0 * f
        end
      end
    end

  elseif a == "lluvia" then
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      local n = 7 + self.fase * 2
      for i = 1, n do
        local px, py
        if i == 1 then
          px, py = objetivo.x, objetivo.y
        else
          px, py = self:puntoEnArena(mapa, 10)
        end
        self:agregarZona({
          tipo = "circulo", x = px, y = py, r = 28,
          delay = 0.95 * f, retraso = 0.16 * (i - 1),
          dano = 2, color = { 0.75, 0.35, 1.0 }, sacudida = 1.5,
          charco = (self.fase >= 3) and { radio = 22, vida = 3.5, dano = 1, tipo = "vacio" } or nil,
        })
      end
      self.timer = 0.95 * f + 0.16 * n + 0.6
    elseif self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.8 * f
    end

  elseif a == "agujero" then
    if self.sub == 0 then
      if self.timer <= 0 then
        self.sub = 1
        self.agujero = { x = self.cx, y = self.cy, t = 0, dur = 3.4, anillo = 0.6 }
        self.timer = 3.4
        Juice.sacudir(3, 0.4)
      end
    elseif self.sub == 1 then
      local h = self.agujero
      h.t = h.t + dt
      -- tira del jugador
      local dx, dy = h.x - objetivo.x, h.y - objetivo.y
      local m = math.sqrt(dx * dx + dy * dy)
      if m > 6 then
        local Col = require("src.sistemas.colisiones")
        local fz = 52 + self.fase * 6
        local nx = objetivo.x + dx / m * fz * dt
        local ny = objetivo.y + dy / m * fz * dt
        if not Col.circuloConMapa(nx, objetivo.y, objetivo.radio, mapa) then
          objetivo.x = nx
        end
        if not Col.circuloConMapa(objetivo.x, ny, objetivo.radio, mapa) then
          objetivo.y = ny
        end
      end
      if m < 24 then
        h.dmgT = (h.dmgT or 0) - dt
        if h.dmgT <= 0 then
          objetivo:recibirDanio(1)
          h.dmgT = 0.5
        end
      end
      h.anillo = h.anillo - dt
      if h.anillo <= 0 then
        h.anillo = 0.9
        local n = 10
        local base = math.random() * PI * 2
        for i = 1, n do
          local ang = base + i * PI * 2 / n
          ctx.disparar(h.x, h.y, math.cos(ang), math.sin(ang), 80, 1, "orbe_vacio")
        end
      end
      if self.timer <= 0 then
        self:agregarZona({
          tipo = "circulo", x = h.x, y = h.y, r = 85,
          delay = 0.7, dano = 3,
          color = { 0.75, 0.3, 1.0 }, sacudida = 6,
        })
        self.agujero = nil
        self.sub = 2
        self.timer = 1.6
      end
    else
      if self.timer <= 0 then
        self.sub = 0
        self.estado = "idle"
        self.timer = 0.9 * f
      end
    end

  elseif a == "invocar" then
    if self.timer <= 0 and not self.hecho then
      self.hecho = true
      ctx.minion("acechador_vacio", self.x - 50, self.y + 30)
      ctx.minion("acechador_vacio", self.x + 50, self.y + 30)
      if self.fase >= 4 then
        ctx.minion("ojo_del_vacio", self.x, self.y - 50)
      end
      Juice.explosion(self.x, self.y, VIOLETA, 1.4)
      self.timer = 1.2
    elseif self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.9
    end
  end
end

function C:dibujarFrente()
  if self.agujero then
    local h = self.agujero
    local t = h.t
    for i = 1, 4 do
      local r = 40 - ((t * 20 + i * 10) % 40)
      love.graphics.setColor(0.7, 0.3, 1.0, 0.25 * (1 - r / 40))
      love.graphics.circle("line", h.x, h.y, r + 10)
    end
    love.graphics.setColor(0.45, 0.15, 0.75, 0.35)
    love.graphics.circle("fill", h.x, h.y, 28)
    love.graphics.setColor(0.02, 0.0, 0.05)
    love.graphics.circle("fill", h.x, h.y, 17)
    love.graphics.setColor(0.8, 0.5, 1.0, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", h.x, h.y, 17)
    love.graphics.setLineWidth(1)
  end

  for _, o in ipairs(self.orbes) do
    local ox = self.x + math.cos(o.ang) * 30
    local oy = self.y + math.sin(o.ang) * 30
    love.graphics.setColor(0.4, 0.1, 0.65, 0.35)
    love.graphics.circle("fill", ox, oy, 10)
    love.graphics.setColor(0.08, 0.02, 0.14)
    love.graphics.circle("fill", ox, oy, 6)
    love.graphics.setColor(0.8, 0.5, 1.0)
    love.graphics.circle("line", ox, oy, 6.5)
  end
end

function C:dibujarCuerpo(alpha, muerto)
  local al = alpha * (self.alpha or 1)
  local t = self.anim
  local x = self.x
  local y = self.y - 4 + math.sin(t * 2) * 2
  local fl = self.flashDanio > 0
  local rabia = (self.fase - 1) / 3
  local function c(r, g, b, a)
    if fl then
      love.graphics.setColor(1, 1, 1, al)
    else
      love.graphics.setColor(r, g, b, (a or 1) * al)
    end
  end

  love.graphics.setColor(0, 0, 0, 0.35 * al)
  love.graphics.ellipse("fill", self.x, self.y + 26, 20, 6)

  -- aura
  love.graphics.setColor(0.5 + rabia * 0.3, 0.15, 0.9, (0.12 + 0.06 * math.sin(t * 4)) * al)
  love.graphics.circle("fill", x, y, 40 + rabia * 8)

  -- fragmentos orbitando
  for i = 1, 5 do
    local a = t * 1.2 + i * PI * 2 / 5
    local fx, fy = x + math.cos(a) * 36, y + math.sin(a) * 18 - 4
    love.graphics.setColor(0.7, 0.35, 1.0, 0.85 * al)
    love.graphics.polygon("fill", fx, fy - 4, fx + 3, fy, fx, fy + 4, fx - 3, fy)
  end

  -- capa
  local ond = math.sin(t * 3) * 3
  c(0.14, 0.06, 0.24)
  love.graphics.polygon("fill",
    x - 12, y - 14,
    x + 12, y - 14,
    x + 22 + ond, y + 28,
    x + 10, y + 22,
    x, y + 30,
    x - 10, y + 22,
    x - 22 - ond, y + 28)
  c(0.28, 0.12, 0.42)
  love.graphics.polygon("fill",
    x - 12, y - 14,
    x, y - 14,
    x - 2, y + 28,
    x - 16, y + 26)

  -- armadura
  c(0.25, 0.22, 0.36)
  love.graphics.polygon("fill",
    x - 11, y - 14,
    x + 11, y - 14,
    x + 9, y + 10,
    x - 9, y + 10)
  c(0.40, 0.36, 0.56)
  love.graphics.polygon("fill",
    x - 11, y - 14,
    x - 2, y - 14,
    x - 3, y + 10,
    x - 9, y + 10)

  local g = 0.5 + 0.5 * math.sin(t * 4)
  love.graphics.setColor(0.8, 0.4, 1.0, (0.6 + g * 0.4) * al)
  love.graphics.circle("fill", x, y - 3, 3.5 + g)
  love.graphics.setColor(1, 0.9, 1.0, al)
  love.graphics.circle("fill", x, y - 3, 1.5)

  -- hombreras
  c(0.35, 0.30, 0.50)
  love.graphics.polygon("fill", x - 18, y - 14, x - 8, y - 18, x - 8, y - 8)
  love.graphics.polygon("fill", x + 18, y - 14, x + 8, y - 18, x + 8, y - 8)

  -- yelmo
  c(0.28, 0.24, 0.40)
  love.graphics.circle("fill", x, y - 24, 9)
  love.graphics.setColor(0.04, 0.01, 0.08, al)
  love.graphics.rectangle("fill", x - 6, y - 26, 12, 4)
  love.graphics.setColor(0.9, 0.55, 1.0, al)
  love.graphics.rectangle("fill", x - 5, y - 25, 3, 2)
  love.graphics.rectangle("fill", x + 2, y - 25, 3, 2)

  -- cuernos
  c(0.20, 0.14, 0.30)
  love.graphics.polygon("fill", x - 8, y - 29, x - 16, y - 44, x - 4, y - 32)
  love.graphics.polygon("fill", x + 8, y - 29, x + 16, y - 44, x + 4, y - 32)
  love.graphics.setColor(0.8, 0.45, 1.0, (0.5 + g * 0.4) * al)
  love.graphics.polygon("fill", x - 2, y - 32, x, y - 42 - rabia * 5, x + 2, y - 32)

  -- espada
  local ang = atan2(self.mirandoY, self.mirandoX)
  local alza = 0.35 + math.sin(t * 2) * 0.1
  if self.estado == "ataque" and self.ataque == "combo" then alza = -0.9 end
  love.graphics.push()
  love.graphics.translate(x, y - 2)
  love.graphics.rotate(ang + alza)
  love.graphics.setColor(0.75, 0.4, 1.0, 0.35 * al)
  love.graphics.rectangle("fill", 8, -4, 40, 8)
  love.graphics.setColor(0.18, 0.08, 0.28, al)
  love.graphics.rectangle("fill", 8, -2, 38, 4)
  love.graphics.setColor(0.9, 0.7, 1.0, al)
  love.graphics.rectangle("fill", 10, -1, 34, 1.4)
  love.graphics.setColor(0.35, 0.2, 0.5, al)
  love.graphics.rectangle("fill", 5, -4, 4, 8)
  love.graphics.pop()
end

return C