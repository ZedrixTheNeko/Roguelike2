-- ============================================================
-- FX DE HABILIDADES (shaders): explosiones, rayos del cielo y ondas.
-- Pensado para ser barato:
--   * maximo 6 efectos simultaneos (el mas viejo se descarta),
--   * un solo quad pequeno por efecto, aditivo,
--   * se desactiva solo con shaders OFF o calidad BAJA,
--   * todo dentro de pcall: un fallo nunca rompe el juego.
-- Los efectos visuales clasicos del juego siguen funcionando debajo.
-- ============================================================
local Shaders = require("src.utils.shaders")
local Config = require("src.datos.config")

local FX = {}
FX.lista = {}
local MAX = 6

local function activo()
  return Shaders.activo and Shaders.calidad >= 2 and Config.get("efectosVisuales") ~= false
end

local function agregar(e)
  if not activo() then return end
  -- evita apilar el mismo efecto en el mismo punto
  for _, o in ipairs(FX.lista) do
    if o.tipo == e.tipo and o.t < 0.12 and math.abs(o.x - e.x) < 8 and math.abs(o.y - e.y) < 8 then
      return
    end
  end
  if #FX.lista >= MAX then table.remove(FX.lista, 1) end
  e.t = 0
  e.semilla = math.random() * 10
  FX.lista[#FX.lista + 1] = e
end

function FX.reset() FX.lista = {} end

function FX.explosion(x, y, radio, color)
  color = color or { 1.0, 0.55, 0.15 }
  agregar({ tipo = "explosion", x = x, y = y, r = math.max(18, radio) * 1.35,
            dur = 0.55, color = color })
end

function FX.onda(x, y, radio, color)
  color = color or { 0.9, 0.8, 0.5 }
  agregar({ tipo = "onda", x = x, y = y, r = math.max(24, radio), dur = 0.5, color = color, plano = true })
end

-- Rayo que cae del cielo sobre (x, y)
function FX.rayo(x, y, color)
  color = color or { 0.6, 0.8, 1.0 }
  agregar({ tipo = "rayo", x = x, y = y, r = 0, dur = 0.5, color = color })
end

-- Se llama una vez por cada "corte" (efecto de habilidad) nuevo
function FX.desdeCorte(c)
  local t = c.tipo
  if t == "explosion_fuego" then FX.explosion(c.x, c.y, c.radio or 40, { 1.0, 0.55, 0.15 })
  elseif t == "explosion_sagrada" then FX.explosion(c.x, c.y, c.radio or 40, { 1.0, 0.88, 0.45 })
  elseif t == "explosion_vacio" then FX.explosion(c.x, c.y, c.radio or 40, { 0.7, 0.3, 1.0 })
  elseif t == "explosion_valquiria" then FX.explosion(c.x, c.y, c.radio or 40, { 1.0, 0.3, 0.35 })
  elseif t == "onda_tierra" then FX.onda(c.x, c.y, c.radio or 80, { 0.95, 0.78, 0.4 })
  elseif t == "impacto_martillo" then FX.onda(c.x, c.y, (c.radio or 28) * 1.3, { 1.0, 0.92, 0.55 })
  elseif t == "pilar_luz" then FX.rayo(c.x, c.y, { 1.0, 0.92, 0.5 })
  end
end

function FX.actualizar(dt)
  local i = 1
  while i <= #FX.lista do
    local e = FX.lista[i]
    e.t = e.t + dt
    if e.t >= e.dur then table.remove(FX.lista, i) else i = i + 1 end
  end
end

-- Dibujar en coordenadas del mundo (dentro de la camara)
function FX.dibujar()
  if #FX.lista == 0 or not activo() then return end
  local modo = love.graphics.getBlendMode()
  love.graphics.setBlendMode("add")
  for _, e in ipairs(FX.lista) do
    local k = e.t / e.dur
    local c = e.color
    if e.tipo == "explosion" then
      Shaders.efecto("explosion", e.x - e.r, e.y - e.r, e.r * 2, e.r * 2, c[1], c[2], c[3], 1, k, e.semilla)
      Shaders.luz(e.x, e.y, e.r * 1.6, c[1], c[2], c[3], 0.45 * (1 - k))
    elseif e.tipo == "onda" then
      local alto = e.r * 2 * 0.6
      Shaders.efecto("onda", e.x - e.r, e.y - alto / 2, e.r * 2, alto, c[1], c[2], c[3], 1, k, e.semilla)
    elseif e.tipo == "rayo" then
      local h = 240
      Shaders.efecto("rayo", e.x - 32, e.y - h, 64, h, c[1], c[2], c[3], 1, k, e.semilla)
      Shaders.luz(e.x, e.y, 70, c[1], c[2], c[3], 0.6 * (1 - k))
    end
  end
  love.graphics.setBlendMode(modo)
end

return FX
