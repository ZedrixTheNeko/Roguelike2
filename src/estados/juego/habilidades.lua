-- ============================================================
-- HABILIDADES - Fachada
-- ============================================================

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- CARGAR HABILIDADES POR PERSONAJE
-- ============================================================
require("src.estados.juego.habilidades.robin")
require("src.estados.juego.habilidades.conan")
require("src.estados.juego.habilidades.merlin")
require("src.estados.juego.habilidades.kael")
require("src.estados.juego.habilidades.brunilda")
require("src.estados.juego.habilidades.coyote")
require("src.estados.juego.habilidades.shen")
require("src.estados.juego.habilidades.nyx")
require("src.estados.juego.habilidades.lyra")
require("src.estados.juego.habilidades.nuevos_heroes")  -- Shadow, Thorin, Rex, Sable + extras

-- ============================================================
-- ROUTER
-- ============================================================

function J.intentarHabilidad(indice)
  if not J.robin.vivo then return end
  if J.pausado then return end
  if J.dialogoJoy then return end
  if J.accionEspecial.tipo ~= nil then return end
  if J.cooldownsHabilidad[indice] > 0 then return end

  local arma = J.robin.tipoArma
  local exito = false

  if arma == "arco" then
    if indice == 1 then J.habilidadRobin1() exito = true
    elseif indice == 2 then J.habilidadRobin2() exito = true
    elseif indice == 3 then J.habilidadRobin3() exito = true end

  elseif arma == "espada" then
    if indice == 1 then J.habilidadConan1() exito = true
    elseif indice == 2 then J.habilidadConan2() exito = true
    elseif indice == 3 then J.habilidadConan3() exito = true end

  elseif arma == "grimorio" then
    if indice == 1 then J.habilidadMerlin1() exito = true
    elseif indice == 2 then J.habilidadMerlin2() exito = true
    elseif indice == 3 then J.habilidadMerlin3() exito = true end

  elseif arma == "bumeran" then
    if indice == 1 then J.habilidadKael1() exito = true
    elseif indice == 2 then J.habilidadKael2() exito = true
    elseif indice == 3 then J.habilidadKael3() exito = true end

  elseif arma == "lanza" then
    if indice == 1 then J.habilidadBrunilda1() exito = true
    elseif indice == 2 then J.habilidadBrunilda2() exito = true
    elseif indice == 3 then J.habilidadBrunilda3() exito = true end

  elseif arma == "revolver" then
    if indice == 1 then J.habilidadCoyote1() exito = true
    elseif indice == 2 then J.habilidadCoyote2() exito = true
    elseif indice == 3 then J.habilidadCoyote3() exito = true end

  elseif arma == "katana" then
    -- Shen y Sable comparten tipoArma
    local p = J.robin.personaje
    if p and p.id == "sable" then
      if indice == 1 then J.habilidadSable1() exito = true
      elseif indice == 2 then J.habilidadSable2() exito = true
      elseif indice == 3 then J.habilidadSable3() exito = true end
    else
      if indice == 1 then J.habilidadShen1() exito = true
      elseif indice == 2 then J.habilidadShen2() exito = true
      elseif indice == 3 then J.habilidadShen3() exito = true end
    end

  elseif arma == "ballesta_plasma" then
    if indice == 1 then J.habilidadNyx1() exito = true
    elseif indice == 2 then J.habilidadNyx2() exito = true
    elseif indice == 3 then J.habilidadNyx3() exito = true end

  elseif arma == "lira" then
    if indice == 1 then J.habilidadLyra1() exito = true
    elseif indice == 2 then J.habilidadLyra2() exito = true
    elseif indice == 3 then J.habilidadLyra3() exito = true end

  elseif arma == "dagas" then
    -- Shadow
    if indice == 1 then J.habilidadShadow1() exito = true
    elseif indice == 2 then J.habilidadShadow2() exito = true
    elseif indice == 3 then J.habilidadShadow3() exito = true end

  elseif arma == "martillo" then
    -- Thorin
    if indice == 1 then J.habilidadThorin1() exito = true
    elseif indice == 2 then J.habilidadThorin2() exito = true
    elseif indice == 3 then J.habilidadThorin3() exito = true end

  elseif arma == "rifle" then
    -- Rex
    if indice == 1 then J.habilidadRex1() exito = true
    elseif indice == 2 then J.habilidadRex2() exito = true
    elseif indice == 3 then J.habilidadRex3() exito = true end
  end

  if exito then
    local h = J.robin.personaje.habilidades[indice]
    J.cooldownsHabilidad[indice] = h.cooldown
  end
