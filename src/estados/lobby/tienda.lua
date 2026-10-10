local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Boton      = require("src.ui.boton")
local Guardado   = require("src.datos.guardado")
local sonidos    = require("src.datos.sonidos")

local Tienda = {}

-- Precio de compra: 150% del valor original
local PRECIO_MULTIPLICADOR = 1.5

function Tienda.abrir()
  L.tienda.abierta = true
  L.tienda.pestana = "recuperar"
  L.tienda.objetoSeleccionado = nil
  L.tienda.botones = {}
  Tienda.construirBotones()
end

function Tienda.cerrar()
  L.tienda.abierta = false
  L.tienda.botones = {}
end

function Tienda.construirBotones()
  L.tienda.botones = {}

  -- Boton cerrar
  L.tienda.botonCerrarTienda = Boton.nuevo(
    constantes.ANCHO_VIRTUAL - 100,
    constantes.ALTO_VIRTUAL - 40,
    90, 30, "Cerrar",
    function() Tienda.cerrar() end)

  -- Tabs
  local tabW, tabH = 160, 34
  local tabsY = 70
  local cx = constantes.ANCHO_VIRTUAL / 2

  L.tienda.botonTabRecuperar = Boton.nuevo(cx - tabW - 8, tabsY, tabW, tabH, "Recuperar", function()
    L.tienda.pestana = "recuperar"
    Tienda.reconstruirItems()
  end)

  L.tienda.botonTabComprar = Boton.nuevo(cx + 8, tabsY, tabW, tabH, "Objetos", function()
    L.tienda.pestana = "comprar"
    Tienda.reconstruirItems()
  end)

  Tienda.reconstruirItems()
end

function Tienda.reconstruirItems()
  -- Quitar botones de items viejos (los que tienen "item_")
  local filtrados = {}
  for _, b in ipairs(L.tienda.botones) do
    if not b.esItem then table.insert(filtrados, b) end
  end
  L.tienda.botones = filtrados

  if L.tienda.pestana == "recuperar" then
    Tienda.construirItemsRecuperar()
  elseif L.tienda.pestana == "comprar" then
    Tienda.construirItemsComprar()
  end
end

function Tienda.construirItemsRecuperar()
  local inventario = Guardado.get("mack").inventario
  local y = 130
  local cx = constantes.ANCHO_VIRTUAL / 2

  if #inventario == 0 then
    return  -- Nada que mostrar
  end

  for i, obj in ipairs(inventario) do
    if i > 8 then break end  -- Maximo 8 items visibles

    local texto, precio
    if obj.tipo == "gema" then
      texto = obj.cantidad .. " gemas perdidas (Nv " .. obj.nivel .. ")"
      precio = math.floor(obj.cantidad * PRECIO_MULTIPLICADOR)
    else
      texto = "Objeto desconocido"
      precio = 0
    end

    local btn = Boton.nuevo(cx - 200, y, 400, 34,
      texto .. "  -  " .. precio .. "G",
      function()
        Tienda.comprarItem(i)
      end)
    btn.esItem = true
    table.insert(L.tienda.botones, btn)

    y = y + 40
  end
end

function Tienda.construirItemsComprar()
  -- Placeholder: en el proximo mensaje metemos pociones y objetos
  local cx = constantes.ANCHO_VIRTUAL / 2
  local y = 130
  local btn = Boton.nuevo(cx - 200, y, 400, 34, "Proximamente mas objetos...", function() end)
  btn.esItem = true
  table.insert(L.tienda.botones, btn)
end

function Tienda.comprarItem(indice)
  local inventario = Guardado.get("mack").inventario
  local obj = inventario[indice]
  if not obj then return end

  local precio
  if obj.tipo == "gema" then
    precio = math.floor(obj.cantidad * PRECIO_MULTIPLICADOR)
  else
    return
  end

  if not Guardado.gastarGemas(precio) then
    -- Sin gemas suficientes
    if sonidos.danio_jugador then sonidos.danio_jugador:stop() sonidos.danio_jugador:play() end
    return
  end

  -- Recuperar las gemas
  Guardado.datos.gemas = Guardado.datos.gemas + obj.cantidad
  table.remove(inventario, indice)
  Guardado.guardar()

  -- Sonido de exito
  if sonidos.cura then sonidos.cura:stop() sonidos.cura:play() end

  -- Reconstruir lista
  Tienda.reconstruirItems()
end

