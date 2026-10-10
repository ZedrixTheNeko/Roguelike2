-- ============================================================
-- HEROES NUEVOS: Shadow (dagas), Thorin (martillo),
-- Rex (rifle), Sable (katana) + esquiva, frasco, torretas
-- y granadas.
-- ============================================================
local J           = require("src.estados.juego.estado")
local Juice       = require("src.sistemas.juice")
local sonidos     = require("src.datos.sonidos")
local Colisiones  = require("src.sistemas.colisiones")
local BotonRedondo = require("src.ui.botonRedondo")
local constantes  = require("src.constantes")
local Config      = require("src.datos.config")

local atan2 = math.atan2 or math.atan
local PI = math.pi

J.torretas = J.torretas or {}
J.granadas = J.granadas or {}

local function snd(nombre)
  local s = sonidos[nombre]
  if s then s:stop() s:play() end
end

-- ============================================================
-- HELPERS LOCALES
-- ============================================================

local function hab(i)
  return J.robin.personaje.habilidades[i]
end

local function jefeVivo()
  local jf = J.salaActual and J.salaActual.jefe
  if jf and jf.vivo then return jf end
  return nil
end

-- Dano generico a un enemigo con empuje y stun opcionales
function J.danarEnemigo(e, dano, dirX, dirY, empuje, stun)
  if not e.vivo then return false end
  local murio = e:recibirDanio(dano)
  snd("impacto")
  if murio then
    snd("muerte_enemigo")
    local cant = (e.datos and e.datos.monedasAlMorir) or 1
    if e.esElite then cant = cant * 2 end
    J.soltarDrop(e.x, e.y, "moneda", cant)
  else
    if empuje and e.aplicarKnockback then e:aplicarKnockback(dirX, dirY, empuje) end
    if stun and e.aplicarStun then e:aplicarStun(stun) end
  end
  return murio
end

-- Golpe en cono con bonus por espalda
function J.golpeCono(x, y, ang, rango, apertura, dano, opts)
  opts = opts or {}
  local hits = 0
  local dirX, dirY = math.cos(ang), math.sin(ang)

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - x, e.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < rango + e.radio then
        local a = atan2(dy, dx)
        local dif = math.abs(((a - ang + PI) % (PI * 2)) - PI)
        if dif < apertura or d < e.radio + 6 then
          local dm = dano
          if opts.trasero and e.ultimaDirX and e.ultimaDirY then
            if e.ultimaDirX * dirX + e.ultimaDirY * dirY > 0.25 then
              dm = dano * 1.6
              Juice.numero(e.x, e.y - e.radio - 14, "ESPALDA!", {1.0, 0.75, 0.25}, 0.9)
              Juice.chispas(e.x, e.y, 8, {1.0, 0.8, 0.3}, 100, 0.35)
            end
          end
          J.danarEnemigo(e, dm, dirX, dirY, opts.empuje, opts.stun)
          hits = hits + 1
        end
      end
    end
  end

  local jf = jefeVivo()
  if jf then
    local dx, dy = jf.x - x, jf.y - y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < rango + jf.radio then
      local a = atan2(dy, dx)
      local dif = math.abs(((a - ang + PI) % (PI * 2)) - PI)
      if dif < apertura or d < jf.radio + 6 then
        jf:recibirDanio(dano)
        snd("impacto")
        hits = hits + 1
      end
    end
  end

  if hits > 0 then Juice.golpe(opts.hitstop or 0.03) end
  return hits
end

-- Golpe circular
function J.golpeCirculo(x, y, radio, dano, opts)
  opts = opts or {}
  local hits = 0
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - x, e.y - y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < radio + e.radio then
        local nx, ny = 1, 0
        if d > 0.01 then nx, ny = dx / d, dy / d end
        J.danarEnemigo(e, dano, nx, ny, opts.empuje, opts.stun)
        hits = hits + 1
      end
    end
  end
  local jf = jefeVivo()
  if jf then
    local dx, dy = jf.x - x, jf.y - y
    if math.sqrt(dx * dx + dy * dy) < radio + jf.radio then
      jf:recibirDanio(dano)
      snd("impacto")
      hits = hits + 1
    end
  end
  if hits > 0 then Juice.golpe(opts.hitstop or 0.04) end
  return hits