end

-- ============================================================
-- ACTUALIZACION DE ACCIONES ESPECIALES
-- ============================================================

-- ------------------------------------------------------------
-- CARGA ESTOCADA (Conan hab 2)
-- ------------------------------------------------------------
local function actualizarCargaEstocada(dt, a)
  local puntaX = J.robin.x + J.robin.ultimaDirX * 18
  local puntaY = J.robin.y + J.robin.ultimaDirY * 18

  if math.random() < 0.8 then
    local ang = math.random() * math.pi * 2
    local dist = 40 + math.random() * 30
    table.insert(a.particulas, {
      x = puntaX + math.cos(ang) * dist,
      y = puntaY + math.sin(ang) * dist,
      targetX = puntaX, targetY = puntaY,
      vida = 0.7, radio = 1 + math.random() * 1.8,
    })
  end

  local i = 1
  while i <= #a.particulas do
    local p = a.particulas[i]
    p.vida = p.vida - dt
    local dx = p.targetX - p.x
    local dy = p.targetY - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 2 and p.vida > 0 then
      p.x = p.x + (dx / d) * 140 * dt
      p.y = p.y + (dy / d) * 140 * dt
    end
    if p.vida <= 0 then table.remove(a.particulas, i) else i = i + 1 end
  end

  if a.timer >= a.duracion then
    J.ejecutarEstocadaMaestra()
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- DANZA CORTANTE (Conan hab 3)
-- ------------------------------------------------------------
local function actualizarDanzaCortante(dt, a)
  local e = a.enemigoObjetivo

  if e == nil or not e.vivo then
    a.tipo = nil
    a.bloqueaMovimiento = false
    return
  end

  local total = a.duracion
  local anguloAE = math.atan2(e.y - J.robin.y, e.x - J.robin.x)

  if a.timer >= total * 0.30 and a.fase == 1 then
    a.fase = 2
    local distLado = 20
    J.robin.x = e.x - math.cos(anguloAE) * distLado
    J.robin.y = e.y - math.sin(anguloAE) * distLado
    J.robin.ultimaDirX = math.cos(anguloAE)
    J.robin.ultimaDirY = math.sin(anguloAE)
  end

  if a.timer >= total * 0.40 and not a.golpeAplicado[1] then
    a.golpeAplicado[1] = true
    local h = J.robin.personaje.habilidades[3]
    Helpers.aplicarDanioAEnemigo(e, h.dano1)
    table.insert(J.cortes, {
      x = J.robin.x, y = J.robin.y,
      angulo = anguloAE, tipo = "corte_rojo_1",
      vida = 0.4, duracion = 0.4,
    })
  end

  if a.timer >= total * 0.60 and not a.golpeAplicado[2] then
    a.golpeAplicado[2] = true
    local h = J.robin.personaje.habilidades[3]
    if e.vivo then
      Helpers.aplicarDanioAEnemigo(e, h.dano2)
      if e.aplicarKnockback then
        e:aplicarKnockback(math.cos(anguloAE), math.sin(anguloAE), h.empuje)
      end
    end
    table.insert(J.cortes, {
      x = J.robin.x, y = J.robin.y,
      angulo = anguloAE, tipo = "corte_rojo_2",
      vida = 0.55, duracion = 0.55,
    })
    Helpers.reproducirCorte()
  end

  if a.timer >= total * 0.80 and not a.golpeAplicado[3] then
    a.golpeAplicado[3] = true
    local anguloAtras = anguloAE + math.pi
    local dist = 55
    local nx = J.robin.x + math.cos(anguloAtras) * dist
    local ny = J.robin.y + math.sin(anguloAtras) * dist
    local Colisiones = require("src.sistemas.colisiones")
    if not Colisiones.circuloConMapa(nx, ny, J.robin.radio, J.salaActual.mapa) then
      J.robin.x = nx
      J.robin.y = ny
    end
    J.robin.invulnerable = math.max(J.robin.invulnerable, 0.4)
  end

  if a.timer >= total then
    a.tipo = nil
    a.enemigoObjetivo = nil
    a.golpeAplicado = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- ESPERANDO MARCADORA (Robin hab 2)
