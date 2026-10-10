local sonidos = {}

local RATE = 11025

local function crear(duracion, generador)
  local samples = math.floor(RATE * duracion)
  local data = love.sound.newSoundData(samples, RATE, 16, 1)
  for i = 0, samples - 1 do
    local t = i / RATE
    local p = i / samples
    local s = generador(t, p)
    if s > 1 then s = 1 elseif s < -1 then s = -1 end
    data:setSample(i, s)
  end
  return love.audio.newSource(data, "static")
end

function sonidos.cargar()
  sonidos.disparo = crear(0.06, function(t, p)
    local env = math.max(0, 1 - p * 1.6)
    return math.sin(t * 900 * 2 * math.pi) * env * 0.85
  end)

  sonidos.impacto = crear(0.07, function(t, p)
    local env = math.max(0, 1 - p * 1.3)
    local s = math.sin(t * 280 * 2 * math.pi)
    if s > 0 then s = 1 else s = -1 end
    return s * env * 0.80
  end)

  sonidos.muerte_enemigo = crear(0.20, function(t, p)
    local freq = 500 * (1 - p * 0.9)
    local env = math.max(0, 1 - p)
    return math.sin(t * freq * 2 * math.pi) * env * 0.85
  end)

  sonidos.danio_jugador = crear(0.20, function(t, p)
    local env = math.max(0, 1 - p)
    local s = math.sin(t * 220 * 2 * math.pi)
    s = s + 0.5 * math.sin(t * 110 * 2 * math.pi)
    return s * env * 0.85
  end)

  sonidos.portal_entrar = crear(0.55, function(t, p)
    local freq = 200 + 600 * (1 - p)
    local env = math.sin(p * math.pi)
    return math.sin(t * freq * 2 * math.pi) * env * 0.80
  end)

  sonidos.nivel_completo = crear(0.35, function(t, p)
    local freq
    if p < 0.5 then freq = 523 else freq = 784 end
    local env = math.max(0, 1 - (p % 0.5) * 2)
    return math.sin(t * freq * 2 * math.pi) * env * 0.85
  end)

  sonidos.letra_cae = crear(0.07, function(t, p)
    local env = math.max(0, 1 - p * 1.5)
    return math.sin(t * 220 * 2 * math.pi) * env * 0.80
  end)

  sonidos.cura = crear(0.35, function(t, p)
    local freq = 400 + 500 * p
    local env = math.sin(p * math.pi)
    return math.sin(t * freq * 2 * math.pi) * env * 0.80
  end)

  sonidos.compra = crear(0.15, function(t, p)
    local env = math.max(0, 1 - p)
    return math.sin(t * 700 * 2 * math.pi) * env * 0.80
  end)

  sonidos.corte = crear(0.10, function(t, p)
    local env = math.max(0, 1 - p * 1.2)
    local s = math.sin(t * 500 * 2 * math.pi)
    s = s + 0.6 * math.sin(t * 900 * 2 * math.pi)
    return s * env * 0.75
  end)

  sonidos.fuego = crear(0.14, function(t, p)
    local env = math.max(0, 1 - p * 0.9)
    local s = math.sin(t * 180 * 2 * math.pi)
    s = s + 0.5 * math.sin(t * 340 * 2 * math.pi + t * 60)
    return s * env * 0.75
  end)
end

return sonidos