end

-- Golpe a lo largo de un segmento
function J.golpeLinea(x1, y1, x2, y2, ancho, dano, opts)
  opts = opts or {}
  local sx, sy = x2 - x1, y2 - y1
  local len2 = sx * sx + sy * sy
  if len2 < 0.01 then return 0 end

  local function dist(px, py)
    local t = ((px - x1) * sx + (py - y1) * sy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local qx, qy = x1 + sx * t - px, y1 + sy * t - py
    return math.sqrt(qx * qx + qy * qy)
  end

  local len = math.sqrt(len2)
  local dirX, dirY = sx / len, sy / len
  local hits = 0
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo and dist(e.x, e.y) < ancho / 2 + e.radio then
      J.danarEnemigo(e, dano, dirX, dirY, opts.empuje, opts.stun)
      hits = hits + 1
    end
  end
  local jf = jefeVivo()
  if jf and dist(jf.x, jf.y) < ancho / 2 + jf.radio then
    jf:recibirDanio(dano)
    snd("impacto")
    hits = hits + 1
  end
  if hits > 0 then Juice.golpe(opts.hitstop or 0.05) end
  return hits
end

-- Mueve al jugador en una direccion hasta chocar. Devuelve distancia recorrida
local function avanzar(dist, dx, dy)
  local r = J.robin
  local paso = 4
  local recorrido = 0
  while recorrido < dist do
    local nx, ny = r.x + dx * paso, r.y + dy * paso
    if Colisiones.circuloConMapa(nx, ny, r.radio, J.salaActual.mapa) then break end
    r.x, r.y = nx, ny
    recorrido = recorrido + paso
  end
  return recorrido
end

local function enemigoMasCercano(x, y, rango, excluir)
  local mejor, md = nil, rango * rango
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo and e ~= excluir and not e.intangible then
      local dx, dy = e.x - x, e.y - y
      local d = dx * dx + dy * dy
      if d < md then mejor, md = e, d end
    end
  end
  local jf = jefeVivo()
  if jf and jf ~= excluir then
    local dx, dy = jf.x - x, jf.y - y
    local d = dx * dx + dy * dy
    if d < md then mejor, md = jf, d end
  end
  return mejor
end
J.enemigoMasCercano = enemigoMasCercano

-- Dash en linea recta con estela + dano lineal (usado por Shadow y Sable)
local function dashLinea(h, color, ancho)
  local r = J.robin
  local ang = atan2(r.ultimaDirY, r.ultimaDirX)
  local dx, dy = math.cos(ang), math.sin(ang)
  local x0, y0 = r.x, r.y
  Juice.humo(x0, y0, 5, { 0.5, 0.3, 0.7 }, 0.5)
  local rec = avanzar(h.distancia, dx, dy)
  table.insert(J.cortes, {
    x = x0, y = y0, angulo = ang, tipo = "rastro",
    rango = rec, ancho = ancho, color = color,
    vida = 0.35, duracion = 0.35,
  })
  J.golpeLinea(x0, y0, r.x, r.y, 30, h.dano, { hitstop = 0.06, empuje = 80 })
  r.invulnerable = math.max(r.invulnerable, h.invulnerableDurante or 0.35)
  Juice.sacudir(2.5, 0.15)
  Juice.chispas(r.x, r.y, 8, color, 100, 0.4)
end

-- ============================================================
-- SHADOW — dagas
-- ============================================================

function J.habilidadShadow1()
  local h = hab(1)
  dashLinea(h, { 0.7, 0.4, 1.0 }, 10)
  snd("corte")
end

function J.habilidadShadow2()
  local h = hab(2)
  local r = J.robin
  local base = atan2(r.ultimaDirY, r.ultimaDirX)
  local n = h.cantidad
  for i = 1, n do
    local a = base - h.apertura / 2 + h.apertura * (i - 1) / (n - 1)
    local p = J.poolFlechas:obtener()
    if p then
      p:lanzar(r.x, r.y, math.cos(a), math.sin(a), 300, h.dano, false, "daga")
    end
  end
  r.invulnerable = math.max(r.invulnerable, 0.2)
  snd("disparo")
end

function J.habilidadShadow3()
  local h = hab(3)
  local r = J.robin
  local objetivo = enemigoMasCercano(r.x, r.y, h.rango)

  if not objetivo then
    J.agregarNotificacion("Sin objetivo", r.x, r.y - 25, { 0.8, 0.8, 0.9 })
    return false
  end

  local a = J.accionEspecial
  a.tipo = "ejecucion"
  a.timer = 0
  a.duracion = h.duracion
  a.golpes = 0
  a.objetivoRef = objetivo
  a.bloqueaMovimiento = true
  r.invulnerable = math.max(r.invulnerable, h.duracion + 0.2)
  Juice.flash(0.5, 0.2, 0.8, 0.3, 0.3)
end

-- ============================================================
-- THORIN — martillo
-- ============================================================

function J.habilidadThorin1()
  local h = hab(1)
  local a = J.accionEspecial
  a.tipo = "escudo_sagrado"
  a.timer = 0
  a.duracion = h.duracion
  a.bloqueados = 0
  a.bloqueaMovimiento = false
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.duracion)
  Juice.anillo(J.robin.x, J.robin.y, 40, {1, 0.9, 0.4}, 0.5)
