local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Boton      = require("src.ui.boton")
local Guardado   = require("src.datos.guardado")
local Progreso   = require("src.datos.progreso")
local Personajes = require("src.datos.personajes")
local sonidos    = require("src.datos.sonidos")

local Mejoras = {}

local botonesCompra = {}
local botonCerrar = nil
local listaMejoras = {}
local personajeActualId = nil

local COLORES = {
  vida = {0.85, 0.30, 0.35},
  dano = {0.90, 0.55, 0.20},
  velocidad = {0.35, 0.80, 0.45},
  habilidad = {0.55, 0.50, 0.95},
}

local ICONOS = {
  vida = "HP",
  dano = "DMG",
  velocidad = "SPD",
  habilidad = "CD",
}

local DESCRIPCIONES = {
  vida = "+2 vida maxima por nivel",
  dano = "+15% dano por nivel",
  velocidad = "+8% velocidad por nivel",
  habilidad = "-12% cooldown habilidad por nivel",
}

function Mejoras.abrir()
  L.mejoras.abierto = true
  L.mejoras.botones = {}
  L.mejoras.mensaje = nil
  L.mejoras.timerMensaje = 0

  personajeActualId = Personajes.actualData().id
  Mejoras.reconstruir()
end

function Mejoras.cerrar()
  L.mejoras.abierto = false
  botonesCompra = {}
end

function Mejoras.reconstruir()
  botonesCompra = {}
  listaMejoras = Progreso.listarMejoras(personajeActualId)

  local px = constantes.ANCHO_VIRTUAL / 2
  local y0 = 145
  local saltoY = 46

  for i, m in ipairs(listaMejoras) do
    local y = y0 + (i - 1) * saltoY
    local boton = Boton.nuevo(px + 140, y, 110, 32, "Comprar", function()
      Mejoras.intentarComprar(i)
    end)
    boton.mejoraIdx = i
    table.insert(botonesCompra, boton)
  end

  botonCerrar = Boton.nuevo(constantes.ANCHO_VIRTUAL / 2 - 70,
                            constantes.ALTO_VIRTUAL - 45,
                            140, 32, "Cerrar", function()
    Mejoras.cerrar()
  end)
end

function Mejoras.intentarComprar(idx)
  local m = listaMejoras[idx]
  if not m then return end

  if m.comprado then
    L.mejoras.mensaje = "Ya esta al maximo"
    L.mejoras.timerMensaje = 1.5
    if sonidos.danio_jugador then
      sonidos.danio_jugador:stop()
      sonidos.danio_jugador:play()
    end
    return
  end

  local exito, razon = Progreso.comprar(personajeActualId, m.id)
  if exito then
    L.mejoras.mensaje = "Comprado! " .. (DESCRIPCIONES[m.id] or "")
    L.mejoras.timerMensaje = 2.0
    if sonidos.cura then
      sonidos.cura:stop()
      sonidos.cura:play()
    end

    -- Aplicar cambios al jugador del lobby
    if L.robin then
      L.robin:aplicarPersonaje()
      if m.id == "vida" then
        L.robin.hp = L.robin.hpMax
      end
    end

    Mejoras.reconstruir()
  elseif razon == "sin_gemas" then
    L.mejoras.mensaje = "Gemas insuficientes"
    L.mejoras.timerMensaje = 1.5
    if sonidos.danio_jugador then
      sonidos.danio_jugador:stop()
      sonidos.danio_jugador:play()
    end
  elseif razon == "al_maximo" then
    L.mejoras.mensaje = "Ya esta al maximo"
    L.mejoras.timerMensaje = 1.5
  end
end

