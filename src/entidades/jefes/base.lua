-- ============================================================
-- BASE DE JEFES
-- Da a cada jefe: fases, intro, zonas telegrafiadas (circulo, linea,
-- cono), charcos persistentes, movimiento con paredes, muerte.
-- La interfaz publica es la misma que la del Rey Slime:
--   x, y, radio, vivo, hp, hpMax, charcos, recibirDanio, colisiona,
--   actualizar(dt, mapa, objetivo, enemigos, ctx), dibujar()
-- ============================================================
local Colisiones = require("src.sistemas.colisiones")
local Juice      = require("src.sistemas.juice")
local Sangre     = require("src.sistemas.sangre")

local atan2 = math.atan2 or math.atan
local PI = math.pi

local B = {}
B.__index = B

-- Crea la instancia base de una clase de jefe
function B.crear(clase, def)
  local j = setmetatable({}, clase)
  j.tipo = def.tipo
  j.nombre = def.nombre
  j.subtitulo = def.subtitulo or ""
  j.x, j.y = def.x, def.y
  j.cx, j.cy = def.x, def.y          -- centro de la arena
  j.hpMax = def.hpMax
  j.hp = def.hpMax
  j.radio = def.radio
  j.anchoDibujo = def.anchoDibujo or def.radio * 2
  j.altoDibujo = def.altoDibujo or def.radio * 2
  j.vivo = true
  j.flashDanio = 0
  j.estado = "intro"
  j.timer = def.intro or 2.2
  j.fase = 1
  j.umbrales = def.umbrales or { 0.66, 0.33 }
  j.charcos = {}
  j.zonas = {}
  j.anim = 0
  j.mirandoX, j.mirandoY = 0, 1
  j.z = 0
  j.reduccionDanio = def.reduccionDanio or 0
  j.invulnerableT = 0
  j.danoContacto = def.danoContacto or 1
  j.recompensa = def.recompensa or 30
  j.barraSuperior = true
  j.bannerHecho = false
  j.ultimoAtaque = nil
  j.cooldownGlobal = 0
  return j
end

-- ------------------------------------------------------------
-- DANO
-- ------------------------------------------------------------
function B:recibirDanio(cantidad)
  if not self.vivo then return false end
  if self.invulnerableT > 0 or self.estado == "intro" then return false end
  if self.reduccionDanio and self.reduccionDanio > 0 then
    cantidad = cantidad * (1 - self.reduccionDanio)
  end
  if self.multDanioRecibido then cantidad = cantidad * self.multDanioRecibido end
  self.hp = self.hp - cantidad
  self.flashDanio = 0.10
  Juice.registrarDanio(self, cantidad)
  if self.hp > 0 then pcall(Sangre.herida, self, cantidad * 0.7) end
  if self.hp <= 0 then
    self.hp = 0
    self.vivo = false
    self.tMuerte = love.timer.getTime()
    Juice.golpe(0.22)
    Juice.sacudir(8, 1.0)
    Juice.flash(1, 1, 1, 0.7, 0.5)
    pcall(Sangre.muerte, self, 2.8)
    for _ = 1, 5 do
      Juice.explosion(self.x + (math.random() - 0.5) * self.radio * 2,
                      self.y + (math.random() - 0.5) * self.radio * 2,
                      self.colorMuerte or { 1, 0.8, 0.4 }, 1.4)
    end
    return true
  end
  return false
end

function B:colisiona(x, y, r)
  if not self.vivo then return false end
  if self.z > 20 or self.sinContacto then return false end
  local dx = self.x - x
  local dy = self.y - y
  local rr = self.radio + r
  return dx * dx + dy * dy < rr * rr
end

-- ------------------------------------------------------------
-- UTILIDADES DE MOVIMIENTO Y ARENA
-- ------------------------------------------------------------
function B:mover(mx, my, vel, dt, mapa)
  local bx, by = false, false
  local nx = self.x + mx * vel * dt
  if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa, true) then self.x = nx else bx = true end
  local ny = self.y + my * vel * dt
  if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa, true) then self.y = ny else by = true end
  return bx, by
