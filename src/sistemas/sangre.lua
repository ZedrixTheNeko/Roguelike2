-- ============================================================
-- SANGRE: salpicaduras con fisica, charcos, manchas persistentes,
-- pisadas y reaccion a las explosiones/habilidades.
--
--  * Gotas en el aire con gravedad (pseudo-3D: x, y, z), arrastre y rebote.
--  * Al caer dejan manchas "frescas" (brillantes, se oscurecen al secarse).
--  * Las manchas secas se estampan en un Canvas por sala (barato y persistente).
--  * Cada enemigo tiene su fluido: sangre, baba, polvo de hueso, lava,
--    hielo, icor del vacio o savia.
--  * Opcion Config "sangre" (Ajustes) para apagarla.
-- Todo es a prueba de fallos: sin sala activa no hace nada.
-- ============================================================
local Config = require("src.datos.config")
local Colisiones = require("src.sistemas.colisiones")

local S = {}

local atan2 = math.atan2 or math.atan
local PI = math.pi
local GRAV = 330
local MAX_GOTAS = 260
local MAX_FRESCAS = 190
local MAX_LISTA_SECA = 320

S.gotas = {}
S.frescas = {}
S.pendientes = {}
S.bruma = {}
S.sala = nil
S.mapa = nil
S.rx, S.ry = 0, 0
S.W, S.H = 640, 352
S.t = 0
S.hintX, S.hintY, S.hintT = 0, 0, 0
S.fuenteX, S.fuenteY = nil, nil
S.pisadas = 0
S.pisadaT = 0
S.pisadaLado = 1
S.pisadaPerfil = nil

local PERFILES = {
  sangre = { c = { 0.66, 0.04, 0.06 }, seco = { 0.30, 0.02, 0.04 }, brillo = 0.55 },
  baba   = { c = { 0.38, 0.88, 0.32 }, seco = { 0.20, 0.48, 0.18 }, brillo = 0.65, viscoso = true },
  hueso  = { c = { 0.90, 0.86, 0.74 }, seco = { 0.62, 0.58, 0.50 }, brillo = 0.0, polvo = true },
  lava   = { c = { 1.00, 0.52, 0.10 }, seco = { 0.14, 0.06, 0.05 }, brillo = 1.0, brasa = true },
  hielo  = { c = { 0.78, 0.94, 1.00 }, seco = { 0.58, 0.74, 0.88 }, brillo = 0.8 },
  icor   = { c = { 0.60, 0.28, 0.92 }, seco = { 0.22, 0.09, 0.32 }, brillo = 0.7, brasa = true },
  savia  = { c = { 0.58, 0.82, 0.22 }, seco = { 0.28, 0.40, 0.10 }, brillo = 0.5 },
}

local POR_TIPO = {
  slime = "baba", slime_rey = "baba",
  esqueleto = "hueso", esqueleto_arquero = "hueso", guardia = "hueso", arquero = "hueso",
  mago_oscuro = "icor", mago = "icor",
  acechador_vacio = "icor", ojo_del_vacio = "icor", caballero_vacio = "icor", soberano_vacio = "icor",
  salamandra = "lava", golem_menor = "lava", espiritu_fuego = "lava", coloso_magma = "lava",
  cristal_helado = "hielo", fantasma_escarcha = "hielo", reina_escarcha = "hielo",
  hongo_toxico = "savia", arana_venenosa = "savia", madre_raiz = "savia",
}

-- Reconoce el tipo exacto o por prefijo (slime_pequeno, esqueleto_guardia, ...)
local function nombreDePerfil(tipo)
  if type(tipo) ~= "string" then return "sangre" end
  local n = POR_TIPO[tipo]
  if n then return n end
  if tipo:find("^slime") or tipo:find("baba") then return "baba" end
  if tipo:find("^esqueleto") or tipo:find("^guardia") or tipo:find("^calavera") then return "hueso" end
  if tipo:find("^mago") or tipo:find("vacio") or tipo:find("^nigro") then return "icor" end
  if tipo:find("lava") or tipo:find("magma") or tipo:find("fuego") then return "lava" end
  if tipo:find("hielo") or tipo:find("escarcha") then return "hielo" end
  if tipo:find("hongo") or tipo:find("arana") or tipo:find("raiz") then return "savia" end
  return "sangre"
