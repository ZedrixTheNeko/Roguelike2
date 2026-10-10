-- ============================================================
-- HABILIDADES DE COYOTE (Pistolero)
-- ============================================================
-- 1. Doble Revolver: buff 30s (dos revolveres, ataque doble)
-- 2. Rafaga Rapida: vacia el cargador en 0.4s
-- 3. El Ultimo Aliento: slow-mo + rafaga ancha perforante
--
-- Con Dual Wield activo:
--   - Rafaga Rapida dispara 2 balas por tick.
--   - El Ultimo Aliento dispara el doble de balas.

local J       = require("src.estados.juego.estado")
local Helpers = require("src.estados.juego.habilidades.helpers")

-- ============================================================
-- HABILIDAD 1: Doble Revolver
-- ============================================================
-- Activa el buff de dual wield durante 30s.
-- Mientras esta activo, el ataque normal dispara 2 balas y la
-- habilidad 2 dispara al doble. La habilidad 3 duplica balas.

function J.habilidadCoyote1()
  local h = J.robin.personaje.habilidades[1]

  J.robin.dualWield = h.duracion   -- 30s

  -- Efecto visual: anillo dorado expansivo
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "dual_wield_activado",
    vida = 0.8,
    duracion = 0.8,
    radio = 60,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.3)
  Helpers.reproducirDisparo()
end

-- ============================================================
-- HABILIDAD 2: Rafaga Rapida
-- ============================================================
-- Dispara todas las balas del cargador en 0.4s (una cada 0.067s).
-- Si dualWield activo, dispara 2 balas por tick (consume 2 balas).
-- Si se queda sin balas, la rafaga se corta naturalmente.

function J.habilidadCoyote2()
  local h = J.robin.personaje.habilidades[2]

  if J.robin.recargando then return end
  if J.robin.recurso <= 0 then return end

  J.accionEspecial.tipo = "rafaga_coyote"
  J.accionEspecial.timer = 0
  J.accionEspecial.duracion = 0.4
  J.accionEspecial.fase = 1
  J.accionEspecial.particulas = {}
  J.accionEspecial.golpeAplicado = {}
  J.accionEspecial.bloqueaMovimiento = false
  J.accionEspecial.intervalo = 0.067    -- ~6 balas en 0.4s
  J.accionEspecial.timerDisparo = 0
  J.accionEspecial.direccionX = J.robin.ultimaDirX
  J.accionEspecial.direccionY = J.robin.ultimaDirY

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 0.3)
end

-- ============================================================
-- HABILIDAD 3: El Ultimo Aliento
-- ============================================================
-- Slow-mo 1.5s + rafaga ancha de 6 balas perforantes.
-- Con dualWield, dispara 12 balas.

function J.habilidadCoyote3()
  local h = J.robin.personaje.habilidades[3]
  local anguloBase = math.atan2(J.robin.ultimaDirY, J.robin.ultimaDirX)

  -- Slow motion
  J.tiempoSlow = h.duracionSlow or 1.5
  J.factorSlow = h.factorSlow or 0.30

  local dualActivo = (J.robin.dualWield or 0) > 0
  local balasBase = h.balas or 6
  local total = dualActivo and (balasBase * 2) or balasBase

  -- Disparar las balas en un cono estrecho
  local apertura = math.rad(25)

  for i = 1, total do
    local t = (i - 1) / (total - 1) - 0.5
    local ang = anguloBase + t * apertura
    local p = J.poolFlechas:obtener()
    if p then
      p:lanzar(J.robin.x, J.robin.y, math.cos(ang), math.sin(ang),
        550, h.dano, false, "bala_perforante")
    end
  end

  -- Efecto visual
  table.insert(J.cortes, {
    x = J.robin.x, y = J.robin.y,
    angulo = 0,
    tipo = "slowmo_activado",
    vida = 0.5,
    duracion = 0.5,
    radio = 80,
  })

  J.robin.invulnerable = math.max(J.robin.invulnerable, h.invulnerableDurante or 1.0)
  Helpers.reproducirDisparo()
end

return true