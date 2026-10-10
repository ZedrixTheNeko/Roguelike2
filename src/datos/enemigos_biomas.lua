-- Datos de los enemigos nuevos (uno o mas por bioma).
-- Cada uno usa un "arquetipo" de comportamiento (ver entidades/enemigo/nuevos.lua)
local d = {}

-- ========== BOSQUE MALDITO ==========
d.lobo_sombra = {
  nombre = "Lobo de sombra", arquetipo = "embestidor",
  hpMax = 34, radio = 8, anchoDibujo = 20, altoDibujo = 12,
  danoContacto = 0, danoEmbestida = 2,
  velocidad = 62, velEmbestida = 250, duracionEmbestida = 0.42,
  alcanceEmbestida = 170, aviso = 0.55, descanso = 0.9, cooldown = 1.2,
  monedasAlMorir = 3, paleta = "lobo",
}

d.hongo_toxico = {
  nombre = "Hongo toxico", arquetipo = "torreta",
  hpMax = 36, radio = 9, anchoDibujo = 18, altoDibujo = 18,
  danoContacto = 0, modo = "radial", cantidad = 8, velProyectil = 75, danoProyectil = 1,
  tipoProyectil = "espora", cooldown = 3.2, aviso = 0.7, alcance = 260,
  monedasAlMorir = 3, paleta = "hongo",
}

d.arana_venenosa = {
  nombre = "Arana venenosa", arquetipo = "kiter",
  hpMax = 26, radio = 7, anchoDibujo = 16, altoDibujo = 12,
  danoContacto = 1, velocidad = 70, rangoMinimo = 70, rangoIdeal = 120, rangoDisparo = 190,
  cooldown = 2.4, aviso = 0.45, cantidad = 1, apertura = 0, velProyectil = 120,
  danoProyectil = 1, tipoProyectil = "espora",
  monedasAlMorir = 3, paleta = "arana",
}

-- ========== FORJA DE MAGMA ==========
d.salamandra = {
  nombre = "Salamandra", arquetipo = "kiter",
  hpMax = 38, radio = 8, anchoDibujo = 20, altoDibujo = 12,
  danoContacto = 1, velocidad = 66, rangoMinimo = 90, rangoIdeal = 140, rangoDisparo = 210,
  cooldown = 2.6, aviso = 0.5, cantidad = 2, apertura = 14, velProyectil = 145,
  danoProyectil = 2, tipoProyectil = "bola_fuego",
  monedasAlMorir = 4, paleta = "salamandra",
}

d.golem_menor = {
  nombre = "Golem de lava", arquetipo = "aplastador",
  hpMax = 130, radio = 12, anchoDibujo = 26, altoDibujo = 28,
  danoContacto = 1, danoAtaque = 3, velocidad = 34,
  rangoAtaque = 46, radioImpacto = 52, aviso = 0.85, descanso = 0.9, cooldown = 1.4,
  monedasAlMorir = 7, paleta = "golem",
}

d.espiritu_fuego = {
  nombre = "Espiritu de fuego", arquetipo = "kamikaze",
  hpMax = 16, radio = 6, anchoDibujo = 14, altoDibujo = 14,
  danoContacto = 0, danoExplosion = 2, radioExplosion = 38,
  velocidad = 92, velCarga = 150, aviso = 0.55, distanciaActivar = 52,
  monedasAlMorir = 2, paleta = "fuego",
}

-- ========== GLACIAR ETERNO ==========
d.yeti = {
  nombre = "Yeti", arquetipo = "embestidor",
  hpMax = 78, radio = 11, anchoDibujo = 26, altoDibujo = 26,
  danoContacto = 0, danoEmbestida = 3,
  velocidad = 44, velEmbestida = 210, duracionEmbestida = 0.55,
  alcanceEmbestida = 190, aviso = 0.75, descanso = 1.6, cooldown = 1.0,
  aturdeAlChocar = 1.8,
  monedasAlMorir = 6, paleta = "yeti",
}

d.cristal_helado = {
  nombre = "Cristal helado", arquetipo = "torreta",
  hpMax = 46, radio = 9, anchoDibujo = 16, altoDibujo = 24,
  danoContacto = 0, modo = "dirigida", cantidad = 3, apertura = 16,
  velProyectil = 135, danoProyectil = 1, tipoProyectil = "esquirla_hielo",
  cooldown = 2.5, aviso = 0.6, alcance = 280,
  monedasAlMorir = 4, paleta = "cristal",
}

d.fantasma_escarcha = {
  nombre = "Espectro de escarcha", arquetipo = "blink",
  hpMax = 30, radio = 8, anchoDibujo = 18, altoDibujo = 24,
  danoContacto = 0, velocidad = 36,
  distanciaMin = 100, distanciaMax = 150, cooldown = 2.6, aviso = 0.5,
  modoAtaque = "disparo", cantidad = 3, apertura = 18, velProyectil = 120,
  danoProyectil = 1, tipoProyectil = "esquirla_hielo",
  monedasAlMorir = 5, paleta = "escarcha",
}

-- ========== SANTUARIO DEL VACIO ==========
d.acechador_vacio = {
  nombre = "Acechador del vacio", arquetipo = "blink",
  hpMax = 40, radio = 8, anchoDibujo = 18, altoDibujo = 24,
  danoContacto = 0, velocidad = 52,
  distanciaMin = 24, distanciaMax = 34, cooldown = 2.2, aviso = 0.5,
  modoAtaque = "tajo", danoAtaque = 2, rangoTajo = 46, aperturaTajo = 60,
  monedasAlMorir = 6, paleta = "vacio",
}

d.ojo_del_vacio = {
  nombre = "Ojo del vacio", arquetipo = "rayo",
  hpMax = 44, radio = 9, anchoDibujo = 22, altoDibujo = 22,
  danoContacto = 0, velocidad = 34, distanciaIdeal = 150,
  cooldown = 3.4, aviso = 1.0, duracionRayo = 0.30, anchoRayo = 12, largoRayo = 360,
  danoRayo = 2,
  monedasAlMorir = 6, paleta = "ojo",
}

d.caballero_vacio = {
  nombre = "Caballero del vacio", arquetipo = "duelista",
  hpMax = 90, radio = 9, anchoDibujo = 22, altoDibujo = 28,
  danoContacto = 0, danoAtaque = 2, velocidad = 54, velocidadGuardia = 40,
  rangoAtaque = 40, aperturaTajo = 62, aviso = 0.46, golpesCombo = 3,
  recuperacion = 1.1, cooldown = 1.0, reduccionGuardia = 0.75,
  monedasAlMorir = 8, paleta = "caballero",
}

return d