end

local function perfilDe(tipo)
  local n = nombreDePerfil(tipo)
  return PERFILES[n], n
end

local function activa()
  return S.sala ~= nil and Config.get("sangre") ~= false
end

local function rnd(a, b) return a + math.random() * (b - a) end

-- ------------------------------------------------------------
-- SALA / CANVAS
-- ------------------------------------------------------------
local function canvasDe(sala)
  if sala.sangreCanvas == nil then
    local ok, c = pcall(love.graphics.newCanvas, S.W, S.H)
    if ok and c then
      pcall(function() c:setFilter("nearest", "nearest") end)
      local prev = love.graphics.getCanvas()
      love.graphics.setCanvas(c)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setCanvas(prev)
      sala.sangreCanvas = c
    else
      sala.sangreCanvas = false
    end
  end
  return sala.sangreCanvas
end

function S.reset()
  S.gotas, S.frescas, S.pendientes, S.bruma = {}, {}, {}, {}
  S.sala, S.mapa = nil, nil
  S.pisadas = 0
end

-- Dibuja una mancha (fresca o seca) en el sistema de coordenadas actual
local function dibujarMancha(d, seco, ox, oy)
  local p = d.perfil
  local c
  if seco then
    c = p.seco
  else
    local k = math.min(1, d.edad / d.vida)
    local a, b = p.c, p.seco
    c = { a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k }
  end
  local alfa = seco and (d.alfaSeco or 0.85) or 0.92
  local x, y = d.x - ox, d.y - oy

  if d.lobulos then
    -- charco irregular (crece al formarse)
    local g = seco and 1 or math.min(1, d.edad / 1.1)
    g = 1 - (1 - g) * (1 - g)
    love.graphics.setColor(c[1], c[2], c[3], alfa)
    for _, l in ipairs(d.lobulos) do
      love.graphics.ellipse("fill", x + l[1] * g, y + l[2] * g, l[3] * g, l[4] * g)
    end
  else
    love.graphics.setColor(c[1], c[2], c[3], alfa)
    if d.elong > 1.35 then
      love.graphics.push()
      love.graphics.translate(x, y)
      love.graphics.rotate(d.ang)
      love.graphics.ellipse("fill", 0, 0, d.r * d.elong, d.r)
      love.graphics.pop()
    else
      love.graphics.circle("fill", x, y, d.r)
    end
    if d.sats then
      for _, s in ipairs(d.sats) do
        love.graphics.circle("fill", x + s[1], y + s[2], s[3])
      end
    end
  end

  -- brillo humedo mientras esta fresca
  if not seco and p.brillo > 0 then
    local k = math.min(1, d.edad / d.vida)
    local br = p.brillo * (1 - k)
    if br > 0.05 then
      love.graphics.setColor(1, 1, 1, 0.55 * br)
      love.graphics.circle("fill", x - d.r * 0.3, y - d.r * 0.3, math.max(0.6, d.r * 0.28))
    end
  end
end

