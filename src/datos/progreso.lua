local Progreso = {}
local Guardado = require("src.datos.guardado")
local Personajes = require("src.datos.personajes")

Progreso.MEJORAS = {
  vida = {
    nombre = "Vida extra",
    descripcion = "+2 vida maxima por nivel",
    icono = "corazon",
    maxNivel = 5,
    costoBase = 25,
    costoIncremento = 20,
    valorPorNivel = 2,
  },
  dano = {
    nombre = "Fuerza bruta",
    descripcion = "+15% dano por nivel",
    icono = "espada",
    maxNivel = 5,
    costoBase = 30,
    costoIncremento = 25,
    valorPorNivel = 0.15,
  },
  velocidad = {
    nombre = "Reflejos",
    descripcion = "+8% velocidad por nivel",
    icono = "bota",
    maxNivel = 5,
    costoBase = 25,
    costoIncremento = 20,
    valorPorNivel = 0.08,
  },
  habilidad = {
    nombre = "Maestria arcana",
    descripcion = "-12% cooldown de habilidades",
    icono = "estrella",
    maxNivel = 3,
    costoBase = 50,
    costoIncremento = 40,
    valorPorNivel = 0.12,
  },
}

function Progreso.nivelMejora(personajeId, mejoraId)
  local mejoras = Guardado.get("mejoras")
  if not mejoras or not mejoras[personajeId] then return 0 end
  return mejoras[personajeId][mejoraId] or 0
end

function Progreso.costoSiguiente(personajeId, mejoraId)
  local def = Progreso.MEJORAS[mejoraId]
  if not def then return nil end
  local nivelActual = Progreso.nivelMejora(personajeId, mejoraId)
  if nivelActual >= def.maxNivel then return nil end
  return def.costoBase + def.costoIncremento * nivelActual
end

function Progreso.comprar(personajeId, mejoraId)
  local costo = Progreso.costoSiguiente(personajeId, mejoraId)
  if not costo then return false, "al_maximo" end

  local datos = Guardado.datos
  if not datos then
    Guardado.cargar()
    datos = Guardado.datos
  end

  if datos.gemas < costo then
    return false, "sin_gemas"
  end

  datos.gemas = datos.gemas - costo

  if not datos.mejoras[personajeId] then
    datos.mejoras[personajeId] = {}
  end
  datos.mejoras[personajeId][mejoraId] =
    (datos.mejoras[personajeId][mejoraId] or 0) + 1

  Guardado.guardar()

  return true
end

function Progreso.aplicarAlJugador(jugador)
  local p = Personajes.actualData()
  local id = p.id

  local nivelVida = Progreso.nivelMejora(id, "vida")
  if nivelVida > 0 then
    jugador.hpMax = jugador.hpMax + nivelVida * 2
    if jugador.hp > jugador.hpMax then jugador.hp = jugador.hpMax end
  end

  local nivelDano = Progreso.nivelMejora(id, "dano")
  if nivelDano > 0 then
    jugador.danoAtaque = jugador.danoAtaque * (1 + nivelDano * 0.15)
  end

  local nivelVel = Progreso.nivelMejora(id, "velocidad")
  if nivelVel > 0 then
    jugador.velocidad = jugador.velocidad * (1 + nivelVel * 0.08)
  end

  local nivelHab = Progreso.nivelMejora(id, "habilidad")
  if nivelHab > 0 and jugador.personaje and jugador.personaje.habilidades then
    local reduccion = 1 - nivelHab * 0.12
    for _, h in ipairs(jugador.personaje.habilidades) do
      h.cooldown = h.cooldown * reduccion
    end
  end
end

function Progreso.listarMejoras(personajeId)
  local lista = {}
  local orden = { "vida", "dano", "velocidad", "habilidad" }
  for _, id in ipairs(orden) do
    local def = Progreso.MEJORAS[id]
    local nivel = Progreso.nivelMejora(personajeId, id)
    local costo = Progreso.costoSiguiente(personajeId, id)
    table.insert(lista, {
      id = id,
      nombre = def.nombre,
      descripcion = def.descripcion,
      icono = def.icono,
      nivel = nivel,
      maxNivel = def.maxNivel,
      costo = costo,
      comprado = (nivel >= def.maxNivel),
    })
  end
  return lista
end

return Progreso