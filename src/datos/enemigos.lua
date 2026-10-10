local enemigos = {
  slime_pequeno = {
    nombre       = "Slime pequeño",
    hpMax        = 28,
    radio        = 7,
    anchoDibujo  = 14,
    altoDibujo   = 12,
    danoContacto = 1,
    velocidad    = 110,
    duracionSalto = 0.35,
    esperaMin    = 0.15,
    esperaMax    = 0.35,
    monedasAlMorir = 1,
    tipo         = "saltador",
  },

  esqueleto_guardia = {
    nombre       = "Guardia esqueleto",
    hpMax        = 55,
    radio        = 9,
    anchoDibujo  = 18,
    altoDibujo   = 22,
    danoContacto = 0,
    danoAtaque   = 2,
    velocidad    = 58,
    rangoCorte   = 32,
    rangoEstocada = 68,
    windupCorte  = 0.38,
    windupEstocada = 0.50,
    duracionCorte = 0.15,
    duracionEstocada = 0.28,
    rangoGolpeCorte = 34,
    rangoGolpeEstocada = 44,
    cooldownAtaque = 1.0,
    monedasAlMorir = 3,
    tipo         = "cuerpo_a_cuerpo",
  },

  esqueleto_arquero = {
    nombre       = "Arquero esqueleto",
    hpMax        = 28,
    radio        = 8,
    anchoDibujo  = 16,
    altoDibujo   = 20,
    danoContacto = 0,
    velocidad    = 55,
    rangoMinimo  = 80,
    rangoIdeal   = 160,
    rangoDisparo = 190,
    cooldownDisparo = 2.4,
    danoFlecha   = 1,
    velocidadFlecha = 150,
    factorPrediccion = 0.30,
    dispersionGrados = 20,
    monedasAlMorir = 3,
    tipo         = "arquero",
  },

  rata_gigante = {
    nombre       = "Rata gigante",
    hpMax        = 18,
    radio        = 7,
    anchoDibujo  = 16,
    altoDibujo   = 12,
    danoContacto = 1,
    velocidad    = 95,
    tipo         = "perseguidor_rapido",
    monedasAlMorir = 2,
  },

  murcielago = {
    nombre       = "Murcielago",
    hpMax        = 20,
    radio        = 7,
    anchoDibujo  = 16,
    altoDibujo   = 12,
    danoContacto = 1,
    velocidad    = 105,
    tipo         = "volador_erratico",
    monedasAlMorir = 2,
  },

  mago_oscuro = {
    nombre       = "Mago oscuro",
    hpMax        = 32,
    radio        = 9,
    anchoDibujo  = 18,
    altoDibujo   = 24,
    danoContacto = 0,
    velocidad    = 50,
    rangoMinimo  = 100,
    rangoIdeal   = 180,
    rangoDisparo = 230,
    cooldownDisparo = 2.6,
    danoProyectil = 2,
    velocidadProyectil = 140,
    monedasAlMorir = 4,
    tipo         = "mago",
  },
}

-- Configuracion global de elites
enemigos.elite = {
  hpMultiplicador       = 2.5,
  radioMultiplicador    = 1.4,
  danoMultiplicador     = 1.5,
  velocidadMultiplicador = 0.85,
  monedasMultiplicador  = 2,
  escalaVisual          = 1.3,
  -- Aura de color (dorado brillante)
  colorAura             = {1.0, 0.85, 0.30},
}

-- Enemigos de los biomas nuevos (se cargan desde su propio archivo)
for k, v in pairs(require("src.datos.enemigos_biomas")) do
  enemigos[k] = v
end

return enemigos