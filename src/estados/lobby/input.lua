local L       = require("src.estados.lobby.estado")
local Tienda  = require("src.estados.lobby.tienda")
local Mejoras = require("src.estados.lobby.mejoras")
local Estados = require("src.sistemas.estados")

-- ============================================================
-- HELPERS
-- ============================================================

local function tiendaAbierta()
  return L.tienda and L.tienda.abierta
end

local function mejorasAbierto()
  return L.mejoras and L.mejoras.abierto
end

local function sobreBoton(b, x, y)
  if not b then return false end
  return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

local function sobreBotonInteractuar(x, y)
  if not L.botonInteractuar or L.botonInteractuar.oculto then return false end
  return sobreBoton(L.botonInteractuar, x, y)
end

-- ============================================================
-- TOUCH
-- ============================================================

function L.touchpressed(id, x, y)
  if L.saliendo then return end
  if L.cambioPersonaje and L.cambioPersonaje.activo then return end

  if tiendaAbierta() then
    Tienda.touchpressed(id, x, y)
    return
  end
  if mejorasAbierto() then
    Mejoras.touchpressed(id, x, y)
    return
  end

  if L.estado == "explorando" then
    if not L.botonInteractuar.oculto and L.botonInteractuar:touchpressed(id, x, y) then
      return
    end
    L.joyMover:touchpressed(id, x, y)

  elseif L.estado == "preguntando" then
    L.botonSi:touchpressed(id, x, y)
    L.botonNo:touchpressed(id, x, y)

  elseif L.estado == "dialogo" then
    L.botonCerrar:touchpressed(id, x, y)

  elseif L.estado == "seleccion" then
    L.seleccionTouchpressed(id, x, y)
  end
end

function L.touchmoved(id, x, y)
  if L.saliendo then return end
  if L.cambioPersonaje and L.cambioPersonaje.activo then return end

  if tiendaAbierta() then return end
  if mejorasAbierto() then return end

  if L.estado == "explorando" then
    L.joyMover:touchmoved(id, x, y)
  elseif L.estado == "seleccion" then
    L.seleccionTouchmoved(id, x, y)
  end
end

function L.touchreleased(id, x, y)
  if L.saliendo then return end

  if tiendaAbierta() then
    Tienda.touchreleased(id, x, y)
    return
  end
  if mejorasAbierto() then
    Mejoras.touchreleased(id, x, y)
    return
  end

  if L.estado == "explorando" then
    L.botonInteractuar:touchreleased(id, x, y)
    L.joyMover:touchreleased(id, x, y)

  elseif L.estado == "preguntando" then
    L.botonSi:touchreleased(id, x, y)
    L.botonNo:touchreleased(id, x, y)

  elseif L.estado == "dialogo" then
    L.botonCerrar:touchreleased(id, x, y)

  elseif L.estado == "seleccion" then
    L.seleccionTouchreleased(id, x, y)
  end
end

-- ============================================================
-- KEYBOARD
-- ============================================================

function L.keypressed(key)
  if L.saliendo then return end
  if L.cambioPersonaje and L.cambioPersonaje.activo then return end

  if key == "escape" then
    if tiendaAbierta() then
      Tienda.cerrar()
    elseif mejorasAbierto() then
      Mejoras.cerrar()
    elseif L.estado == "dialogo" then
      L.estado = "explorando"
      L.dialogoTitulo = nil
      L.dialogoTexto = nil
    elseif L.estado == "preguntando" then
      L.estado = "explorando"
    elseif L.estado == "seleccion" then
      L.estado = "explorando"
    elseif L.estado == "explorando" then
      Estados.cambiar("menu")
    end
  end
end

return L