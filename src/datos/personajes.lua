local personajes = {}

personajes.lista = {
  -- ============================================================
  -- 1) ROBIN — Arquera (arco)
  -- ============================================================
  {
    id = "robin",
    nombre = "Robin",
    tipo = "Arquera",
    arma = "Arco corto",
    desc1 = "Agil y precisa.",
    desc2 = "Ataca a distancia con su arco.",
    colorTunica = {0.35, 0.75, 0.45},
    colorCapa   = {0.25, 0.55, 0.35},
    colorPelo   = {0.55, 0.30, 0.15},
    colorPiel   = {1.00, 0.85, 0.70},
    tipoArma    = "arco",
    hpMax       = 6,
    escudoMax   = 3,
    velocidad   = 120,
    recursoTipo = "estamina",
    recursoMax  = 110,
    regenRecurso = 35,
    retrasoRegen = 1.5,
    costeAtaque     = 20,
    danoAtaque      = 4,
    cooldownAtaque  = 0.28,
    habilidades = {
      { nombre = "Dash Flechero", cooldown = 7.0, duracion = 5.0, buffVelocidad = 1.20, invulnerableDurante = 0.5 },
      { nombre = "Lluvia de Flechas", cooldown = 14.0, cantidad = 22, dano = 6, radio = 85, duracionZona = 2.5 },
      { nombre = "Flecha Perforante", cooldown = 15.0, dano = 14, velocidad = 400 },
    },
  },

  -- ============================================================
  -- 2) CONAN — Guerrero (espada)
  -- ============================================================
  {
    id = "conan",
    nombre = "Conan",
    tipo = "Guerrero",
    arma = "Espada de hierro",
    desc1 = "Fuerte y resistente.",
    desc2 = "Devastador cuerpo a cuerpo.",
    colorTunica = {0.75, 0.45, 0.35},
    colorCapa   = {0.55, 0.30, 0.20},
    colorPelo   = {0.18, 0.12, 0.08},
    colorPiel   = {1.00, 0.78, 0.62},
    tipoArma    = "espada",
    hpMax       = 10,
    escudoMax   = 5,
    velocidad   = 80,
    recursoTipo = "estamina",
    recursoMax  = 100,
    regenRecurso = 28,
    retrasoRegen = 1.8,
    costeAtaque     = 15,
    danoAtaque      = 9,
    cooldownAtaque  = 0.55,
    rangoMelee      = 22,
    habilidades = {
      { nombre = "Corte Noqueador", cooldown = 10.0, dano = 12, empuje = 200, stunDur = 3.0, rango = 60, apertura = math.rad(50), duracionAnim = 0.5, invulnerableDurante = 0.4 },
      { nombre = "Estocada Maestra", cooldown = 18.0, dano = 18, empuje = 320, cargaTiempo = 1.1, rango = 90, apertura = math.rad(25), invulnerableDurante = 1.3 },
      { nombre = "Danza Cortante", cooldown = 24.0, dano1 = 10, dano2 = 20, empuje = 250, duracionTotal = 1.5, invulnerableDurante = 1.5 },
    },
  },

  -- ============================================================
  -- 3) MERLIN — Mago (grimorio)
  -- ============================================================
  {
    id = "merlin",
    nombre = "Merlin",
    tipo = "Mago",
    arma = "Grimorio",
    desc1 = "Sabio misterioso.",
    desc2 = "Lanza magia elemental.",
    colorTunica = {0.55, 0.45, 0.85},
    colorCapa   = {0.40, 0.30, 0.65},
    colorPelo   = {0.85, 0.85, 0.88},
    colorPiel   = {1.00, 0.85, 0.75},
    tipoArma    = "grimorio",
    hpMax       = 5,
    escudoMax   = 2,
    velocidad   = 90,
    recursoTipo = "mana",
    recursoMax  = 150,
    regenRecurso = 24,
    retrasoRegen = 2.0,
    costeAtaque     = 12,
    danoAtaque      = 2.5,
    cooldownAtaque  = 0.35,
    velocidadProyectil = 200,
    habilidades = {
      { nombre = "Orbes de Fuego", cooldown = 10.0, cantidad = 3, dano = 15, danoExplosion = 25, radioExplosion = 55, duracionAnim = 0.4, invulnerableDurante = 0.4 },
      { nombre = "Rayo Arcano", cooldown = 16.0, cargaTiempo = 1.3, dano = 60, rango = 480, anchoRayo = 45, empuje = 260, invulnerableDurante = 1.8 },
      { nombre = "Ira Carmesi", cooldown = 75.0, cargaTiempo = 2.0, danoPorRayo = 55, radioExplosion = 65, invulnerableDurante = 3.0 },
    },
  },

  -- ============================================================
  -- 4) KAEL — Cazador de Sombras (bumeran)
  -- ============================================================
  {
    id = "kael",
    nombre = "Kael",
    tipo = "Cazador",
    arma = "Bumeran de obsidiana",
    desc1 = "Nomada de las estepas.",
    desc2 = "Sus bumeranes vuelven a el.",
    colorTunica = {0.55, 0.42, 0.28},
    colorCapa   = {0.35, 0.25, 0.15},
    colorPelo   = {0.15, 0.10, 0.05},
    colorPiel   = {0.80, 0.60, 0.45},
    tipoArma    = "bumeran",
    hpMax       = 6,
    escudoMax   = 3,
    velocidad   = 118,
    recursoTipo = "estamina",
    recursoMax  = 110,
    regenRecurso = 40,
    retrasoRegen = 1.2,
    costeAtaque     = 18,
    danoAtaque      = 5,
    cooldownAtaque  = 0.55,
    habilidades = {
      { nombre = "Lanzamiento Gemelo", cooldown = 8.0, cantidad = 2, dano = 6, velocidad = 260, invulnerableDurante = 0.3 },
      { nombre = "Ricochet Fatal", cooldown = 14.0, dano = 9, velocidad = 320, rebotes = 5, invulnerableDurante = 0.4 },
      { nombre = "Marca del Cazador", cooldown = 22.0, duracion = 6.0, multiplicadorDano = 1.4, radio = 200, invulnerableDurante = 0.5 },
    },
  },

  -- ============================================================
  -- 5) SHADOW — Asesino de dagas (era el "Kael" de la version nueva)
  -- ============================================================
  {
    id = "shadow",
    nombre = "Shadow",
    tipo = "Asesino",
    arma = "Dagas gemelas",
    desc1 = "Rapido y letal por la espalda.",
    desc2 = "Combos veloces y teletransporte.",
    colorTunica = {0.30, 0.22, 0.42},
    colorCapa   = {0.16, 0.12, 0.25},
    colorPelo   = {0.85, 0.85, 0.92},
    colorPiel   = {0.95, 0.80, 0.68},
    tipoArma    = "dagas",
    hpMax       = 5,
    escudoMax   = 2,
    velocidad   = 112,
    recursoTipo = "estamina",
    recursoMax  = 100,
    regenRecurso = 34,
    retrasoRegen = 1.2,
    costeAtaque     = 9,
    danoAtaque      = 4.5,
    cooldownAtaque  = 0.24,
    habilidades = {
      { nombre = "Paso Sombrio", cooldown = 6.0, dano = 9, distancia = 105, invulnerableDurante = 0.4 },
      { nombre = "Lluvia de Dagas", cooldown = 11.0, cantidad = 9, dano = 5, apertura = math.rad(120) },
      { nombre = "Ejecucion", cooldown = 20.0, golpes = 6, dano = 8, rango = 210, duracion = 1.3 },
    },
  },

  -- ============================================================
  -- 6) BRUNILDA — Valquiria (lanza)
  -- ============================================================
  {
    id = "brunilda",
    nombre = "Brunilda",
    tipo = "Valquiria",
    arma = "Lanza de Odin",
    desc1 = "Guerrera del Valhalla.",
    desc2 = "Tanque sagrada con arma arrojadiza.",
    colorTunica = {0.85, 0.75, 0.35},
    colorCapa   = {0.55, 0.15, 0.20},
    colorPelo   = {0.90, 0.85, 0.60},
    colorPiel   = {1.00, 0.85, 0.75},
    tipoArma    = "lanza",
    hpMax       = 10,
    escudoMax   = 5,
    velocidad   = 78,
    recursoTipo = "estamina",
    recursoMax  = 110,
    regenRecurso = 26,
    retrasoRegen = 2.0,
    costeAtaque     = 18,
    danoAtaque      = 8,
    cooldownAtaque  = 0.35,
    rangoMelee      = 26,
    danoArrojado    = 12,
    habilidades = {
      { nombre = "Carga del Cuervo", cooldown = 9.0, dano = 10, empuje = 280, distancia = 90, invulnerableDurante = 0.6 },
      { nombre = "Lluvia de Valquiria", cooldown = 13.0, dano = 22, radio = 60, velocidad = 300, invulnerableDurante = 0.5 },
      { nombre = "Furia del Valhalla", cooldown = 28.0, duracion = 4.0, radio = 100, danoFinal = 30, invulnerableDurante = 4.0 },
    },
  },

  -- ============================================================
  -- 7) COYOTE — Pistolero (revolver)
  -- ============================================================
  {
    id = "coyote",
    nombre = "Coyote",
    tipo = "Pistolero",
    arma = "Colmillo de Serpiente",
    desc1 = "Forajido del desierto.",
    desc2 = "Precision letal a larga distancia.",
    colorTunica = {0.45, 0.32, 0.22},
    colorCapa   = {0.65, 0.55, 0.40},
    colorPelo   = {0.25, 0.15, 0.08},
    colorPiel   = {0.85, 0.65, 0.50},
    tipoArma    = "revolver",
    hpMax       = 6,
    escudoMax   = 2,
    velocidad   = 108,
    recursoTipo = "balas",
    recursoMax  = 6,
    regenRecurso = 0,
    retrasoRegen = 0,
    costeAtaque     = 1,
    danoAtaque      = 7,
    cooldownAtaque  = 0.32,
    velocidadProyectil = 480,
    habilidades = {
      { nombre = "Doble Revolver", cooldown = 45.0, duracion = 30.0, invulnerableDurante = 0.3 },
      { nombre = "Rafaga Rapida", cooldown = 12.0, invulnerableDurante = 0.3 },
      { nombre = "El Ultimo Aliento", cooldown = 30.0, dano = 10, balas = 6, duracionSlow = 1.5, factorSlow = 0.30, invulnerableDurante = 1.0 },
    },
  },

  -- ============================================================
  -- 8) SHEN — Samurai (katana) — sinergias propias
  -- ============================================================
  {
    id = "shen",
    nombre = "Shen",
    tipo = "Samurai",
    arma = "Katana Corte de Luna",
    desc1 = "Espadachin sin maestro.",
    desc2 = "Cortes rapidos con combo devastador.",
    colorTunica = {0.15, 0.12, 0.18},
    colorCapa   = {0.65, 0.15, 0.20},
    colorPelo   = {0.08, 0.06, 0.05},
    colorPiel   = {0.95, 0.80, 0.65},
    tipoArma    = "katana",
    hpMax       = 8,
    escudoMax   = 4,
    velocidad   = 102,
    recursoTipo = "estamina",
    recursoMax  = 105,
    regenRecurso = 32,
    retrasoRegen = 1.4,
    costeAtaque     = 14,
    danoAtaque      = 7,
    cooldownAtaque  = 0.30,
    rangoMelee      = 24,
    habilidades = {
      { nombre = "Iai (Desenvaine)", cooldown = 8.0, dano = 11, rango = 50, multiplicadorCercano = 2.0, radioCercano = 20, invulnerableDurante = 0.6 },
      { nombre = "Pasos de Viento", cooldown = 12.0, dashes = 3, danoEstela = 3, distancia = 55, invulnerableDurante = 1.2 },
      { nombre = "Corte del Vacio", cooldown = 25.0, dano = 45, cargaTiempo = 0.8, rango = 80, empuje = 400, invulnerableDurante = 2.0 },
    },
  },

  -- ============================================================
  -- 9) SABLE — Samurai de la version nueva (katana) — estilo souls
  -- ============================================================
  {
    id = "sable",
    nombre = "Sable",
    tipo = "Samurai Errante",
    arma = "Katana Lunar",
    desc1 = "Disciplina y precision mortal.",
    desc2 = "Parry, iaido y cien cortes.",
    colorTunica = {0.75, 0.20, 0.25},
    colorCapa   = {0.20, 0.20, 0.28},
    colorPelo   = {0.08, 0.06, 0.10},
    colorPiel   = {0.98, 0.84, 0.70},
    tipoArma    = "katana",
    hpMax       = 7,
    escudoMax   = 2,
    velocidad   = 96,
    recursoTipo = "estamina",
    recursoMax  = 100,
    regenRecurso = 30,
    retrasoRegen = 1.4,
    costeAtaque     = 12,
    danoAtaque      = 7,
    cooldownAtaque  = 0.32,
    habilidades = {
      { nombre = "Contraataque", cooldown = 8.0, ventana = 0.7, dano = 28, radio = 70, stunDur = 1.8 },
      { nombre = "Iaido", cooldown = 12.0, dano = 24, distancia = 165, invulnerableDurante = 0.35 },
      { nombre = "Cien Cortes", cooldown = 24.0, golpes = 10, dano = 6, radio = 80, duracion = 1.3 },
    },
  },

  -- ============================================================
  -- 10) NYX-7 — Cazadora Estelar (ballesta de plasma)
  -- ============================================================
  {
    id = "nyx",
    nombre = "Nyx-7",
    tipo = "Cazadora Estelar",
    arma = "Ballesta de plasma Ferro",
    desc1 = "Unidad hibrida de combate.",
    desc2 = "Drones y tecnologia de soporte.",
    colorTunica = {0.35, 0.40, 0.55},
    colorCapa   = {0.20, 0.45, 0.60},
    colorPelo   = {0.55, 0.75, 0.90},
    colorPiel   = {0.88, 0.92, 0.95},
    tipoArma    = "ballesta_plasma",
    hpMax       = 5,
    escudoMax   = 3,
    velocidad   = 102,
    recursoTipo = "energia",
    recursoMax  = 130,
    regenRecurso = 30,
    retrasoRegen = 1.6,
    costeAtaque     = 14,
    danoAtaque      = 4,
    cooldownAtaque  = 0.32,
    velocidadProyectil = 340,
    habilidades = {
      { nombre = "Dron Centinela", cooldown = 16.0, duracion = 8.0, dano = 3, cadencia = 0.5, invulnerableDurante = 0.5 },
      { nombre = "Anclaje Gravimetrico", cooldown = 14.0, radio = 80, duracion = 4.0, factorSlow = 0.40, invulnerableDurante = 0.5 },
      { nombre = "Rafaga Orbital", cooldown = 26.0, rayos = 5, dano = 14, duracion = 2.0, invulnerableDurante = 1.5 },
    },
  },

  -- ============================================================
  -- 11) LYRA — Barda (lira)
  -- ============================================================
  {
    id = "lyra",
    nombre = "Lyra",
    tipo = "Barda",
    arma = "Lira de cuerdas lunares",
    desc1 = "Musica que altera el alma.",
    desc2 = "Soporte y control con ondas sonoras.",
    colorTunica = {0.50, 0.30, 0.70},
    colorCapa   = {0.35, 0.20, 0.50},
    colorPelo   = {0.80, 0.55, 0.85},
    colorPiel   = {1.00, 0.85, 0.80},
    tipoArma    = "lira",
    hpMax       = 7,
    escudoMax   = 4,
    velocidad   = 92,
    recursoTipo = "mana",
    recursoMax  = 140,
    regenRecurso = 26,
    retrasoRegen = 1.8,
    costeAtaque     = 10,
    danoAtaque      = 3,
    cooldownAtaque  = 0.40,
    velocidadProyectil = 240,
    habilidades = {
      { nombre = "Cancion de Cuna", cooldown = 15.0, duracion = 3.0, rango = 100, apertura = math.rad(90), invulnerableDurante = 0.5 },
      { nombre = "Nota Resonante", cooldown = 10.0, dano = 8, radio = 70, empuje = 220, invulnerableDurante = 0.4 },
      { nombre = "Sinfonia Belica", cooldown = 30.0, duracion = 6.0, multiplicadorDano = 1.30, multiplicadorVelocidad = 1.25, multiplicadorCadencia = 1.50, invulnerableDurante = 0.5 },
    },
  },

  -- ============================================================
  -- 12) THORIN — Paladin (martillo) — de la version nueva
  -- ============================================================
  {
    id = "thorin",
    nombre = "Thorin",
    tipo = "Paladin",
    arma = "Martillo sagrado",
    desc1 = "Muro viviente de fe y acero.",
    desc2 = "Golpes lentos que aplastan.",
    colorTunica = {0.80, 0.70, 0.35},
    colorCapa   = {0.55, 0.15, 0.15},
    colorPelo   = {0.45, 0.28, 0.12},
    colorPiel   = {0.96, 0.78, 0.62},
    tipoArma    = "martillo",
    hpMax       = 12,
    escudoMax   = 4,
    velocidad   = 68,
    recursoTipo = "estamina",
    recursoMax  = 110,
    regenRecurso = 26,
    retrasoRegen = 1.8,
    costeAtaque     = 18,
    danoAtaque      = 11,
    cooldownAtaque  = 0.85,
    habilidades = {
      { nombre = "Escudo Sagrado", cooldown = 12.0, duracion = 2.4, radio = 34 },
      { nombre = "Terremoto", cooldown = 14.0, dano = 14, radio = 90, stunDur = 2.0, empuje = 260 },
      { nombre = "Juicio Divino", cooldown = 26.0, cargaTiempo = 1.2, dano = 26, radio = 38, rayos = 5 },
    },
  },

  -- ============================================================
  -- 13) REX — Ingeniero (rifle de plasma) — de la version nueva
  -- ============================================================
  {
    id = "rex",
    nombre = "Rex",
    tipo = "Ingeniero",
    arma = "Rifle de plasma",
    desc1 = "Fuego automatico y artilugios.",
    desc2 = "Torretas, granadas y sobrecarga.",
    colorTunica = {0.25, 0.55, 0.65},
    colorCapa   = {0.18, 0.30, 0.38},
    colorPelo   = {0.90, 0.55, 0.15},
    colorPiel   = {0.90, 0.70, 0.55},
    tipoArma    = "rifle",
    hpMax       = 6,
    escudoMax   = 3,
    velocidad   = 95,
    recursoTipo = "mana",
    recursoMax  = 170,
    regenRecurso = 42,
    retrasoRegen = 1.0,
    costeAtaque     = 5,
    danoAtaque      = 1.9,
    cooldownAtaque  = 0.11,
    habilidades = {
      { nombre = "Torreta Automatica", cooldown = 13.0, duracion = 10.0, dano = 2.5, cadencia = 0.33 },
      { nombre = "Granada de Racimo", cooldown = 10.0, dano = 20, radio = 52, minis = 6, danoMini = 6, mecha = 0.8 },
      { nombre = "Sobrecarga", cooldown = 22.0, duracion = 6.0 },
    },
  },
}

personajes.actual = 1

function personajes.actualData()
  return personajes.lista[personajes.actual]
end

return personajes