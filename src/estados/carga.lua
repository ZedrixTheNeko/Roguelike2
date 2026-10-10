local constantes = require("src.constantes")
local Estados = require("src.sistemas.estados")
local sonidos = require("src.datos.sonidos")
local Biomas = require("src.datos.biomas")

local carga = {}

local letras = {}
local tiempoTotal = 0
local todoCayo = false
local blinkTimer = 0
local delayFinal = 0
local nivelCargando = 1

function carga.entrar(nivel)
  nivelCargando = nivel or 1
  letras = {}
  tiempoTotal = 0
  todoCayo = false
  blinkTimer = 0
  delayFinal = 0

  local textoCompleto = "Nivel " .. tostring(nivelCargando) .. " - " .. Biomas.paraNivel(nivelCargando).nombre
  if nivelCargando % 3 == 0 then
    textoCompleto = textoCompleto .. "  (JEFE)"
  end

  local f = love.graphics.getFont()
  local baseX = 14
  local baseY = constantes.ALTO_VIRTUAL - 20
  local accX = baseX

  for i = 1, #textoCompleto do
    local c = textoCompleto:sub(i, i)
    local w = f:getWidth(c)
    table.insert(letras, {
      c = c,
      x = accX,
      baseY = baseY,
      y = baseY - 40 - i * 6,
      targetY = baseY,
      vy = 0,
      landed = false,
      startDelay = 0.15 + i * 0.05,
      activa = false,
      fase = 0,
      indexBase = i,
    })
    accX = accX + w
  end
end

function carga.actualizar(dt)
  tiempoTotal = tiempoTotal + dt

  local todasListas = true
  for _, l in ipairs(letras) do
    if tiempoTotal >= l.startDelay then l.activa = true end

    if l.activa and not l.landed then
      todasListas = false
      l.vy = l.vy + 900 * dt
      l.y = l.y + l.vy * dt

      if l.y >= l.targetY then
        l.y = l.targetY
        if math.abs(l.vy) > 60 then
          l.vy = -l.vy * 0.30
          if sonidos.letra_cae then
            sonidos.letra_cae:stop()
            sonidos.letra_cae:play()
          end
        else
          l.vy = 0
          l.landed = true
        end
      end
    elseif not l.activa then
      todasListas = false
    end
  end

  if todasListas and not todoCayo then
    todoCayo = true
    delayFinal = 0
  end

  if todoCayo then
    delayFinal = delayFinal + dt
    blinkTimer = blinkTimer + dt
    for _, l in ipairs(letras) do
      local fase = blinkTimer * 4 - l.indexBase * 0.4
      l.y = l.targetY - math.abs(math.sin(fase)) * 4
    end
  end
end

function carga.dibujar()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  love.graphics.setColor(1, 1, 1)
  for _, l in ipairs(letras) do
    if l.activa then
      love.graphics.print(l.c, l.x, l.y)
    end
  end

  if todoCayo and delayFinal > 0.6 then
    local alpha = 0.5 + 0.5 * math.sin(blinkTimer * 4)
    love.graphics.setColor(1, 1, 1, alpha)
    local txt = "Pulsa para comenzar"
    local f = love.graphics.getFont()
    local tw = f:getWidth(txt)
    love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, constantes.ALTO_VIRTUAL - 60)
  end
end

function carga.touchpressed(id, x, y)
  if todoCayo and delayFinal > 0.6 then
    Estados.cambiar("juego", nivelCargando, false)
  end
end

function carga.mousepressed(x, y, b)
  carga.touchpressed(-1, x, y)
end

function carga.keypressed(key)
  if todoCayo and delayFinal > 0.6 then
    Estados.cambiar("juego", nivelCargando, false)
  end
end

return carga