-- ============================================================
-- JUICE: hit-stop, sacudida de camara, numeros de dano,
-- particulas, ambiente por bioma y banner de jefe.
-- Todo es opcional y aislado: si algo falla aqui el juego sigue.
-- ============================================================
local Shaders = require("src.utils.shaders")
local Config = require("src.datos.config")
local Sangre = require("src.sistemas.sangre")
local FX = require("src.sistemas.fx_habilidades")

local Juice = {}

Juice.hitStop = 0
Juice.shakeT = 0
Juice.shakeDur = 0.01
Juice.shakeMag = 0
Juice.numeros = {}
Juice.particulas = {}
Juice.pendientes = {}
Juice.ambiente = nil
Juice.banner = nil
Juice.flashPantalla = nil

local MAX_PARTICULAS = 420

function Juice.reset()
  Juice.hitStop = 0
  Juice.shakeT = 0
  Juice.shakeMag = 0
  Juice.numeros = {}
  Juice.particulas = {}
  Juice.pendientes = {}
  Juice.ambiente = nil
  Juice.banner = nil
  Juice.flashPantalla = nil
end

function Juice.golpe(dur)
  if dur and dur > Juice.hitStop then Juice.hitStop = dur end
end

function Juice.sacudir(mag, dur)
  -- Golpes fuertes: onda de choque + aberracion cromatica (shader)
  if mag >= 5 then
    pcall(Shaders.shock, 0.5, 0.5)
    pcall(Shaders.golpe, 0.002 + mag * 0.0004)
  elseif mag >= 3 then
    pcall(Shaders.golpe, 0.0012)
  end
  if mag >= Juice.shakeMag or Juice.shakeT <= 0 then
    Juice.shakeMag = mag
    Juice.shakeT = dur
    Juice.shakeDur = math.max(0.01, dur)
  end
end

function Juice.flash(r, g, b, a, dur)
  -- Flash rojo = dano al jugador: pulso rojo en los bordes
  if r > 0.8 and g < 0.2 and b < 0.2 then pcall(Shaders.dano, 0.7) end
  Juice.flashPantalla = { r = r, g = g, b = b, a = a, t = dur, dur = dur }
end

function Juice.offsetCamara()
  if Juice.shakeT <= 0 then return 0, 0 end
  local k = Juice.shakeT / Juice.shakeDur
  local m = Juice.shakeMag * k
  return (math.random() - 0.5) * 2 * m, (math.random() - 0.5) * 2 * m
end

-- Numero flotante inmediato
function Juice.numero(x, y, texto, color, escala)
  if #Juice.numeros > 60 then table.remove(Juice.numeros, 1) end
  Juice.numeros[#Juice.numeros + 1] = {
    x = x + (math.random() - 0.5) * 8,
    y = y,
    texto = tostring(texto),
    color = color or { 1, 1, 1 },
    vida = 0.75,
    vidaMax = 0.75,
    vy = -38,
    escala = escala or 1,
  }
end