end

function J.habilidadThorin2()
  local h = hab(2)
  local r = J.robin

  table.insert(J.cortes, {
    x = r.x, y = r.y, angulo = 0, tipo = "onda_tierra",
    radio = h.radio, vida = 0.5, duracion = 0.5,
  })

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - r.x, e.y - r.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < h.radio + e.radio then
        local nx, ny = 1, 0
        if d > 0.01 then nx, ny = dx / d, dy / d end
        J.danarEnemigo(e, h.dano, nx, ny, h.empuje, h.stunDur)
      end
    end
  end

  local jf = jefeVivo()
  if jf then
    local dx, dy = jf.x - r.x, jf.y - r.y
    if math.sqrt(dx * dx + dy * dy) < h.radio + jf.radio then
      jf:recibirDanio(h.dano)
    end
  end

  Juice.sacudir(7, 0.4)
  Juice.golpe(0.08)
  Juice.explosion(r.x, r.y, {0.9, 0.75, 0.4}, 1.6)
  r.invulnerable = math.max(r.invulnerable, 0.4)
  snd("corte")
end

function J.habilidadThorin3()
  local h = hab(3)
  local r = J.robin
  local a = J.accionEspecial
  a.tipo = "juicio"
  a.timer = 0
  a.duracion = h.cargaTiempo
  a.bloqueaMovimiento = true
  a.objetivos = {}

  local cand = {}
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx, dy = e.x - r.x, e.y - r.y
      cand[#cand + 1] = { e = e, d = dx * dx + dy * dy }
    end
  end
  local jf = jefeVivo()
  if jf then cand[#cand + 1] = { e = jf, d = 0 } end

  table.sort(cand, function(p, q) return p.d < q.d end)

  for i = 1, math.min(h.rayos, #cand) do
    a.objetivos[i] = cand[i].e
  end

  if #a.objetivos == 0 then
    a.tipo = nil
    a.bloqueaMovimiento = false
    J.agregarNotificacion("Sin objetivo", r.x, r.y - 25, {0.8, 0.8, 0.9})
    return false
  end

  r.invulnerable = math.max(r.invulnerable, h.cargaTiempo + 0.3)
  Juice.flash(1, 0.95, 0.6, 0.25, 0.3)
end

-- ============================================================
-- REX — rifle de plasma
-- ============================================================

function J.habilidadRex1()
  local h = hab(1)
  local r = J.robin

  if #J.torretas >= 2 then table.remove(J.torretas, 1) end

  table.insert(J.torretas, {
    x = r.x + r.ultimaDirX * 14,
    y = r.y + r.ultimaDirY * 14,
    t = h.duracion,
    tMax = h.duracion,
    cad = 0.4,
    cadencia = h.cadencia,
    dano = h.dano,
    ang = atan2(r.ultimaDirY, r.ultimaDirX),
    nace = 0.4,
  })

  Juice.explosion(r.x + r.ultimaDirX * 14, r.y + r.ultimaDirY * 14, {0.4, 0.9, 1.0}, 0.8)
  snd("disparo")
end

function J.habilidadRex2()
  local h = hab(2)
  local r = J.robin
  local dx, dy = r.ultimaDirX, r.ultimaDirY
  local dist = 130

  while dist > 20 and Colisiones.circuloConMapa(
    r.x + dx * dist, r.y + dy * dist, 4, J.salaActual.mapa) do
    dist = dist - 10
  end

  table.insert(J.granadas, {
    x0 = r.x, y0 = r.y,
    x1 = r.x + dx * dist,
    y1 = r.y + dy * dist,
    t = 0, vuelo = 0.55, h = h,
    estado = "vuelo", minis = {},
  })

  r.invulnerable = math.max(r.invulnerable, 0.15)
  snd("disparo")
end

function J.habilidadRex3()
  local h = hab(3)
  J.robin.sobrecargaT = h.duracion
  J.robin.recurso = J.robin.recursoMax
  Juice.flash(1, 0.5, 0.15, 0.3, 0.3)
  Juice.anillo(J.robin.x, J.robin.y, 36, {1, 0.6, 0.2}, 0.5)
  J.agregarNotificacion("SOBRECARGA!", J.robin.x, J.robin.y - 28, {1, 0.6, 0.25})
end

-- ============================================================
-- SABLE — katana estilo souls
-- ============================================================

function J.habilidadSable1()
  local h = hab(1)
  local a = J.accionEspecial
  a.tipo = "parry"
  a.timer = 0
  a.duracion = h.ventana
  a.bloqueaMovimiento = false
  J.robin.parryActivo = true
  J.robin.parryExito = false
  Juice.anillo(J.robin.x, J.robin.y, 28, {0.6, 0.9, 1.0}, 0.4)
end

function J.habilidadSable2()
  local h = hab(2)
  dashLinea(h, { 0.85, 0.95, 1.0 }, 12)
  Juice.golpe(0.07)
  snd("corte")
end

function J.habilidadSable3()
  local h = hab(3)
  local a = J.accionEspecial
  a.tipo = "cien_cortes"
  a.timer = 0
  a.duracion = h.duracion
  a.golpes = 0
  a.bloqueaMovimiento = true
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.duracion + 0.2)
  Juice.flash(1, 1, 1, 0.25, 0.3)
end

-- ============================================================
-- ACCIONES ESPECIALES NUEVAS
-- (se llama desde actualizarAccionEspecial como fallback)
-- ============================================================

function J.actualizarAccionNueva(dt, a)
  local r = J.robin
  local tipo = a.tipo

  -- ============================================================
  -- EJECUCION (Shadow hab 3)
  -- ============================================================
  if tipo == "ejecucion" then
    local h = hab(3)
    local intervalo = h.duracion / h.golpes
    local debidos = math.floor(a.timer / intervalo) + 1

    while a.golpes < debidos and a.golpes < h.golpes do
      a.golpes = a.golpes + 1
      local obj = a.objetivoRef
      if not obj or not obj.vivo then
        obj = enemigoMasCercano(r.x, r.y, h.rango)
        a.objetivoRef = obj
      end
      if obj then
        local ang = math.random() * PI * 2
        local tx = obj.x + math.cos(ang) * (obj.radio + 10)
        local ty = obj.y + math.sin(ang) * (obj.radio + 10)
        if not Colisiones.circuloConMapa(tx, ty, r.radio, J.salaActual.mapa) then
          Juice.chispas(r.x, r.y, 5, { 0.6, 0.3, 0.9 }, 80, 0.3)
          r.x, r.y = tx, ty
        end
        r.ultimaDirX = math.cos(ang + PI)
        r.ultimaDirY = math.sin(ang + PI)

        local ultimo = (a.golpes == h.golpes)
        local dm = ultimo and (h.dano * 2) or h.dano

        if obj.recibirDanio then
          if obj.datos then
            J.danarEnemigo(obj, dm, math.cos(ang + PI), math.sin(ang + PI), nil, nil)
          else
            obj:recibirDanio(dm)
            snd("impacto")
          end
        end

        table.insert(J.cortes, {
          x = obj.x, y = obj.y, angulo = ang, tipo = "corte_aleatorio",
          rango = 34, vida = 0.18, duracion = 0.18,
        })
        Juice.chispas(obj.x, obj.y, 6, { 0.8, 0.5, 1.0 }, 100, 0.3)
        Juice.golpe(ultimo and 0.1 or 0.025)
        if ultimo then Juice.sacudir(5, 0.3) end
      end
    end

    r.invulnerable = math.max(r.invulnerable, 0.1)
    if a.timer >= a.duracion then
      a.tipo = nil
      a.bloqueaMovimiento = false
    end

  -- ============================================================
  -- ESCUDO SAGRADO (Thorin hab 1)
  -- ============================================================
  elseif tipo == "escudo_sagrado" then
    local h = hab(1)
    r.invulnerable = math.max(r.invulnerable, 0.1)

    for p in J.poolFlechasEnemigas:iterarActivos() do
      local dx, dy = p.x - r.x, p.y - r.y
      if dx * dx + dy * dy < (h.radio + p.radio) ^ 2 then
        J.poolFlechasEnemigas:devolver(p)
        a.bloqueados = a.bloqueados + 1
        Juice.chispas(p.x, p.y, 6, { 1, 0.9, 0.4 }, 90, 0.3)
        if a.bloqueados % 3 == 0 and r.escudo < r.escudoMax then
          r.escudo = r.escudo + 1
          J.agregarNotificacion("+1 escudo", r.x, r.y - 30, {0.5, 0.85, 1.0})
        end
      end
    end

    if a.timer >= a.duracion then a.tipo = nil end

  -- ============================================================
  -- JUICIO DIVINO (Thorin hab 3)
  -- ============================================================
  elseif tipo == "juicio" then
    local h = hab(3)
    r.invulnerable = math.max(r.invulnerable, 0.1)

    if a.timer >= a.duracion then
      local alguno = false
      for _, e in ipairs(a.objetivos) do
        if e.vivo then
          alguno = true
          table.insert(J.cortes, {
            x = e.x, y = e.y, angulo = 0, tipo = "pilar_luz",
            radio = h.radio, vida = 0.5, duracion = 0.5,
          })
          J.golpeCirculo(e.x, e.y, h.radio, h.dano, { stun = 0.8, hitstop = 0.0 })
          Juice.explosion(e.x, e.y, { 1, 0.95, 0.55 }, 1.2)
        end
      end

      if alguno then
        Juice.sacudir(6, 0.35)
        Juice.golpe(0.1)
        if r.hp < r.hpMax then
          r.hp = r.hp + 1
          J.agregarNotificacion("+1 vida", r.x, r.y - 30, {0.5, 1.0, 0.5})
        end
      end

      a.tipo = nil
      a.bloqueaMovimiento = false
    end

  -- ============================================================
  -- PARRY (Sable hab 1)
  -- ============================================================
  elseif tipo == "parry" then
    local h = hab(1)

    if r.parryExito then
      r.parryActivo = false
      r.parryExito = false
      r.invulnerable = math.max(r.invulnerable, 0.8)
      J.golpeCirculo(r.x, r.y, h.radio, h.dano, { stun = h.stunDur, empuje = 220, hitstop = 0.0 })
      table.insert(J.cortes, {
        x = r.x, y = r.y, angulo = 0, tipo = "onda_tierra",
        radio = h.radio + 20, vida = 0.4, duracion = 0.4,
      })
      Juice.golpe(0.14)
      Juice.sacudir(5, 0.3)
      Juice.flash(1, 1, 1, 0.45, 0.25)
      Juice.explosion(r.x, r.y, { 0.7, 0.95, 1.0 }, 1.5)
      r.recurso = r.recursoMax
      J.cooldownsHabilidad[1] = 0
      J.agregarNotificacion("PARRY!", r.x, r.y - 32, {0.7, 0.95, 1.0})
      a.tipo = nil

    elseif a.timer >= a.duracion then
      r.parryActivo = false
      a.tipo = nil
    end

  -- ============================================================
  -- CIEN CORTES (Sable hab 3)
  -- ============================================================
  elseif tipo == "cien_cortes" then
    local h = hab(3)
    local intervalo = h.duracion / h.golpes
    local debidos = math.floor(a.timer / intervalo) + 1

    while a.golpes < debidos and a.golpes < h.golpes do
      a.golpes = a.golpes + 1
      local ang = math.random() * PI * 2
      local dd = math.random() * h.radio
      local px, py = r.x + math.cos(ang) * dd, r.y + math.sin(ang) * dd
      local ultimo = (a.golpes == h.golpes)

      table.insert(J.cortes, {
        x = px, y = py, angulo = math.random() * PI,
        tipo = "corte_aleatorio",
        rango = ultimo and 70 or 34,
        vida = 0.2, duracion = 0.2,
      })

      if ultimo then
        J.golpeCirculo(r.x, r.y, h.radio, h.dano * 3, { empuje = 160, hitstop = 0.1 })
        Juice.sacudir(5, 0.3)
        Juice.explosion(r.x, r.y, { 1, 1, 1 }, 1.4)
      else
        J.golpeCirculo(px, py, 22, h.dano, { hitstop = 0.0 })
        Juice.golpe(0.012)
      end
    end

    r.invulnerable = math.max(r.invulnerable, 0.1)
    if a.timer >= a.duracion then
      a.tipo = nil
      a.bloqueaMovimiento = false
    end
  end
end

-- ============================================================
-- TORRETAS Y GRANADAS
-- ============================================================

function J.actualizarExtras(dt)
  -- Torretas
  local i = 1
  while i <= #J.torretas do
    local t = J.torretas[i]
    t.t = t.t - dt
    if t.nace and t.nace > 0 then t.nace = t.nace - dt end
    t.cad = t.cad - dt

    local obj = enemigoMasCercano(t.x, t.y, 230)
    if obj then
      t.ang = atan2(obj.y - t.y, obj.x - t.x)
      if t.cad <= 0 and (not t.nace or t.nace <= 0) then
        t.cad = t.cadencia
        local p = J.poolFlechas:obtener()
        if p then
          p:lanzar(t.x, t.y, math.cos(t.ang), math.sin(t.ang), 330, t.dano, false, "bala")
          Juice.chispas(t.x + math.cos(t.ang) * 8, t.y + math.sin(t.ang) * 8, 2, {1, 0.9, 0.4}, 50, 0.12)
        end
      end
    end

    if t.t <= 0 then
      Juice.explosion(t.x, t.y, { 0.5, 0.9, 1.0 }, 0.8)
      table.remove(J.torretas, i)
    else
      i = i + 1
    end
  end

  -- Granadas
  i = 1
  while i <= #J.granadas do
    local g = J.granadas[i]
    g.t = g.t + dt
    local borrar = false

    if g.estado == "vuelo" then
      if g.t >= g.vuelo then
        g.estado = "minis"
        g.t = 0
        local h = g.h
        g.x, g.y = g.x1, g.y1
        table.insert(J.cortes, {
          x = g.x, y = g.y, angulo = 0, tipo = "explosion_fuego",
          radio = h.radio, vida = 0.5, duracion = 0.5,
        })
        J.golpeCirculo(g.x, g.y, h.radio, h.dano, { empuje = 150, hitstop = 0.06 })
        Juice.explosion(g.x, g.y, { 1, 0.6, 0.2 }, 1.6)
        Juice.sacudir(4, 0.25)

        for k = 1, h.minis do
          local ang = math.random() * PI * 2
          local dd = 28 + math.random() * 32
          g.minis[k] = {
            x = g.x + math.cos(ang) * dd,
            y = g.y + math.sin(ang) * dd,
            t = 0.12 * k, hecho = false,
          }
        end
      end

    else
      local pendientes = 0
      for _, m in ipairs(g.minis) do
        if not m.hecho then
          m.t = m.t - dt
          if m.t <= 0 then
            m.hecho = true
            table.insert(J.cortes, {
              x = m.x, y = m.y, angulo = 0, tipo = "explosion_fuego",
              radio = 24, vida = 0.35, duracion = 0.35,
            })
            J.golpeCirculo(m.x, m.y, 24, g.h.danoMini, { hitstop = 0.0 })
            Juice.explosion(m.x, m.y, { 1, 0.7, 0.3 }, 0.8)
          else
            pendientes = pendientes + 1
          end
        end
      end
      if pendientes == 0 then borrar = true end
    end

    if borrar then table.remove(J.granadas, i) else i = i + 1 end
  end
end

function J.reiniciarExtras()
  J.torretas = {}
  J.granadas = {}
end

-- ============================================================
-- DIBUJO DE EXTRAS (torretas, granadas, escudos, parry)
-- ============================================================

function J.dibujarExtrasMundo()
  local t = love.timer.getTime()

  -- Torretas
  for _, tr in ipairs(J.torretas) do
    local k = (tr.nace and tr.nace > 0) and (1 - tr.nace / 0.4) or 1

    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", tr.x, tr.y + 7, 8, 3)
    love.graphics.setColor(0.25, 0.30, 0.38)
    love.graphics.rectangle("fill", tr.x - 6, tr.y - 2 + (1 - k) * 8, 12, 9, 2)
    love.graphics.setColor(0.40, 0.48, 0.58)
    love.graphics.rectangle("fill", tr.x - 6, tr.y - 2 + (1 - k) * 8, 12, 3, 2)

    love.graphics.push()
    love.graphics.translate(tr.x, tr.y - 3)
    love.graphics.rotate(tr.ang)
    love.graphics.setColor(0.15, 0.18, 0.24)
    love.graphics.rectangle("fill", 0, -2, 13, 4, 1)
    love.graphics.setColor(0.3, 0.95, 1.0, 0.9)
    love.graphics.rectangle("fill", 3, -0.5, 7, 1)
    love.graphics.pop()

    local frac = tr.t / tr.tMax
    love.graphics.setColor(0.3, 0.95, 1.0, 0.9)
    love.graphics.rectangle("fill", tr.x - 6, tr.y + 9, 12 * frac, 1.5)
    love.graphics.setColor(0.3, 0.95, 1.0, 0.12)
    love.graphics.circle("line", tr.x, tr.y, 230)
  end

  -- Granadas en vuelo
  for _, g in ipairs(J.granadas) do
    if g.estado == "vuelo" then
      local k = g.t / g.vuelo
      local x = g.x0 + (g.x1 - g.x0) * k
      local y = g.y0 + (g.y1 - g.y0) * k - math.sin(k * PI) * 28

      love.graphics.setColor(0, 0, 0, 0.3)
      love.graphics.ellipse("fill", g.x0 + (g.x1 - g.x0) * k, g.y0 + (g.y1 - g.y0) * k + 4, 4, 1.5)
      love.graphics.setColor(0.25, 0.30, 0.22)
      love.graphics.circle("fill", x, y, 4)
      love.graphics.setColor(1, 0.35, 0.25, 0.5 + 0.5 * math.sin(t * 30))
      love.graphics.circle("fill", x, y - 3, 1.5)
      love.graphics.setColor(1, 0.4, 0.2, 0.18 * k)
      love.graphics.circle("line", g.x1, g.y1, g.h.radio)
    end
  end

  -- Escudos sagrados / juicio / ejecución / parry
  local a = J.accionEspecial

  if a.tipo == "escudo_sagrado" then
    local r = J.robin
    local rad = hab(1).radio
    local fade = math.min(1, (a.duracion - a.timer) / 0.5)
    love.graphics.setColor(1, 0.92, 0.45, (0.12 + 0.06 * math.sin(t * 8)) * fade)
    love.graphics.circle("fill", r.x, r.y, rad)
    love.graphics.setColor(1, 0.95, 0.60, 0.8 * fade)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", r.x, r.y, rad)
    love.graphics.setLineWidth(1)
    for i = 1, 6 do
      local ang = t * 2 + i * PI / 3
      love.graphics.setColor(1, 1, 0.8, 0.9 * fade)
      love.graphics.circle("fill", r.x + math.cos(ang) * rad, r.y + math.sin(ang) * rad, 2)
    end

  elseif a.tipo == "juicio" and a.objetivos then
    local k = math.min(1, a.timer / a.duracion)
    for _, e in ipairs(a.objetivos) do
      if e.vivo then
        love.graphics.setColor(1, 0.95, 0.5, 0.2 + 0.2 * k)
        love.graphics.circle("fill", e.x, e.y, hab(3).radio)
        love.graphics.setColor(1, 0.95, 0.6, 0.9)
        love.graphics.circle("line", e.x, e.y, hab(3).radio * (1.4 - 0.4 * k))
      end
    end

  elseif a.tipo == "ejecucion" and a.objetivoRef and a.objetivoRef.vivo then
    local o = a.objetivoRef
    love.graphics.setColor(0.8, 0.4, 1.0, 0.8)
    love.graphics.circle("line", o.x, o.y, o.radio + 6 + math.sin(t * 20) * 2)
    love.graphics.line(o.x - o.radio - 10, o.y, o.x + o.radio + 10, o.y)
    love.graphics.line(o.x, o.y - o.radio - 10, o.x, o.y + o.radio + 10)

  elseif a.tipo == "parry" then
    local r = J.robin
    love.graphics.setColor(0.6, 0.9, 1.0, 0.25 + 0.2 * math.sin(t * 25))
    love.graphics.circle("fill", r.x, r.y, 20)
    love.graphics.setColor(0.8, 0.97, 1.0, 0.9)
    love.graphics.circle("line", r.x, r.y, 20)
  end
end

-- ============================================================
-- BOTONES EXTRA (esquiva + frasco)
-- ============================================================

function J.crearBotonesExtra()
  local escala = Config.get("escalaControles") or 1.0
  local r = 19 * escala
  J.botonRodar  = BotonRedondo.nuevo(
    constantes.ANCHO_VIRTUAL - 235, constantes.ALTO_VIRTUAL - 52,
    r, "R", { 0.35, 0.70, 0.55 })
  J.botonFrasco = BotonRedondo.nuevo(
    constantes.ANCHO_VIRTUAL - 285, constantes.ALTO_VIRTUAL - 80,
    r * 0.9, "F", { 0.75, 0.35, 0.45 })
  J.reiniciarExtras()
end

function J.accionRodar()
  if J.pausado or J.dialogoJoy or J.estadoFinNivel then return end
  local r = J.robin
  if not r or not r.vivo then return end
  if J.accionEspecial.bloqueaMovimiento then return end

  local dx, dy = 0, 0
  if J.joyMover and J.joyMover.activo and J.joyMover.magnitud > 0.1 then
    dx, dy = J.joyMover.dx, J.joyMover.dy
  end

  if r:rodar(dx, dy) then
    snd("corte")
  else
    J.agregarNotificacion("Sin energia", r.x, r.y - 25, {0.8, 0.8, 0.9})
  end
end

function J.accionFrasco()
  if J.pausado or J.dialogoJoy or J.estadoFinNivel then return end
  local r = J.robin
  if not r or not r.vivo then return end

  if r:beber() then
    snd("cura")
    J.agregarNotificacion("Frasco!", r.x, r.y - 28, {0.5, 1.0, 0.55})
  elseif r.frascos <= 0 then
    J.agregarNotificacion("Sin frascos", r.x, r.y - 25, {0.8, 0.8, 0.9})
  end
end

function J.dibujarBotonesExtra()
  if not J.botonRodar then return end
  local r = J.robin

  local coste = math.max(14, r.recursoMax * 0.16)
  local puede = r.recurso >= coste and r.estado == "normal"

  J.botonRodar:dibujar()
  if not puede then
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.circle("fill", J.botonRodar.cx, J.botonRodar.cy, J.botonRodar.radio - 2)
  end

  J.botonFrasco:dibujar()
  if r.frascos <= 0 or r.hp >= r.hpMax then
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.circle("fill", J.botonFrasco.cx, J.botonFrasco.cy, J.botonFrasco.radio - 2)
  end

  local f = love.graphics.getFont()
  local txt = "x" .. tostring(r.frascos)
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(txt,
    J.botonFrasco.cx - f:getWidth(txt) * 0.3 + 1,
    J.botonFrasco.cy + J.botonFrasco.radio + 1, 0, 0.7, 0.7)
  love.graphics.setColor(1, 0.85, 0.9)
  love.graphics.print(txt,
    J.botonFrasco.cx - f:getWidth(txt) * 0.3,
    J.botonFrasco.cy + J.botonFrasco.radio, 0, 0.7, 0.7)
end

return J