local Consola = {}

Consola.mensajes = {}
Consola.maxMensajes = 30
Consola.tiempoVida = 15
Consola.printOriginal = print
Consola.instalada = false

-- Sustituye el print global por uno que tambien guarda el mensaje en un
-- buffer que luego se dibuja en pantalla (cuando debugConsola esta activo).
function Consola.instalar()
  if Consola.instalada then return end
  Consola.printOriginal = print
  print = function(...)
    local args = {...}
    local partes = {}
    for i = 1, #args do
      table.insert(partes, tostring(args[i]))
    end
    local texto = table.concat(partes, " ")

    table.insert(Consola.mensajes, {
      texto = texto,
      vida = Consola.tiempoVida,
      color = Consola.colorPara(texto),
    })

    while #Consola.mensajes > Consola.maxMensajes do
      table.remove(Consola.mensajes, 1)
    end

    Consola.printOriginal(texto)
  end
  Consola.instalada = true
end

-- Restaura el print original. Util si alguna vez quieres apagar por
-- completo la consola (por ejemplo en builds de release), pero no es
-- necesario llamarlo durante el gameplay normal: basta con no dibujarla.
function Consola.desinstalar()
  if not Consola.instalada then return end
  print = Consola.printOriginal
  Consola.instalada = false
end

function Consola.colorPara(texto)
  if texto:find("%[GUARDADO%]") then
    return {0.4, 0.85, 1.0}
  elseif texto:find("ERROR") or texto:find("Error") then
    return {1.0, 0.4, 0.4}
  elseif texto:find("WARN") or texto:find("warning") then
    return {1.0, 0.85, 0.4}
  elseif texto:find("%[DEBUG%]") then
    return {0.55, 1.0, 0.55}
  else
    return {0.9, 0.9, 0.9}
  end
end

function Consola.actualizar(dt)
  local i = 1
  while i <= #Consola.mensajes do
    local m = Consola.mensajes[i]
    m.vida = m.vida - dt
    if m.vida <= 0 then
      table.remove(Consola.mensajes, i)
    else
      i = i + 1
    end
  end
end

function Consola.dibujar(ancho, alto)
  local f = love.graphics.getFont()
  local altoMensaje = 14
  local padding = 8

  local numMensajes = #Consola.mensajes
  local alturaTotal
  if numMensajes == 0 then
    alturaTotal = altoMensaje + padding * 2
  else
    alturaTotal = numMensajes * altoMensaje + padding * 2
  end
  local anchoPanel = math.min(ancho - 20, 560)
  local y0 = alto - alturaTotal - 10

  -- Fondo semitransparente
  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.rectangle("fill", 10, y0, anchoPanel, alturaTotal, 4)

  -- Borde azul
  love.graphics.setColor(0.4, 0.7, 1.0, 0.7)
  love.graphics.rectangle("line", 10, y0, anchoPanel, alturaTotal, 4)

  -- Barra superior decorativa
  love.graphics.setColor(0.4, 0.7, 1.0, 0.35)
  love.graphics.rectangle("fill", 10, y0, anchoPanel, 2, 4)

  if numMensajes == 0 then
    love.graphics.setColor(0.55, 0.70, 0.90, 0.8)
    love.graphics.print("Consola activa (esperando mensajes...)", 20, y0 + padding + 2)
  else
    for i, m in ipairs(Consola.mensajes) do
      local alpha = math.min(1, m.vida / 2)
      love.graphics.setColor(m.color[1], m.color[2], m.color[3], alpha)
      love.graphics.print(m.texto, 20, y0 + padding + (i - 1) * altoMensaje)
    end
  end
end

function Consola.limpiar()
  Consola.mensajes = {}
end

function Consola.mensaje(texto)
  print("[DEBUG] " .. texto)
end

return Consola