-- ------------------------------------------------------------
local function actualizarEsperandoMarcadora(dt, a)
  local m = a.marcadoraRef
  local activo = false

  if m then
    for p in J.poolFlechas:iterarActivos() do
      if p == m then activo = true break end
    end
  end

  if not activo or a.timer >= a.duracion then
    local zx, zy
    if m then
      zx = m.x; zy = m.y
    else
      zx = J.robin.x; zy = J.robin.y
    end
    local h = J.robin.personaje.habilidades[2]
    a.tipo = "zona_flechas"
    a.timer = 0
    a.duracion = h.duracionZona
    a.zonaX = zx; a.zonaY = zy
    a.radio = h.radio
    a.cantidad = h.cantidad
    a.dano = h.dano
    a.flechasCreadas = 0
    a.marcadoraRef = nil
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- ZONA FLECHAS (Robin hab 2)
-- ------------------------------------------------------------
local function actualizarZonaFlechas(dt, a)
  local progreso = a.timer / a.duracion
  local objetivoCreadas = math.floor(progreso * a.cantidad)

  while a.flechasCreadas < objetivoCreadas do
    a.flechasCreadas = a.flechasCreadas + 1
    local ang = math.random() * math.pi * 2
    local dist = math.random() * a.radio
    local fx = a.zonaX + math.cos(ang) * dist
    local fy = a.zonaY + math.sin(ang) * dist
    local p = J.poolFlechas:obtener()
    if p then
      p:lanzar(fx, fy - 70, 0, 1, 320, a.dano, false, "flecha")
    end
  end

  if a.timer >= a.duracion then a.tipo = nil end
end

