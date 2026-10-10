-- ============================================================
-- HABILIDADES DE MERLIN (Mago)
-- ============================================================
-- 1. Orbes de Fuego (homing + explosion)
-- 2. Rayo Arcano (carga + laser)
-- 3. Ira Carmesi (multiples rayos del cielo)

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades._helpers")

-- ============================================================
-- HABILIDAD 1: Orbes de Fuego
-- ============================================================
-- Lanza 3 orbes que persiguen enemigos y explotan al impactar.

function J.habilidadMerlin1()
  local h = J.robin.personaje.habilidades[1]

  local candidatos = {}

  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      local dx = e.x - J.robin.x
      local dy = e.y - J.robin.y
      local d2 = dx * dx + dy * dy
      table.insert(candidatos, { enemigo = e, dist = d2 })
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local dx = J.salaActual.jefe.x - J.robin.x
    local dy = J.salaActual.jefe.y - J.robin.y
    local d2 = dx * dx + dy * dy
    table.insert(candidatos, { enemigo = J.salaActual.jefe, dist = d2 })
  end

  table.sort(candidatos, function(a, b) return a.dist < b.dist end)

  local lanzados = 0
  for _, c in ipairs(candidatos) do
    if lanzados >= h.cantidad then break end
    lanzados = lanzados + 1

    local p = J.poolFlechas:obtener()
    if p then
      local ang = math.atan2(c.enemigo.y - J.robin.y, c.enemigo.x - J.robin.x)
      p:lanzar(J.robin.x, J.robin.y, math.cos(ang), math.sin(ang), 240,
        h.dano, false, "orbe_fuego")
      p.target = c.enemigo
      p.danoExplosion = h.danoExplosion
      p.radioExplosion = h.radioExplosion
    end
  end

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
  Helpers.reproducirFuego()
end

-- ============================================================
-- HABILIDAD 2: Rayo Arcano
-- ============================================================
-- Carga durante 1.3s y lanza un laser recto.

function J.habilidadMerlin2()
  local h = J.robin.personaje.habilidades[2]
  J.accionEspecial.tipo = "carga_rayo_arcano"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.cargaTiempo
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
end

function J.ejecutarRayoArcano()
  local h = J.robin.personaje.habilidades[2]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)

  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = anguloBase,
    tipo = "rayo_arcano",
    vida = 0.7,
    duracion = 0.7,
    rango = h.rango,
    ancho = h.anchoRayo,
  })

  local dx = math.cos(anguloBase)
  local dy = math.sin(anguloBase)

  local function procesar(e)
    if e == nil then return end
    if not e.vivo then return end
    local ex = e.x - J.robin.x
    local ey = e.y - J.robin.y
    local proj = ex * dx + ey * dy
    local perpX = ex - proj * dx
    local perpY = ey - proj * dy
    local perp = math.sqrt(perpX * perpX + perpY * perpY)
    if proj > 0 and proj < h.rango + e.radio and perp < h.anchoRayo / 2 + e.radio then
      local murio = e:recibirDanio(h.dano)
      if e.aplicarKnockback then
        e:aplicarKnockback(dx, dy, h.empuje)
      end
      Helpers.reproducirImpacto()
      if murio then
        Helpers.reproducirMuerte()
        Helpers.soltarMonedas(e)
      end
    end
  end

  for _, e in ipairs(J.salaActual.enemigos) do procesar(e) end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    procesar(J.salaActual.jefe)
  end

  Helpers.reproducirImpacto()
end

-- ============================================================
-- HABILIDAD 3: Ira Carmesi
-- ============================================================
-- Carga 2s y hace caer rayos sobre todos los enemigos visibles.

function J.habilidadMerlin3()
  local h = J.robin.personaje.habilidades[3]
  J.accionEspecial.tipo = "carga_ira_carmesi"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = h.cargaTiempo
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = true
  J.accionEspecial.objetivos = {}
  J.accionEspecial.rayos = {}
  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante)
end

function J.ejecutarIraCarmesi()
  local h = J.robin.personaje.habilidades[3]

  local enemigos = {}
  for _, e in ipairs(J.salaActual.enemigos) do
    if e.vivo then
      table.insert(enemigos, e)
    end
  end

  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    table.insert(enemigos, J.salaActual.jefe)
  end

  for i, e in ipairs(enemigos) do
    local retraso = 0.1 + (i - 1) * 0.08 + math.random() * 0.15
    table.insert(J.accionEspecial.rayos, {
      target = e,
      delay = retraso,
      timer = 0,
      activo = false,
      caido = false,
    })
  end

  J.accionEspecial.tipo = "ira_carmesi_activa"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = 2.0
  J.accionEspecial.bloqueaMovimiento = false
end

return true