function Mejoras.dibujar()
  if not L.mejoras.abierto then return end

  -- NOTA: el timer del mensaje ahora se decrementa en
  -- src/estados/lobby/actualizar.lua usando el dt real.
  -- Antes usaba (1/60) fijo y se desincronizaba a >60 FPS.

  love.graphics.setColor(0, 0, 0, 0.90)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  local pw = 500
  local ph = constantes.ALTO_VIRTUAL - 30
  local px = (constantes.ANCHO_VIRTUAL - pw) / 2
  local py = 15

  love.graphics.setColor(0.10, 0.08, 0.12, 0.98)
  love.graphics.rectangle("fill", px, py, pw, ph, 8)
  love.graphics.setColor(0.75, 0.45, 0.20)
  love.graphics.rectangle("line", px, py, pw, ph, 8)

  love.graphics.setColor(0.75, 0.45, 0.20, 0.4)
  love.graphics.rectangle("fill", px + 10, py + 5, pw - 20, 2)

  love.graphics.setColor(1, 0.75, 0.35)
  local f = love.graphics.getFont()
  local titulo = "HERRERIA DEL GREMIO"
  local twT = f:getWidth(titulo) * 1.4
  love.graphics.print(titulo, (constantes.ANCHO_VIRTUAL - twT) / 2, py + 12, 0, 1.4, 1.4)

  local p = Personajes.actualData()
  love.graphics.setColor(0.90, 0.88, 0.92)
  local sub = "Mejorando: " .. p.nombre .. " (" .. p.tipo .. ")"
  local twS = f:getWidth(sub)
  love.graphics.print(sub, (constantes.ANCHO_VIRTUAL - twS) / 2, py + 42)

  love.graphics.setColor(0.75, 0.45, 0.20, 0.6)
  love.graphics.rectangle("fill", px + 20, py + 62, pw - 40, 1)

  love.graphics.setColor(0.70, 0.72, 0.80)
  local instr = "Gasta gemas para mejorar a tu personaje de forma permanente."
  local twI = f:getWidth(instr)
  love.graphics.print(instr, (constantes.ANCHO_VIRTUAL - twI) / 2, py + 76)

  local y0 = 145
  local saltoY = 46

  for i, m in ipairs(listaMejoras) do
    local y = y0 + (i - 1) * saltoY
    local color = COLORES[m.id] or {0.6, 0.6, 0.6}

    -- Panel
    love.graphics.setColor(color[1] * 0.20, color[2] * 0.20, color[3] * 0.20, 0.6)
    love.graphics.rectangle("fill", px + 15, y - 4, pw - 30, 42, 4)
    love.graphics.setColor(color[1], color[2], color[3], 0.7)
    love.graphics.rectangle("line", px + 15, y - 4, pw - 30, 42, 4)

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", px + 15, y - 4, 4, 42, 4)

    -- Icono
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", px + 28, y + 2, 38, 26, 3)
    love.graphics.setColor(0.05, 0.05, 0.08)
    love.graphics.print(ICONOS[m.id] or "?", px + 33, y + 8)

    -- Nombre
    love.graphics.setColor(0.95, 0.95, 1.0)
    love.graphics.print(m.nombre, px + 74, y - 2)

    -- Descripcion
    love.graphics.setColor(0.65, 0.72, 0.85)
    local desc = DESCRIPCIONES[m.id] or ""
    love.graphics.print(desc, px + 74, y + 12, 0, 0.75, 0.75)

    -- Puntos de nivel
    for k = 1, m.maxNivel do
      local dx = px + 74 + (k - 1) * 12
      if k <= m.nivel then
        love.graphics.setColor(color)
        love.graphics.circle("fill", dx, y + 28, 4)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("line", dx, y + 28, 4)
      else
        love.graphics.setColor(0.30, 0.32, 0.40)
        love.graphics.circle("line", dx, y + 28, 4)
      end
    end

    -- Costo
    if m.comprado then
      love.graphics.setColor(0.55, 0.95, 0.55)
      local txt = "MAX"
      local tw2 = f:getWidth(txt) * 1.1
      love.graphics.print(txt, px + 260 - tw2 / 2, y + 8, 0, 1.1, 1.1)
    else
      local costo = m.costo or 0
      love.graphics.setColor(0.30, 0.90, 0.95)
      love.graphics.polygon("fill",
        px + 205, y + 10,
        px + 213, y + 18,
        px + 205, y + 26,
        px + 197, y + 18)
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(tostring(costo), px + 220, y + 10)
    end

    -- Boton
    local b = botonesCompra[i]
    if b then
      if m.comprado then
        love.graphics.setColor(0.20, 0.22, 0.28, 0.7)
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 3)
        love.graphics.setColor(0.40, 0.42, 0.50)
        love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 3)
        love.graphics.setColor(0.50, 0.52, 0.60)
        local txt = "Completo"
        local tw3 = f:getWidth(txt)
        love.graphics.print(txt, b.x + b.w / 2 - tw3 / 2, b.y + 9)
      else
        local gemas = Guardado.get("gemas") or 0
        if gemas < (m.costo or 0) then
          love.graphics.setColor(0.40, 0.15, 0.15)
          love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 3)
          love.graphics.setColor(0.75, 0.30, 0.30)
          love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 3)
          love.graphics.setColor(1, 1, 1)
          local txt = "Comprar"
          local tw3 = f:getWidth(txt)
          love.graphics.print(txt, b.x + b.w / 2 - tw3 / 2, b.y + 9)
        else
          love.graphics.setColor(0.25, 0.55, 0.30)
          love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 3)
          love.graphics.setColor(0.55, 0.95, 0.60)
          love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 3)
          love.graphics.setColor(1, 1, 1)
          local txt = "Comprar"
          local tw3 = f:getWidth(txt)
          love.graphics.print(txt, b.x + b.w / 2 - tw3 / 2, b.y + 9)
        end
      end
    end
  end

  botonCerrar:dibujar()

  if L.mejoras.mensaje then
    local alpha = math.min(1, L.mejoras.timerMensaje * 3)
    if L.mejoras.mensaje:find("Comprado") then
      love.graphics.setColor(0.55, 0.95, 0.55, alpha)
    elseif L.mejoras.mensaje:find("insuficientes") then
      love.graphics.setColor(1, 0.45, 0.45, alpha)
    else
      love.graphics.setColor(0.95, 0.85, 0.40, alpha)
    end
    local twM = f:getWidth(L.mejoras.mensaje)
    love.graphics.print(L.mejoras.mensaje, (constantes.ANCHO_VIRTUAL - twM) / 2, constantes.ALTO_VIRTUAL - 78)
  end

  local gemas = Guardado.get("gemas") or 0
  love.graphics.setColor(0.30, 0.90, 0.95)
  love.graphics.polygon("fill",
    constantes.ANCHO_VIRTUAL - 105, py + 24,
    constantes.ANCHO_VIRTUAL - 97, py + 32,
    constantes.ANCHO_VIRTUAL - 105, py + 40,
    constantes.ANCHO_VIRTUAL - 113, py + 32)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(tostring(gemas), constantes.ANCHO_VIRTUAL - 92, py + 24)
end

function Mejoras.touchpressed(id, x, y)
  if not L.mejoras.abierto then return end
  for _, b in ipairs(botonesCompra) do
    if b:touchpressed(id, x, y) then return end
  end
  botonCerrar:touchpressed(id, x, y)
end

function Mejoras.touchreleased(id, x, y)
  if not L.mejoras.abierto then return end
  for _, b in ipairs(botonesCompra) do
    b:touchreleased(id, x, y)
  end
  botonCerrar:touchreleased(id, x, y)
end

return Mejoras