end

function B:arena(mapa)
  local offX = mapa.offX or 0
  local offY = mapa.offY or 0
  local W = #mapa[1]
  local H = #mapa
  return offX + 40, offY + 40, offX + W * 16 - 40, offY + H * 16 - 40
end

function B:puntoEnArena(mapa, margen)
  local x0, y0, x1, y1 = self:arena(mapa)
  margen = margen or 0
  return x0 + margen + math.random() * (x1 - x0 - margen * 2),
         y0 + margen + math.random() * (y1 - y0 - margen * 2)
end

function B:distA(o)
  local dx, dy = o.x - self.x, o.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 0.001 then d = 0.001 end
  return d, dx / d, dy / d
end

function B:contarEnemigos(enemigos)
  local n = 0
  for _, e in ipairs(enemigos) do if e.vivo then n = n + 1 end end
  return n
end

-- ------------------------------------------------------------
-- ZONAS TELEGRAFIADAS
--   z = { tipo, x, y, r|largo, ang, apertura, ancho, delay, post,
--         dano, slow, color, retraso, charco, alExplotar, soloAviso }
-- ------------------------------------------------------------
function B:agregarZona(z)
  z.t = -(z.retraso or 0)
  z.post = z.post or 0.28
  z.delay = z.delay or 0.8
  z.color = z.color or { 1, 0.3, 0.2 }
  z.detonada = false
  self.zonas[#self.zonas + 1] = z
  return z
end

local function distSegmento(px, py, x, y, ang, largo)
  local sx, sy = math.cos(ang) * largo, math.sin(ang) * largo
  local qx, qy = px - x, py - y
  local t = (qx * sx + qy * sy) / (sx * sx + sy * sy)
  if t < 0 then t = 0 elseif t > 1 then t = 1 end
  local dx, dy = sx * t - qx, sy * t - qy
  return math.sqrt(dx * dx + dy * dy)
end

function B:detonarZona(z, objetivo, ctx)
  local golpeo = false
  if not z.soloAviso and (z.dano or 0) >= 0 then
    if z.tipo == "circulo" then
      local dx, dy = objetivo.x - z.x, objetivo.y - z.y
      golpeo = math.sqrt(dx * dx + dy * dy) < z.r + objetivo.radio
    elseif z.tipo == "linea" then
      golpeo = distSegmento(objetivo.x, objetivo.y, z.x, z.y, z.ang, z.largo) < z.ancho / 2 + objetivo.radio
    elseif z.tipo == "cono" then
      local dx, dy = objetivo.x - z.x, objetivo.y - z.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < z.r + objetivo.radio then
        local a = atan2(dy, dx)
        local dif = math.abs(((a - z.ang + PI) % (PI * 2)) - PI)
        golpeo = dif < z.apertura
      end
    end
  end
  if golpeo then
    if (z.dano or 0) > 0 then objetivo:recibirDanio(z.dano) end
    if z.slow and objetivo.aplicarSlow then objetivo:aplicarSlow(z.slow) end
  end

  -- efectos visuales / sonoros
  local c = z.color
  if z.tipo == "circulo" then
    Juice.explosion(z.x, z.y, c, math.max(0.6, z.r / 30))
  elseif z.tipo == "linea" then
    local n = 6
    for i = 0, n do
      Juice.chispas(z.x + math.cos(z.ang) * z.largo * i / n,
                    z.y + math.sin(z.ang) * z.largo * i / n, 3, c, 60, 0.35)
    end
  else
    Juice.chispas(z.x + math.cos(z.ang) * z.r * 0.6, z.y + math.sin(z.ang) * z.r * 0.6, 8, c, 90, 0.3)
  end
  if z.sacudida then Juice.sacudir(z.sacudida, 0.22) end

  if z.charco then
    self.charcos[#self.charcos + 1] = {
      x = z.x, y = z.y, radio = z.charco.radio or z.r,
      vida = z.charco.vida or 4, dano = z.charco.dano or 1,
      slow = z.charco.slow, tipo = z.charco.tipo or "lava",
    }
  end
  if z.alExplotar then z.alExplotar(self, z, ctx, objetivo) end
end

function B:actualizarZonas(dt, objetivo, ctx)
  local i = 1
  while i <= #self.zonas do
    local z = self.zonas[i]
    z.t = z.t + dt
    if not z.detonada and z.t >= z.delay then
      z.detonada = true
      self:detonarZona(z, objetivo, ctx)
    end
    if z.t >= z.delay + z.post then
      table.remove(self.zonas, i)
    else
      i = i + 1
    end
  end
end

-- ------------------------------------------------------------
-- TICK COMUN: devuelve true si la IA propia del jefe debe actuar
-- ------------------------------------------------------------
function B:tickBase(dt, mapa, objetivo, enemigos, ctx)
  if not self.vivo then return false end
  self.anim = self.anim + dt
  if self.flashDanio > 0 then self.flashDanio = self.flashDanio - dt end
  if self.invulnerableT > 0 then self.invulnerableT = self.invulnerableT - dt end
  if self.cooldownGlobal > 0 then self.cooldownGlobal = self.cooldownGlobal - dt end

  local d, ux, uy = self:distA(objetivo)
  self.mirandoX, self.mirandoY = ux, uy

  -- charcos
  local i = 1
  while i <= #self.charcos do
    local c = self.charcos[i]
    c.vida = c.vida - dt
    if c.vida <= 0 then table.remove(self.charcos, i) else i = i + 1 end
  end

  self:actualizarZonas(dt, objetivo, ctx)

  if not self.bannerHecho then
    self.bannerHecho = true
    if ctx and ctx.banner then ctx.banner(self.nombre, self.subtitulo) end
  end

  if self.estado == "intro" then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.8
    end
    return false
  end

  -- cambio de fase
  local frac = self.hp / self.hpMax
  local nueva = 1
  for idx, u in ipairs(self.umbrales) do
    if frac < u then nueva = idx + 1 end
  end
  if nueva > self.fase then
    self.fase = nueva
    self.zonas = {}
    self.estado = "transicion"
    self.timer = 1.5
    self.invulnerableT = 1.5
    Juice.sacudir(5, 0.6)
    Juice.flash(1, 1, 1, 0.35, 0.3)
    Juice.anillo(self.x, self.y, 120, self.colorFase or { 1, 0.5, 0.3 }, 0.8)
    if self.alCambiarFase then self:alCambiarFase(nueva, ctx, mapa, objetivo, enemigos) end
    return false
  end

  if self.estado == "transicion" then
    self.timer = self.timer - dt
    if self.duranteTransicion then self:duranteTransicion(dt) end
    if self.timer <= 0 then
      self.estado = "idle"
      self.timer = 0.9
    end
    return false
  end

  return true
end

-- ------------------------------------------------------------
-- DIBUJO COMUN
-- ------------------------------------------------------------
function B:dibujarCharcos()
  for _, c in ipairs(self.charcos) do
    local a = math.min(1, c.vida / 1.5)
    local pulso = 0.85 + 0.15 * math.sin(self.anim * 5 + c.x * 0.1)
    local col1, col2
    if c.tipo == "veneno" then
      col1, col2 = { 0.45, 0.80, 0.20 }, { 0.75, 1.0, 0.45 }
    elseif c.tipo == "hielo" then
      col1, col2 = { 0.50, 0.80, 1.0 }, { 0.90, 0.98, 1.0 }
    elseif c.tipo == "vacio" then
      col1, col2 = { 0.35, 0.10, 0.55 }, { 0.75, 0.40, 1.0 }
    else
      col1, col2 = { 1.0, 0.35, 0.08 }, { 1.0, 0.80, 0.30 }
    end
    love.graphics.setColor(col1[1], col1[2], col1[3], 0.5 * a * pulso)
    love.graphics.ellipse("fill", c.x, c.y + 4, c.radio, c.radio * 0.45)
    love.graphics.setColor(col2[1], col2[2], col2[3], 0.8 * a)
    love.graphics.ellipse("line", c.x, c.y + 4, c.radio, c.radio * 0.45)
    for b = 1, 3 do
      local angB = self.anim * 2 + b * 2.1 + c.x
      local distB = math.sin(angB) * c.radio * 0.5
      love.graphics.setColor(col2[1], col2[2], col2[3], 0.6 * a)
      love.graphics.circle("fill", c.x + distB, c.y + 2, 1.5)
    end
  end
end

function B:dibujarZonas()
  for _, z in ipairs(self.zonas) do
    if z.t >= 0 then
      local c = z.color
      if not z.detonada then
        local k = math.max(0, math.min(1, z.t / z.delay))
        love.graphics.setColor(c[1], c[2], c[3], 0.10 + 0.20 * k)
        if z.tipo == "circulo" then
          love.graphics.circle("fill", z.x, z.y, z.r)
          love.graphics.setColor(c[1], c[2], c[3], 0.35 + 0.35 * k)
          love.graphics.circle("fill", z.x, z.y, z.r * k)
          love.graphics.setColor(c[1], c[2], c[3], 0.7 + 0.3 * k)
          love.graphics.setLineWidth(2)
          love.graphics.circle("line", z.x, z.y, z.r)
          love.graphics.setLineWidth(1)
        elseif z.tipo == "linea" then
          love.graphics.push()
          love.graphics.translate(z.x, z.y)
          love.graphics.rotate(z.ang)
          love.graphics.rectangle("fill", 0, -z.ancho / 2, z.largo, z.ancho)
          love.graphics.setColor(c[1], c[2], c[3], 0.35 + 0.35 * k)
          love.graphics.rectangle("fill", 0, -z.ancho / 2, z.largo * k, z.ancho)
          love.graphics.setColor(c[1], c[2], c[3], 0.7 + 0.3 * k)
          love.graphics.rectangle("line", 0, -z.ancho / 2, z.largo, z.ancho)
          love.graphics.pop()
        elseif z.tipo == "cono" then
          love.graphics.arc("fill", z.x, z.y, z.r, z.ang - z.apertura, z.ang + z.apertura)
          love.graphics.setColor(c[1], c[2], c[3], 0.35 + 0.35 * k)
          love.graphics.arc("fill", z.x, z.y, z.r * k, z.ang - z.apertura, z.ang + z.apertura)
          love.graphics.setColor(c[1], c[2], c[3], 0.7 + 0.3 * k)
          love.graphics.setLineWidth(2)
          love.graphics.arc("line", "open", z.x, z.y, z.r, z.ang - z.apertura, z.ang + z.apertura)
          love.graphics.setLineWidth(1)
        end
      else
        local k = 1 - math.max(0, math.min(1, (z.t - z.delay) / z.post))
        love.graphics.setColor(1, 1, 1, 0.55 * k)
        if z.tipo == "circulo" then
          love.graphics.circle("fill", z.x, z.y, z.r * (0.8 + 0.2 * (1 - k)))
        elseif z.tipo == "linea" then
          love.graphics.push()
          love.graphics.translate(z.x, z.y)
          love.graphics.rotate(z.ang)
          love.graphics.rectangle("fill", 0, -z.ancho / 2, z.largo, z.ancho)
          love.graphics.pop()
        else
          love.graphics.arc("fill", z.x, z.y, z.r, z.ang - z.apertura, z.ang + z.apertura)
        end
      end
    end
  end
end

-- Dibujo general: la clase define dibujarCuerpo(alpha, muerto)
function B:dibujar()
  if not self.vivo then
    local t = love.timer.getTime() - (self.tMuerte or 0)
    if t > 1.7 then return end
    if t < 1.3 and math.random() < 0.35 then
      Juice.explosion(self.x + (math.random() - 0.5) * self.radio * 2,
                      self.y + (math.random() - 0.5) * self.radio * 2,
                      self.colorMuerte or { 1, 0.8, 0.4 }, 0.8)
    end
    self:dibujarCuerpo(math.max(0, 1 - t / 1.7), true)
    return
  end
  self:dibujarCharcos()
  self:dibujarZonas()
  self:dibujarCuerpo(1, false)
  if self.dibujarFrente then self:dibujarFrente() end
end

return B