local function estampar(d)
  local sala = S.sala
  if not sala then return end
  local cv = canvasDe(sala)
  if cv then
    love.graphics.push("all")
    love.graphics.setCanvas(cv)
    love.graphics.origin()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    dibujarMancha(d, true, S.rx, S.ry)
    love.graphics.pop()
  else
    sala.sangreLista = sala.sangreLista or {}
    if #sala.sangreLista < MAX_LISTA_SECA then
      sala.sangreLista[#sala.sangreLista + 1] = d
    end
  end
end

-- Sala nueva: vuelca las manchas frescas de la anterior y cambia de lienzo
function S.entrarSala(sala, rx, ry, W, H)
  if S.sala then
    for _, d in ipairs(S.frescas) do estampar(d) end
    for _, d in ipairs(S.pendientes) do estampar(d) end
  end
  S.frescas, S.pendientes, S.gotas, S.bruma = {}, {}, {}, {}
  S.sala = sala
  S.mapa = sala and sala.mapa or nil
  S.rx, S.ry = rx or 0, ry or 0
  S.W, S.H = W or 640, H or 352
  S.pisadas = 0
  if sala then canvasDe(sala) end
end

-- ------------------------------------------------------------
-- CREACION DE GOTAS Y MANCHAS
-- ------------------------------------------------------------
local function nuevaGota(x, y, z, vx, vy, vz, r, perfil, nombrePerfil, rebotes)
  if #S.gotas >= MAX_GOTAS then table.remove(S.gotas, 1) end
  S.gotas[#S.gotas + 1] = {
    x = x, y = y, z = z, vx = vx, vy = vy, vz = vz, r = r,
    perfil = perfil, nombre = nombrePerfil, rebotes = rebotes or 0,
  }
end

local function nuevaMancha(x, y, r, ang, elong, perfil, vidaExtra)
  if #S.frescas >= MAX_FRESCAS then
    local viejo = table.remove(S.frescas, 1)
    S.pendientes[#S.pendientes + 1] = viejo
  end
  local sats
  if r >= 1.6 and math.random() < 0.7 then
    sats = {}
    for _ = 1, math.random(2, 4) do
      local a = ang + rnd(-0.9, 0.9)
      local dd = r * rnd(1.4, 2.8) * math.min(2, elong)
      sats[#sats + 1] = { math.cos(a) * dd, math.sin(a) * dd, rnd(0.5, math.max(0.7, r * 0.45)) }
    end
  end
  local d = {
    x = x, y = y, r = r, ang = ang, elong = elong, perfil = perfil,
    edad = 0, vida = 5 + math.random() * 3 + (vidaExtra or 0), sats = sats,
  }
  if perfil.brasa then d.brilla = true end
  S.frescas[#S.frescas + 1] = d
  return d
end

local function nuevoCharco(x, y, radio, perfil)
  local lob = {}
  local n = math.random(4, 6)
  for i = 1, n do
    local a = (i / n) * PI * 2 + rnd(-0.4, 0.4)
    local dd = radio * rnd(0.15, 0.65)
    lob[i] = { math.cos(a) * dd, math.sin(a) * dd * 0.75,
               radio * rnd(0.35, 0.65), radio * rnd(0.25, 0.5) }
  end
  lob[n + 1] = { 0, 0, radio * 0.7, radio * 0.5 }
  local d = nuevaMancha(x, y, radio, 0, 1, perfil, 4)
  d.lobulos = lob
  d.sats = nil
  return d
end

local function direccionDeGolpe(ent)
  if S.hintT > 0 then return S.hintX, S.hintY end
  if S.fuenteX and ent then
    local dx, dy = ent.x - S.fuenteX, ent.y - S.fuenteY
    local m = math.sqrt(dx * dx + dy * dy)
    if m > 1 then return dx / m, dy / m end
  end
  local a = math.random() * PI * 2
  return math.cos(a), math.sin(a)
end

-- Impulso direccional de la proxima herida (lo usan los golpes del jugador)
function S.hint(dx, dy)
  local m = math.sqrt(dx * dx + dy * dy)
  if m < 0.001 then return end
  S.hintX, S.hintY, S.hintT = dx / m, dy / m, 0.10
end

-- Herida: salpicadura en la direccion del golpe
function S.herida(ent, cantidad, tipo)
  if not activa() or not ent then return end
  if ent._sgT and S.t - ent._sgT < 0.06 then return end
  ent._sgT = S.t
  local perfil, nombre = perfilDe(tipo or ent.tipo)
  local n = math.max(2, math.min(13, math.floor(cantidad * 0.8) + 2))
  local dx, dy = direccionDeGolpe(ent)
  local base = atan2(dy, dx)
  local altura = (ent.radio or 8) * 0.6

  for _ = 1, n do
    local a
    if math.random() < 0.72 then a = base + rnd(-0.75, 0.75) else a = math.random() * PI * 2 end
    local v = rnd(45, 160)
    local grande = math.random() < 0.14
    nuevaGota(ent.x, ent.y, altura, math.cos(a) * v, math.sin(a) * v, rnd(35, 115),
      grande and rnd(2.2, 3.0) or rnd(0.9, 1.9), perfil, nombre, grande and 1 or 0)
  end

  -- bruma fina (spray)
  for _ = 1, math.random(3, 6) do
    local a = base + rnd(-1.0, 1.0)
    local v = rnd(60, 150)
    S.bruma[#S.bruma + 1] = {
      x = ent.x, y = ent.y - altura, vx = math.cos(a) * v, vy = math.sin(a) * v - 25,
      vida = rnd(0.18, 0.4), vidaMax = 0.4, r = rnd(0.5, 1.1), perfil = perfil,
    }
  end

  -- pequena mancha bajo la herida
  if math.random() < 0.55 then
    nuevaMancha(ent.x + rnd(-3, 3), ent.y + (ent.radio or 6) * 0.6 + rnd(-2, 2),
      rnd(1.2, 2.2), base, 1 + math.random() * 0.6, perfil)
  end
end

-- Muerte: explosion de fluido, charco y trozos que rebotan
function S.muerte(ent, tam, tipo)
  if not activa() or not ent then return end
  tam = tam or 1
  local perfil, nombre = perfilDe(tipo or ent.tipo)
  local dx, dy = direccionDeGolpe(ent)
  local base = atan2(dy, dx)
  local altura = (ent.radio or 8) * 0.5
  local n = math.floor(rnd(16, 24) * tam)

  for i = 1, n do
    local a
    if i <= n * 0.45 then a = base + rnd(-0.9, 0.9) else a = math.random() * PI * 2 end
    local v = rnd(50, 210) * (0.8 + tam * 0.25)
    local grande = math.random() < 0.2
    nuevaGota(ent.x, ent.y, altura, math.cos(a) * v, math.sin(a) * v, rnd(45, 150),
      grande and rnd(2.4, 3.6) or rnd(1.0, 2.2), perfil, nombre, grande and 1 or 0)
  end
  for _ = 1, math.floor(8 * tam) do
    local a = math.random() * PI * 2
    local v = rnd(40, 160)
    S.bruma[#S.bruma + 1] = {
      x = ent.x, y = ent.y - altura, vx = math.cos(a) * v, vy = math.sin(a) * v - 30,
      vida = rnd(0.25, 0.6), vidaMax = 0.6, r = rnd(0.6, 1.4), perfil = perfil,
    }
  end

  nuevoCharco(ent.x, ent.y + (ent.radio or 6) * 0.4, (ent.radio or 8) * rnd(1.0, 1.5) * (0.8 + tam * 0.3), perfil)
  if tam > 1.4 then
    for _ = 1, math.floor(tam) do
      nuevoCharco(ent.x + rnd(-1, 1) * ent.radio * 1.5, ent.y + rnd(-1, 1) * ent.radio, ent.radio * rnd(0.6, 1.0), perfil)
    end
  end
end

-- Onda expansiva (explosiones, golpes de suelo, habilidades de area):
-- las manchas frescas y las gotas cercanas salen despedidas hacia afuera
function S.onda(x, y, radio, fuerza)
  if not activa() then return end
  fuerza = fuerza or 1
  local r2 = radio * radio
  local emitidas = 0

  for i = #S.frescas, 1, -1 do
    local d = S.frescas[i]
    local dx, dy = d.x - x, d.y - y
    local dd = dx * dx + dy * dy
    if dd < r2 and emitidas < 40 then
      local dist = math.sqrt(dd)
      local a = atan2(dy, dx) + rnd(-0.25, 0.25)
      local v = rnd(70, 190) * fuerza * (1 - dist / radio * 0.5)
      local k = math.min(3, math.max(1, math.floor(d.r / 1.2)))
      for _ = 1, k do
        nuevaGota(d.x, d.y, 1, math.cos(a + rnd(-0.3, 0.3)) * v, math.sin(a + rnd(-0.3, 0.3)) * v,
          rnd(60, 140) * fuerza, math.max(0.9, d.r * rnd(0.4, 0.7)), d.perfil, "onda", 0)
        emitidas = emitidas + 1
      end
      -- la mancha original se reduce / se esparce
      d.r = d.r * 0.7
      if d.r < 0.9 then table.remove(S.frescas, i) end
    end
  end

  for _, g in ipairs(S.gotas) do
    local dx, dy = g.x - x, g.y - y
    local dd = dx * dx + dy * dy
    if dd < r2 and dd > 0.01 then
      local dist = math.sqrt(dd)
      local imp = (1 - dist / radio) * 190 * fuerza
      g.vx = g.vx + dx / dist * imp
      g.vy = g.vy + dy / dist * imp
      g.vz = g.vz + imp * 0.5
    end
  end
end

-- Estela de sangre en una linea (dash que atraviesa enemigos, cortes largos)
function S.linea(x1, y1, x2, y2, tipo, cantidad)
  if not activa() then return end
  local perfil, nombre = perfilDe(tipo or "sangre")
  local dx, dy = x2 - x1, y2 - y1
  local base = atan2(dy, dx)
  for _ = 1, cantidad or 8 do
    local t = math.random()
    local lado = (math.random() < 0.5) and 1 or -1
    local a = base + lado * PI / 2 + rnd(-0.5, 0.5)
    local v = rnd(35, 110)
    nuevaGota(x1 + dx * t, y1 + dy * t, 2, math.cos(a) * v, math.sin(a) * v, rnd(30, 90),
      rnd(0.9, 1.8), perfil, nombre, 0)
  end
end

-- ------------------------------------------------------------
-- ACTUALIZACION (fisica)
-- ------------------------------------------------------------
local function aterrizar(g)
  local v = math.sqrt(g.vx * g.vx + g.vy * g.vy)
  local elong = 1 + math.min(2.2, v / 95)
  local ang = (v > 5) and atan2(g.vy, g.vx) or 0
  local r = g.r * (g.perfil.viscoso and 1.3 or 1.0) * (1 + math.min(0.5, math.abs(g.vz) / 300))
  nuevaMancha(g.x, g.y, r, ang, elong, g.perfil)
end

local function enPared(x, y)
  if not S.mapa then return false end
  return Colisiones.circuloConMapa(x, y, 1.2, S.mapa, true)
end

function S.actualizar(dt, jugador)
  S.t = S.t + dt
  if S.hintT > 0 then S.hintT = S.hintT - dt end
  if jugador then S.fuenteX, S.fuenteY = jugador.x, jugador.y end
  if not S.sala then return end

  -- gotas
  local i = 1
  while i <= #S.gotas do
    local g = S.gotas[i]
    local px, py = g.x, g.y
    g.vz = g.vz - GRAV * dt
    local fr = 1 - math.min(1, 0.9 * dt)
    g.vx, g.vy = g.vx * fr, g.vy * fr
    g.x = g.x + g.vx * dt
    g.y = g.y + g.vy * dt
    g.z = g.z + g.vz * dt
    local quitar = false

    if enPared(g.x, g.y) then
      -- se pega a la pared: mancha en el ultimo punto libre
      g.x, g.y = px, py
      g.vx, g.vy = 0, 0
      g.z = 0
      aterrizar(g)
      quitar = true
    elseif g.z <= 0 and g.vz < 0 then
      g.z = 0
      if g.rebotes > 0 then
        g.rebotes = g.rebotes - 1
        g.vz = -g.vz * 0.38
        g.vx, g.vy = g.vx * 0.6, g.vy * 0.6
        nuevaMancha(g.x, g.y, g.r * 0.8, atan2(g.vy, g.vx), 1.3, g.perfil)
      else
        aterrizar(g)
        quitar = true
      end
    end

    if quitar then table.remove(S.gotas, i) else i = i + 1 end
  end

  -- bruma
  i = 1
  while i <= #S.bruma do
    local b = S.bruma[i]
    b.vida = b.vida - dt
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
    b.vy = b.vy + 90 * dt
    b.vx = b.vx * (1 - math.min(1, 2.5 * dt))
    if b.vida <= 0 then table.remove(S.bruma, i) else i = i + 1 end
  end

  -- manchas frescas -> secas
  i = 1
  while i <= #S.frescas do
    local d = S.frescas[i]
    d.edad = d.edad + dt
    if d.edad >= d.vida then
      S.pendientes[#S.pendientes + 1] = d
      table.remove(S.frescas, i)
    else
      i = i + 1
    end
  end

  -- estampar en el lienzo (limitado por frame)
  local n = 0
  while #S.pendientes > 0 and n < 24 do
    estampar(table.remove(S.pendientes, 1))
    n = n + 1
  end

  -- pisadas ensangrentadas
  if jugador then S.actualizarPisadas(dt, jugador) end
end

function S.actualizarPisadas(dt, j)
  if not activa() then return end
  -- ¿esta pisando una mancha fresca?
  if S.pisadas <= 0 then
    for _, d in ipairs(S.frescas) do
      if d.edad < d.vida * 0.8 and (d.r > 1.8 or d.lobulos) then
        local dx, dy = j.x - d.x, j.y + 6 - d.y
        local rr = (d.lobulos and d.r * 0.8 or d.r * 1.2) + 4
        if dx * dx + dy * dy < rr * rr then
          S.pisadas = 9
          S.pisadaPerfil = d.perfil
          S.pisadaDist = 0
          S.pisaX, S.pisaY = j.x, j.y
          break
        end
      end
    end
  end
  if S.pisadas > 0 and S.pisaX then
    local dx, dy = j.x - S.pisaX, j.y - S.pisaY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 9 then
      local a = atan2(dy, dx)
      S.pisadaLado = -S.pisadaLado
      local ox = math.cos(a + PI / 2) * 2.2 * S.pisadaLado
      local oy = math.sin(a + PI / 2) * 2.2 * S.pisadaLado
      local d = nuevaMancha(j.x + ox, j.y + 7 + oy, 1.6, a, 1.7, S.pisadaPerfil)
      d.edad = d.vida * 0.4 * (1 - S.pisadas / 9)
      d.alfaSeco = 0.45 * (S.pisadas / 9)
      S.pisaX, S.pisaY = j.x, j.y
      S.pisadas = S.pisadas - 1
    end
  end
end

-- ------------------------------------------------------------
-- DIBUJO
-- ------------------------------------------------------------
function S.dibujarSuelo(rx, ry)
  if not S.sala or Config.get("sangre") == false then return end
  local sala = S.sala
  local cv = sala.sangreCanvas
  if cv then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(cv, rx, ry)
    love.graphics.setBlendMode("alpha", "alphamultiply")
  elseif sala.sangreLista then
    for _, d in ipairs(sala.sangreLista) do dibujarMancha(d, true, 0, 0) end
  end
  for _, d in ipairs(S.frescas) do dibujarMancha(d, false, 0, 0) end
  -- brasa / icor: resplandor aditivo mientras estan frescos
  love.graphics.setBlendMode("add")
  for _, d in ipairs(S.frescas) do
    if d.brilla then
      local k = 1 - math.min(1, d.edad / d.vida)
      local c = d.perfil.c
      love.graphics.setColor(c[1], c[2], c[3], 0.35 * k)
      love.graphics.circle("fill", d.x, d.y, d.r * (d.lobulos and 1.2 or 1.8))
    end
  end
  love.graphics.setBlendMode("alpha")
end

function S.dibujarAire()
  if not S.sala or Config.get("sangre") == false then return end
  for _, g in ipairs(S.gotas) do
    local c = g.perfil.c
    -- sombra en el suelo
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", g.x, g.y, g.r * 0.9, g.r * 0.45)
    -- estela
    local sx = g.vx * 0.022
    local sy = (g.vy - g.vz) * 0.022
    love.graphics.setColor(c[1], c[2], c[3], 0.55)
    love.graphics.setLineWidth(math.max(1, g.r * 1.4))
    love.graphics.line(g.x, g.y - g.z, g.x - sx, g.y - g.z - sy)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.circle("fill", g.x, g.y - g.z, g.r)
    if g.perfil.brillo > 0 then
      love.graphics.setColor(1, 1, 1, 0.5)
      love.graphics.circle("fill", g.x - g.r * 0.3, g.y - g.z - g.r * 0.3, math.max(0.4, g.r * 0.3))
    end
    if g.perfil.brasa then
      love.graphics.setBlendMode("add")
      love.graphics.setColor(c[1], c[2], c[3], 0.35)
      love.graphics.circle("fill", g.x, g.y - g.z, g.r * 2.4)
      love.graphics.setBlendMode("alpha")
    end
  end
  for _, b in ipairs(S.bruma) do
    local c = b.perfil.c
    love.graphics.setColor(c[1], c[2], c[3], 0.7 * math.max(0, b.vida / b.vidaMax))
    love.graphics.circle("fill", b.x, b.y, b.r)
  end
end

return S