-- Acumula el dano de una entidad durante una ventana corta para
-- no llenar la pantalla de numeros (orbes y quemaduras golpean seguido).
function Juice.registrarDanio(ent, cantidad, esCritico)
  if not ent or cantidad <= 0 then return end
  local p = ent._juiceP
  if not p then
    p = { ent = ent, cant = 0, t = 0.16, crit = false }
    ent._juiceP = p
    Juice.pendientes[#Juice.pendientes + 1] = p
  end
  p.cant = p.cant + cantidad
  if esCritico then p.crit = true end
end

function Juice.chispas(x, y, n, color, vel, vida)
  color = color or { 1, 1, 1 }
  vel = vel or 80
  for _ = 1, n do
    if #Juice.particulas >= MAX_PARTICULAS then return end
    local a = math.random() * math.pi * 2
    local v = vel * (0.4 + math.random() * 0.8)
    Juice.particulas[#Juice.particulas + 1] = {
      x = x, y = y,
      vx = math.cos(a) * v,
      vy = math.sin(a) * v,
      vida = (vida or 0.45) * (0.6 + math.random() * 0.6),
      vidaMax = vida or 0.45,
      r = 1 + math.random() * 1.5,
      color = color,
      grav = 0,
      fric = 3.5,
    }
  end
end

function Juice.humo(x, y, n, color, vida)
  color = color or { 0.6, 0.6, 0.6 }
  for _ = 1, n do
    if #Juice.particulas >= MAX_PARTICULAS then return end
    Juice.particulas[#Juice.particulas + 1] = {
      x = x + (math.random() - 0.5) * 6,
      y = y + (math.random() - 0.5) * 4,
      vx = (math.random() - 0.5) * 14,
      vy = -10 - math.random() * 14,
      vida = (vida or 0.5) * (0.7 + math.random() * 0.6),
      vidaMax = vida or 0.5,
      r = 1.5 + math.random() * 2,
      color = color,
      grav = 0,
      fric = 1.5,
      crece = true,
    }
  end
end

function Juice.anillo(x, y, radio, color, dur)
  if radio and radio >= 40 then
    pcall(Sangre.onda, x, y, radio * 0.8, 0.6)
    pcall(FX.onda, x, y, radio * 0.9, color)
  end
  if #Juice.particulas >= MAX_PARTICULAS then return end
  Juice.particulas[#Juice.particulas + 1] = {
    x = x, y = y,
    vx = 0, vy = 0,
    vida = dur or 0.4,
    vidaMax = dur or 0.4,
    r = radio,
    color = color or { 1, 1, 1 },
    anillo = true,
    grav = 0,
    fric = 0,
  }
end

function Juice.explosion(x, y, color, tam)
  tam = tam or 1
  pcall(Sangre.onda, x, y, 26 * tam, 0.8 * tam)
  if tam >= 1.0 then pcall(FX.explosion, x, y, 20 * tam, color) end
  Juice.chispas(x, y, math.floor(14 * tam), color, 130 * tam, 0.5)
  Juice.humo(x, y, math.floor(6 * tam), { 0.35, 0.33, 0.38 }, 0.7)
  Juice.anillo(x, y, 26 * tam, color, 0.35)
end

function Juice.banners(titulo, subtitulo, dur, color)
  Juice.banner = {
    titulo = titulo,
    sub = subtitulo or "",
    t = 0,
    dur = dur or 3.0,
    color = color or { 1, 0.85, 0.40 },
  }
end

-- ------------------------------------------------------------
-- AMBIENTE (particulas ligadas a un bioma dentro de la sala)
-- ------------------------------------------------------------
function Juice.iniciarAmbiente(bioma, rx, ry, w, h)
  Juice.ambiente = nil
  if bioma then pcall(Shaders.perfilBioma, bioma) end
  if not bioma or not bioma.ambiente then return end
  local a = bioma.ambiente
  local lista = {}
  for i = 1, a.cantidad do
    lista[i] = {
      x = rx + math.random() * w,
      y = ry + math.random() * h,
      fase = math.random() * 6.28,
      v = 0.5 + math.random(),
      r = a.rMin + math.random() * (a.rMax - a.rMin),
    }
  end
  Juice.ambiente = { cfg = a, lista = lista, rx = rx, ry = ry, w = w, h = h }
end

local function actualizarAmbiente(dt)
  local A = Juice.ambiente
  if not A then return end
  local c = A.cfg
  for _, p in ipairs(A.lista) do
    p.fase = p.fase + dt * p.v
    if c.modo == "caer" then
      p.y = p.y + c.vy * p.v * dt
      p.x = p.x + math.sin(p.fase) * c.vx * dt
    elseif c.modo == "subir" then
      p.y = p.y - c.vy * p.v * dt
      p.x = p.x + math.sin(p.fase * 1.3) * c.vx * dt
    else -- flotar
      p.x = p.x + math.cos(p.fase) * c.vx * dt
      p.y = p.y + math.sin(p.fase * 0.8) * c.vy * dt
    end
    if p.y > A.ry + A.h + 4 then p.y = A.ry - 2; p.x = A.rx + math.random() * A.w end
    if p.y < A.ry - 4 then p.y = A.ry + A.h + 2; p.x = A.rx + math.random() * A.w end
    if p.x < A.rx then p.x = A.rx + A.w end
    if p.x > A.rx + A.w then p.x = A.rx end
  end
end

function Juice.actualizar(dt)
  if Juice.shakeT > 0 then Juice.shakeT = Juice.shakeT - dt end

  -- Numeros flotantes
  local i = 1
  while i <= #Juice.numeros do
    local n = Juice.numeros[i]
    n.vida = n.vida - dt
    n.y = n.y + n.vy * dt
    n.vy = n.vy * (1 - 3 * dt)
    if n.vida <= 0 then
      table.remove(Juice.numeros, i)
    else
      i = i + 1
    end
  end

  -- Danos pendientes (ventana de agrupacion)
  i = 1
  while i <= #Juice.pendientes do
    local p = Juice.pendientes[i]
    p.t = p.t - dt
    if p.t <= 0 then
      local e = p.ent
      local val = math.floor(p.cant + 0.5)
      if val < 1 then val = 1 end
      local col = { 1, 0.95, 0.80 }
      local esc = 1
      if p.crit then
        col = { 1, 0.75, 0.25 }
        esc = 1.3
      end
      if val >= 20 then esc = 1.4 end
      Juice.numero(e.x, e.y - (e.radio or 8) - 6, val, col, esc)
      e._juiceP = nil
      table.remove(Juice.pendientes, i)
    else
      i = i + 1
    end
  end

  -- Particulas
  i = 1
  while i <= #Juice.particulas do
    local p = Juice.particulas[i]
    p.vida = p.vida - dt
    if p.vida <= 0 then
      table.remove(Juice.particulas, i)
    else
      if not p.anillo then
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.grav * dt
        local f = 1 - math.min(1, p.fric * dt)
        p.vx = p.vx * f
        p.vy = p.vy * f
      end
      i = i + 1
    end
  end

  actualizarAmbiente(dt)

  if Juice.banner then
    Juice.banner.t = Juice.banner.t + dt
    if Juice.banner.t >= Juice.banner.dur then Juice.banner = nil end
  end

  if Juice.flashPantalla then
    Juice.flashPantalla.t = Juice.flashPantalla.t - dt
    if Juice.flashPantalla.t <= 0 then Juice.flashPantalla = nil end
  end
end

-- ------------------------------------------------------------
-- DIBUJO (mundo)
-- ------------------------------------------------------------
function Juice.dibujarAmbiente()
  local A = Juice.ambiente
  if not A then return end
  local c = A.cfg
  local col = c.color

  -- Niebla/bruma animada del bioma (shader). Respaldo: no se dibuja nada.
  if Shaders.activo and Config.get("efectosVisuales") ~= false then
    local vel = { 0.02, 0.01 }
    local dens, esc = 0.55, 3.5
    if c.modo == "subir" then vel = { 0.012, -0.045 }
    elseif c.modo == "caer" then vel = { 0.025, 0.05 }; dens = 0.45 end
    Shaders.niebla(A.rx, A.ry, A.w, A.h, {
      color = col, alpha = 0.16, escala = esc, vel = vel, densidad = dens,
      offset = { A.rx * 0.004, A.ry * 0.004 }, corte = 0.38,
    })
  end

  for _, p in ipairs(A.lista) do
    local pulso = 0.6 + 0.4 * math.sin(p.fase * 2)
    love.graphics.setColor(col[1], col[2], col[3], (c.alpha or 0.5) * pulso)
    if c.forma == "linea" then
      love.graphics.rectangle("fill", p.x, p.y, 1, p.r * 2)
    else
      love.graphics.circle("fill", p.x, p.y, p.r)
    end
  end
end

function Juice.dibujarMundo()
  for _, p in ipairs(Juice.particulas) do
    local k = math.max(0, p.vida / p.vidaMax)
    if p.anillo then
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], k * 0.8)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", p.x, p.y, p.r * (1 - k) + 2)
      love.graphics.setLineWidth(1)
    else
      local r = p.r
      if p.crece then r = r * (1.5 - k * 0.5) end
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], math.min(1, k * 1.4))
      love.graphics.circle("fill", p.x, p.y, r * (0.5 + k * 0.5))
    end
  end

  local f = love.graphics.getFont()
  for _, n in ipairs(Juice.numeros) do
    local k = n.vida / n.vidaMax
    local a = math.min(1, k * 2)
    local s = n.escala * (1 + math.max(0, k - 0.8) * 2.2)
    local tw = f:getWidth(n.texto) * s
    love.graphics.setColor(0, 0, 0, a * 0.8)
    love.graphics.print(n.texto, n.x - tw / 2 + 1, n.y + 1, 0, s, s)
    love.graphics.setColor(n.color[1], n.color[2], n.color[3], a)
    love.graphics.print(n.texto, n.x - tw / 2, n.y, 0, s, s)
  end
