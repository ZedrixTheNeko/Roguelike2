-- ============================================================
-- JUGADOR - Efectos
-- ============================================================
-- Orbes, slow y otros estados alterados.

local Efectos = {}

-- ============================================================
-- ORBES (Merlin - Orbes de Fuego)
-- ============================================================

function Efectos:activarOrbes(cantidad, radioOrbita, dano, radioBola, duracion)
  self.orbsActivos = true
  self.orbsDuracionTotal = duracion or 5
  self.orbsTimer = self.orbsDuracionTotal
  self.orbsAngulo = 0
  self.orbs = {}

  for i = 1, cantidad do
    local ang = ((i - 1) / cantidad) * math.pi * 2
    table.insert(self.orbs, {
      angulo = ang,
      radioOrbita = radioOrbita,
      dano = dano,
      radioBola = radioBola,
    })
  end
end

-- ============================================================
-- SLOW (afectado por bola de slime del jefe, esporas, etc.)
-- ============================================================

function Efectos:aplicarSlow(duracion)
  self.slowTimer = math.max(self.slowTimer, duracion or 3.0)
end

-- ============================================================
-- SINFONIA BELICA (Lyra)
-- ============================================================

function Efectos:aplicarSinfonia(duracion, multDano, multVel, multCad)
  self.sinfoniaTimer = math.max(self.sinfoniaTimer or 0, duracion or 6.0)
  self.sinfoniaDano = multDano or 1.30
  self.sinfoniaVelocidad = multVel or 1.25
  self.sinfoniaCadencia = multCad or 1.50
end

return Efectos