-- ------------------------------------------------------------
-- CARGA RAYO ARCANO (Merlin hab 2)
-- ------------------------------------------------------------
local function actualizarCargaRayoArcano(dt, a)
  local puntaX = J.robin.x + J.robin.ultimaDirX * 20
  local puntaY = J.robin.y + J.robin.ultimaDirY * 20

  if math.random() < 0.9 then
    local ang = math.random() * math.pi * 2
    local dist = 50 + math.random() * 40
    table.insert(a.particulas, {
      x = puntaX + math.cos(ang) * dist,
      y = puntaY + math.sin(ang) * dist,
      targetX = puntaX, targetY = puntaY,
      vida = 0.6, radio = 1 + math.random() * 2,
    })
  end

  local i = 1
  while i <= #a.particulas do
    local p = a.particulas[i]
    p.vida = p.vida - dt
    local dx = p.targetX - p.x
    local dy = p.targetY - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 2 and p.vida > 0 then
      p.x = p.x + (dx / d) * 180 * dt
      p.y = p.y + (dy / d) * 180 * dt
    end
    if p.vida <= 0 then table.remove(a.particulas, i) else i = i + 1 end
  end

  if a.timer >= a.duracion then
    J.ejecutarRayoArcano()
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- CARGA IRA CARMESI (Merlin hab 3)
-- ------------------------------------------------------------
local function actualizarCargaIraCarmesi(dt, a)
  if math.random() < 1.5 then
    local ang = math.random() * math.pi * 2
    local dist = 30 + math.random() * 30
    table.insert(a.particulas, {
      x = J.robin.x + math.cos(ang) * dist,
      y = J.robin.y + math.sin(ang) * dist,
      vx = 0, vy = -80,
      vida = 0.8, radio = 1 + math.random() * 2.5,
    })
  end

  local i = 1
  while i <= #a.particulas do
    local p = a.particulas[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then table.remove(a.particulas, i) else i = i + 1 end
  end

  if a.timer >= a.duracion then J.ejecutarIraCarmesi() end
end

-- ------------------------------------------------------------
-- IRA CARMESI ACTIVA (Merlin hab 3)
-- ------------------------------------------------------------
local function actualizarIraCarmesiActiva(dt, a)
  for _, r in ipairs(a.rayos) do
    r.timer = r.timer + dt
    if not r.caido and r.timer >= r.delay then
      r.caido = true
      r.activo = true
      do
        local FXh = require("src.sistemas.fx_habilidades")
        local tx = (r.target and r.target.x) or r.x
        local ty = (r.target and r.target.y) or r.y
        if tx and ty then pcall(FXh.rayo, tx, ty, { 1.0, 0.35, 0.5 }) end
      end
      if r.target and r.target.vivo then
        local h = J.robin.personaje.habilidades[3]
        local murio = r.target:recibirDanio(h.danoPorRayo)
        Helpers.reproducirImpacto()
        if murio then
          Helpers.reproducirMuerte()
          Helpers.soltarMonedas(r.target)
        end
      end
    end
  end

  if a.timer >= a.duracion then
    a.tipo = nil
    a.rayos = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- FURIA VALQUIRIA (Brunilda hab 3)
-- ------------------------------------------------------------
local function actualizarFuriaValquiria(dt, a)
  local radio = a.radio or 100

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = J.robin.x - e.x
      local dy = J.robin.y - e.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < radio and d > 20 then
        local velAtraccion = 220
        e.x = e.x + (dx / d) * velAtraccion * dt
        e.y = e.y + (dy / d) * velAtraccion * dt
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = J.robin.x - jf.x
    local dy = J.robin.y - jf.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < radio and d > 30 then
      local velAtraccion = 80
      jf.x = jf.x + (dx / d) * velAtraccion * dt
      jf.y = jf.y + (dy / d) * velAtraccion * dt
    end
  end

  if math.random() < 1.5 then
    local ang = math.random() * math.pi * 2
    local dist = 40 + math.random() * 40
    table.insert(a.particulas, {
      x = J.robin.x + math.cos(ang) * dist,
      y = J.robin.y + math.sin(ang) * dist,
      vx = -math.cos(ang) * 120, vy = -math.sin(ang) * 120,
      vida = 0.5, radio = 1 + math.random() * 2,
    })
  end

  local i = 1
  while i <= #a.particulas do
    local p = a.particulas[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vida = p.vida - dt
    if p.vida <= 0 then table.remove(a.particulas, i) else i = i + 1 end
  end

  if a.timer >= a.duracion then
    J.ejecutarFuriaValhalla()
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- RAFAGA COYOTE (Coyote hab 2)
-- ------------------------------------------------------------
local function actualizarRafagaCoyote(dt, a)
  local dirX = a.direccionX
  local dirY = a.direccionY

  a.timerDisparo = a.timerDisparo - dt

  while a.timerDisparo <= 0 and a.timer < a.duracion do
    a.timerDisparo = a.timerDisparo + a.intervalo

    if J.robin.recurso <= 0 or J.robin.recargando then break end

    local dualActivo = (J.robin.dualWield or 0) > 0
    local anguloBase = math.atan2(dirY, dirX)
    local dispersion = math.rad((math.random() - 0.5) * 6)
    local ang = anguloBase + dispersion

    if dualActivo and J.robin.recurso >= 2 then
      local perpX = math.cos(anguloBase + math.pi / 2) * 5
      local perpY = math.sin(anguloBase + math.pi / 2) * 5

      for i = -1, 1, 2 do
        local p = J.poolFlechas:obtener()
        if p then
          p:lanzar(
            J.robin.x + perpX * i,
            J.robin.y + perpY * i,
            math.cos(ang), math.sin(ang),
            520, J.robin.danoAtaque, false, "bala")
        end
      end
      J.robin:gastarResistencia(2)
    else
      local p = J.poolFlechas:obtener()
      if p then
        p:lanzar(J.robin.x, J.robin.y, math.cos(ang), math.sin(ang),
          520, J.robin.danoAtaque, false, "bala")
      end
      J.robin:gastarResistencia(1)
    end

    if J.robin.recurso <= 0 then break end
  end

  if a.timer >= a.duracion then
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- PASOS DE VIENTO (Shen hab 2)
-- ------------------------------------------------------------
local function actualizarPasosViento(dt, a)
  a.timerDash = a.timerDash - dt

  if a.timerDash <= 0 and a.dashesRestantes > 0 then
    a.timerDash = a.dashIntervalo
    a.dashesRestantes = a.dashesRestantes - 1
    a.dashActual = a.dashActual + 1

    local dirX = a.direccionX
    local dirY = a.direccionY
    local distancia = a.distancia
    local Colisiones = require("src.sistemas.colisiones")
    local nx = J.robin.x + dirX * distancia
    local ny = J.robin.y + dirY * distancia
    if not Colisiones.circuloConMapa(nx, J.robin.y, J.robin.radio, J.salaActual.mapa) then
      J.robin.x = nx
    end
    if not Colisiones.circuloConMapa(J.robin.x, ny, J.robin.radio, J.salaActual.mapa) then
      J.robin.y = ny
    end

    table.insert(J.cortes, {
      x = J.robin.x - dirX * distancia * 0.5,
      y = J.robin.y - dirY * distancia * 0.5,
      angulo = math.atan2(dirY, dirX),
      tipo = "estela_viento",
      vida = 0.35, duracion = 0.35, rango = distancia,
    })

    for _, e in ipairs(J.salaActual.enemigos) do
      if e.vivo then
        local dx = e.x - J.robin.x
        local dy = e.y - J.robin.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < 20 + e.radio then
          local murio = e:recibirDanio(a.danoEstela)
          Helpers.reproducirImpacto()
          if murio then
            Helpers.reproducirMuerte()
            J.soltarDrop(e.x, e.y, "moneda", e.datos.monedasAlMorir)
          end
        end
      end
    end

    if J.salaActual.jefe and J.salaActual.jefe.vivo then
      local jf = J.salaActual.jefe
      local dx = jf.x - J.robin.x
      local dy = jf.y - J.robin.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d < 20 + jf.radio then
        jf:recibirDanio(a.danoEstela)
        Helpers.reproducirImpacto()
      end
    end
  end

  if a.dashesRestantes <= 0 and a.timer >= 0.4 then
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- CARGA CORTE DEL VACIO (Shen hab 3)
-- ------------------------------------------------------------
local function actualizarCargaCorteVacio(dt, a)
  local puntaX = J.robin.x + J.robin.ultimaDirX * 22
  local puntaY = J.robin.y + J.robin.ultimaDirY * 22

  if math.random() < 1.2 then
    local ang = math.random() * math.pi * 2
    local dist = 40 + math.random() * 40
    table.insert(a.particulas, {
      x = puntaX + math.cos(ang) * dist,
      y = puntaY + math.sin(ang) * dist,
      targetX = puntaX, targetY = puntaY,
      vida = 0.6, radio = 1 + math.random() * 2,
    })
  end

  local i = 1
  while i <= #a.particulas do
    local p = a.particulas[i]
    p.vida = p.vida - dt
    local dx = p.targetX - p.x
    local dy = p.targetY - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 2 and p.vida > 0 then
      p.x = p.x + (dx / d) * 200 * dt
      p.y = p.y + (dy / d) * 200 * dt
    end
    if p.vida <= 0 then table.remove(a.particulas, i) else i = i + 1 end
  end

  if a.timer >= a.duracion then
    J.ejecutarCorteVacio()
    a.tipo = nil
    a.particulas = {}
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- ANCLAJE GRAVIMETRICO (Nyx-7 hab 2)
-- ------------------------------------------------------------
local function actualizarAnclajeGravimetrico(dt, a)
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - a.zonaX
      local dy = e.y - a.zonaY
      local d2 = dx * dx + dy * dy
      if d2 < a.radio * a.radio then
        if e.aplicarSlow then e:aplicarSlow(0.2, a.factorSlow) end
        local d = math.sqrt(d2)
        if d > 8 then
          local pull = 40
          local nx = e.x - (dx / d) * pull * dt
          local ny = e.y - (dy / d) * pull * dt
          local Colisiones = require("src.sistemas.colisiones")
          if not Colisiones.circuloConMapa(nx, e.y, e.radio, J.salaActual.mapa) then e.x = nx end
          if not Colisiones.circuloConMapa(e.x, ny, e.radio, J.salaActual.mapa) then e.y = ny end
        end
      end
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    local dx = jf.x - a.zonaX
    local dy = jf.y - a.zonaY
    if dx * dx + dy * dy < a.radio * a.radio then
      if jf.aplicarSlow then jf:aplicarSlow(0.2, a.factorSlow) end
    end
  end

  if a.timer >= a.duracion then
    a.tipo = nil
    a.bloqueaMovimiento = false
  end
end

-- ------------------------------------------------------------
-- RAFAGA ORBITAL (Nyx-7 hab 3)
-- ------------------------------------------------------------
local function actualizarRafagaOrbitalActiva(dt, a)
  for _, r in ipairs(a.rayos or {}) do
    r.timer = r.timer + dt
    if not r.caido and r.timer >= r.delay then
      r.caido = true
      r.activo = true
      do
        local FXh = require("src.sistemas.fx_habilidades")
        local tx = (r.target and r.target.x) or r.x
        local ty = (r.target and r.target.y) or r.y
        if tx and ty then pcall(FXh.rayo, tx, ty, { 0.55, 0.85, 1.0 }) end
      end
      if r.target and r.target.vivo then
        r.x = r.target.x
        r.y = r.target.y
        local murio = r.target:recibirDanio(a.danoPorRayo)
        Helpers.reproducirImpacto()
        if murio then
          Helpers.reproducirMuerte()
          Helpers.soltarMonedas(r.target)
          if J.designtegrarEnemigo then J.designtegrarEnemigo(r.target) end
        end
      end
    end
  end

  if a.timer >= a.duracion then
    a.tipo = nil
    a.rayos = {}
    a.bloqueaMovimiento = false
  end
end

-- ============================================================
-- DISPATCHER
-- ============================================================

function J.actualizarAccionEspecial(dt)
  local a = J.accionEspecial
  if a.tipo == nil then return end

  a.timer = a.timer + dt

  if a.tipo == "carga_estocada" then
    actualizarCargaEstocada(dt, a)
  elseif a.tipo == "danza_cortante" then
    actualizarDanzaCortante(dt, a)
  elseif a.tipo == "esperando_marcadora" then
    actualizarEsperandoMarcadora(dt, a)
  elseif a.tipo == "zona_flechas" then
    actualizarZonaFlechas(dt, a)
  elseif a.tipo == "carga_rayo_arcano" then
    actualizarCargaRayoArcano(dt, a)
  elseif a.tipo == "carga_ira_carmesi" then
    actualizarCargaIraCarmesi(dt, a)
  elseif a.tipo == "ira_carmesi_activa" then
    actualizarIraCarmesiActiva(dt, a)
  elseif a.tipo == "furia_valquiria" then
    actualizarFuriaValquiria(dt, a)
  elseif a.tipo == "rafaga_coyote" then
    actualizarRafagaCoyote(dt, a)
  elseif a.tipo == "pasos_viento" then
    actualizarPasosViento(dt, a)
  elseif a.tipo == "carga_corte_vacio" then
    actualizarCargaCorteVacio(dt, a)
  elseif a.tipo == "anclaje_gravimetrico" then
    actualizarAnclajeGravimetrico(dt, a)
  elseif a.tipo == "rafaga_orbital_activa" then
    actualizarRafagaOrbitalActiva(dt, a)
  else
    -- Habilidades de los personajes nuevos (Shadow, Thorin, Rex, Sable)
    if J.actualizarAccionNueva then
      J.actualizarAccionNueva(dt, a)
    end
  end
end

return J