end

-- ------------------------------------------------------------
-- DIBUJO (pantalla): vineta, tinte, banner, flash
-- ------------------------------------------------------------
function Juice.dibujarPantalla(ancho, alto, bioma)
  -- Tinte de bioma (capa semitransparente)
  if bioma and bioma.tinte then
    local t = bioma.tinte
    love.graphics.setColor(t[1], t[2], t[3], t[4])
    love.graphics.rectangle("fill", 0, 0, ancho, alto)
  end

  -- Vineta (bandas con alpha decreciente)
  for i = 0, 9 do
    local a = (1 - i / 10) * 0.22
    love.graphics.setColor(0, 0, 0, a)
    local g = i * 5
    love.graphics.rectangle("fill", 0, g, ancho, 5)
    love.graphics.rectangle("fill", 0, alto - g - 5, ancho, 5)
    love.graphics.rectangle("fill", g, 0, 5, alto)
    love.graphics.rectangle("fill", ancho - g - 5, 0, 5, alto)
  end

  -- Flash de pantalla
  if Juice.flashPantalla then
    local F = Juice.flashPantalla
    love.graphics.setColor(F.r, F.g, F.b, F.a * (F.t / F.dur))
    love.graphics.rectangle("fill", 0, 0, ancho, alto)
  end

  -- Banner (tipo "PORTADOR DERROTADO" o "Bosque Maldito - Nivel 4")
  local B = Juice.banner
  if B then
    local k
    if B.t < 0.5 then
      k = B.t / 0.5
    elseif B.t > B.dur - 0.7 then
      k = math.max(0, (B.dur - B.t) / 0.7)
    else
      k = 1
    end
    local y = alto * 0.28

    love.graphics.setColor(0, 0, 0, 0.55 * k)
    love.graphics.rectangle("fill", 0, y - 14, ancho, 62)

    love.graphics.setColor(B.color[1], B.color[2], B.color[3], 0.8 * k)
    love.graphics.rectangle("fill", ancho * 0.15, y - 14, ancho * 0.7, 1)
    love.graphics.rectangle("fill", ancho * 0.15, y + 47, ancho * 0.7, 1)

    local f = love.graphics.getFont()
    local esc = 2.0 + (1 - k) * 0.6
    local tw = f:getWidth(B.titulo) * esc
    love.graphics.setColor(0, 0, 0, k)
    love.graphics.print(B.titulo, (ancho - tw) / 2 + 2, y + 2, 0, esc, esc)
    love.graphics.setColor(B.color[1], B.color[2], B.color[3], k)
    love.graphics.print(B.titulo, (ancho - tw) / 2, y, 0, esc, esc)

    if B.sub ~= "" then
      local tw2 = f:getWidth(B.sub)
      love.graphics.setColor(0.85, 0.88, 0.95, k * 0.9)
      love.graphics.print(B.sub, (ancho - tw2) / 2, y + 30)
    end
  end
end

return Juice