function Tienda.dibujar()
  if not L.tienda.abierta then return end

  -- Fondo oscuro
  love.graphics.setColor(0, 0, 0, 0.88)
  love.graphics.rectangle("fill", 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)

  -- Panel central
  local pw, ph = 500, constantes.ALTO_VIRTUAL - 40
  local px = (constantes.ANCHO_VIRTUAL - pw) / 2
  local py = 20

  love.graphics.setColor(0.10, 0.12, 0.18, 0.98)
  love.graphics.rectangle("fill", px, py, pw, ph, 8)
  love.graphics.setColor(0.55, 0.70, 0.95)
  love.graphics.rectangle("line", px, py, pw, ph, 8)

  -- Titulo
  love.graphics.setColor(1, 0.85, 0.40)
  local f = love.graphics.getFont()
  local txt = "Mack Tuercas Locas"
  local tw = f:getWidth(txt) * 1.3
  love.graphics.print(txt, (constantes.ANCHO_VIRTUAL - tw) / 2, py + 12, 0, 1.3, 1.3)

  love.graphics.setColor(0.75, 0.85, 1.0)
  local sub = "\"Vendo lo que perdiste, vaquero\""
  local twSub = f:getWidth(sub) * 0.85
  love.graphics.print(sub, (constantes.ANCHO_VIRTUAL - twSub) / 2, py + 40, 0, 0.85, 0.85)

  -- Gemas del jugador (arriba a la derecha del panel)
  local gemas = Guardado.get("gemas")
  love.graphics.setColor(0.30, 0.90, 0.95)
  love.graphics.polygon("fill",
    constantes.ANCHO_VIRTUAL - 130, py + 20,
    constantes.ANCHO_VIRTUAL - 122, py + 28,
    constantes.ANCHO_VIRTUAL - 130, py + 36,
    constantes.ANCHO_VIRTUAL - 138, py + 28)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(tostring(gemas), constantes.ANCHO_VIRTUAL - 112, py + 20)

  -- Tabs
  L.tienda.botonTabRecuperar:dibujar()
  L.tienda.botonTabComprar:dibujar()

  -- Resaltar tab activa
  local tabActivaY = 70
  local tabActivaX
  if L.tienda.pestana == "recuperar" then
    tabActivaX = constantes.ANCHO_VIRTUAL / 2 - 160 - 8
  else
    tabActivaX = constantes.ANCHO_VIRTUAL / 2 + 8
  end
  love.graphics.setColor(0.95, 0.80, 0.30, 0.9)
  love.graphics.rectangle("fill", tabActivaX, tabActivaY + 32, 160, 2)

  -- Mensaje si no hay items
  if L.tienda.pestana == "recuperar" then
    local inv = Guardado.get("mack").inventario
    if #inv == 0 then
      love.graphics.setColor(0.75, 0.80, 0.88)
      local msg = "No tienes nada pendiente."
      local msg2 = "Cuando mueras, tu 50% caera aqui."
      local twM = f:getWidth(msg)
      local twM2 = f:getWidth(msg2)
      love.graphics.print(msg, (constantes.ANCHO_VIRTUAL - twM) / 2, 160)
      love.graphics.setColor(0.55, 0.62, 0.72)
      love.graphics.print(msg2, (constantes.ANCHO_VIRTUAL - twM2) / 2, 185)
    end
  end

  -- Dibujar botones de items
  for _, b in ipairs(L.tienda.botones) do
    b:dibujar()
  end

  -- Boton cerrar
  L.tienda.botonCerrarTienda:dibujar()
end

function Tienda.touchpressed(id, x, y)
  if not L.tienda.abierta then return false end
  if L.tienda.botonTabRecuperar:touchpressed(id, x, y) then return true end
  if L.tienda.botonTabComprar:touchpressed(id, x, y) then return true end
  if L.tienda.botonCerrarTienda:touchpressed(id, x, y) then return true end
  for _, b in ipairs(L.tienda.botones) do
    if b:touchpressed(id, x, y) then return true end
  end
  return true  -- Bloquea cualquier otro toque
end

function Tienda.touchreleased(id, x, y)
  if not L.tienda.abierta then return false end
  L.tienda.botonTabRecuperar:touchreleased(id, x, y)
  L.tienda.botonTabComprar:touchreleased(id, x, y)
  L.tienda.botonCerrarTienda:touchreleased(id, x, y)
  for _, b in ipairs(L.tienda.botones) do
    b:touchreleased(id, x, y)
  end
  return true
end

return Tienda