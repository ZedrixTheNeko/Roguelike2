local L          = require("src.estados.lobby.estado")
local constantes = require("src.constantes")
local Boton      = require("src.ui.boton")
local Personajes = require("src.datos.personajes")
local sonidos    = require("src.datos.sonidos")

-- ============================================================
-- PALETA
-- ============================================================
local AZUL_PROFUNDO = {0.05, 0.08, 0.20}
local AZUL_MEDIO    = {0.15, 0.35, 0.75}
local AZUL_BRILLO   = {0.55, 0.85, 1.00}
local AZUL_CLARO    = {0.85, 0.95, 1.00}
local DORADO        = {1.00, 0.80, 0.30}
local DORADO_CLARO  = {1.00, 0.95, 0.65}

-- ============================================================
-- ESTADO DEL SCROLL Y DEL TAP
-- ============================================================
local scrollY = 0
local scrollObjetivo = 0
local scrollMax = 0

local arrastrandoScroll = false
local touchScrollId = nil
local arrastreInicialY = 0
local scrollInicial = 0
local ultimoDeltaY = 0

-- Tap sobre un boton de personaje (cancelado si se arrastra)
local tapId = nil
local tapIdx = nil
local tapX = 0
local tapY = 0
local tapMovido = false

-- Region de la lista scrollable
local listaX, listaY, listaW, listaH = 0, 0, 0, 0

-- ============================================================
-- HELPERS
-- ============================================================

local function esquina(x, y, ox, oy, color, alpha, s)
  s = s or 6
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(2)
  love.graphics.line(x, y, x + s * ox, y)
  love.graphics.line(x, y, x, y + s * oy)
  love.graphics.setLineWidth(1)
end

local function dibujarBotonArcanoEn(x, y, w, h, texto, esHover, colorBase)
  love.graphics.setColor(0.08, 0.12, 0.24, 0.92)
  love.graphics.rectangle("fill", x, y, w, h, 4)
  love.graphics.setColor(0.20, 0.32, 0.58, 0.45)
  love.graphics.rectangle("fill", x, y, w, h * 0.5, 4)
  love.graphics.setColor(0.02, 0.04, 0.10, 0.5)
  love.graphics.rectangle("fill", x, y + h * 0.6, w, h * 0.4, 4)

  if esHover then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.95)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.75)
  end
  love.graphics.rectangle("line", x, y, w, h, 4)

  if esHover then
    love.graphics.setColor(DORADO_CLARO[1], DORADO_CLARO[2], DORADO_CLARO[3], 0.9)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.7)
  end
  love.graphics.rectangle("fill", x + 10, y + 1.5, w - 20, 1.5)

  local colEsq = esHover and DORADO or colorBase
  local aEsq = esHover and 1.0 or 0.75
  esquina(x + 3, y + 3, 1, 1, colEsq, aEsq, 6)
  esquina(x + w - 3, y + 3, -1, 1, colEsq, aEsq, 6)
  esquina(x + 3, y + h - 3, 1, -1, colEsq, aEsq, 6)
  esquina(x + w - 3, y + h - 3, -1, -1, colEsq, aEsq, 6)

  local f = love.graphics.getFont()
  local tw = f:getWidth(texto)
  local th = f:getHeight()
  local tx = x + (w - tw) / 2
  local ty = y + (h - th) / 2

  love.graphics.setColor(0, 0, 0, 0.75)
  love.graphics.print(texto, tx + 1, ty + 1)

  if esHover then
    love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.7)
  else
    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3], 0.55)
  end
  love.graphics.print(texto, tx - 1, ty)
  love.graphics.print(texto, tx + 1, ty)
  love.graphics.print(texto, tx, ty - 1)
  love.graphics.print(texto, tx, ty + 1)

  if esHover then
    love.graphics.setColor(1, 0.98, 0.85)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.print(texto, tx, ty)
end

-- ============================================================
-- BOTONES DEL SELECTOR
-- ============================================================

function L.construirBotonesSeleccion()
  L.botonesPersonajes = {}
  local anchoPanel = 220
  local inicioX = constantes.ANCHO_VIRTUAL - anchoPanel - 20
  local y = 90

  for i, p in ipairs(Personajes.lista) do
    local b = Boton.nuevo(inicioX + 20, y, anchoPanel - 40, 34, p.nombre, function()
      L.personajePreview = i
    end)
    table.insert(L.botonesPersonajes, b)
    y = y + 38
  end

  L.botonElegir = Boton.nuevo(inicioX + 20, constantes.ALTO_VIRTUAL - 80,
                              anchoPanel - 40, 32, "Elegir", function()
    if L.personajePreview ~= Personajes.actual then
      L.cambioPersonaje.activo = true
      L.cambioPersonaje.fase = "desintegrando"
      L.cambioPersonaje.timer = 0
      L.cambioPersonaje.personajeNuevo = L.personajePreview
      L.cambioPersonaje.particulasViejas = {}
      L.cambioPersonaje.particulasNuevas = {}
      L.cambioPersonaje.movido = false
      L.estado = "explorando"

      if sonidos.portal_entrar then
        sonidos.portal_entrar:stop()
        sonidos.portal_entrar:play()
      end
    else
      L.estado = "explorando"
    end
  end)

  L.botonVolverSel = Boton.nuevo(inicioX + 20, constantes.ALTO_VIRTUAL - 42,
                                  anchoPanel - 40, 32, "Volver", function()
    L.estado = "explorando"
  end)

  -- Region de la lista
  listaX = inicioX + 15
  listaY = 80
  listaW = anchoPanel - 30
  listaH = (constantes.ALTO_VIRTUAL - 80 - 80) - 20

  local contenidoAlto = #L.botonesPersonajes * 38
  scrollMax = math.max(0, contenidoAlto - listaH)
  scrollY = 0
  scrollObjetivo = 0
  arrastrandoScroll = false
  touchScrollId = nil
  tapId = nil
  tapIdx = nil
  tapMovido = false
end

-- ============================================================
-- DIBUJO
-- ============================================================

function L.dibujarSelector()
  local cx = constantes.ANCHO_VIRTUAL / 2
  local f = love.graphics.getFont()

  -- Fondo con gradiente
  local pasos = 30
  local hPaso = constantes.ALTO_VIRTUAL / pasos
  for i = 0, pasos - 1 do
    local t = i / (pasos - 1)
    local tt = t * t
    local r = 0.02 + (AZUL_PROFUNDO[1] - 0.02) * tt
    local g = 0.03 + (AZUL_PROFUNDO[2] - 0.03) * tt
    local b = 0.06 + (AZUL_PROFUNDO[3] - 0.06) * tt
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, i * hPaso, constantes.ANCHO_VIRTUAL, hPaso + 1)
  end

  -- Panel izquierdo
  local panelIzqX = 30
  local panelIzqY = 40
  local panelIzqW = constantes.ANCHO_VIRTUAL - 280
  local panelIzqH = constantes.ALTO_VIRTUAL - 80

  love.graphics.setColor(0.05, 0.08, 0.15, 0.85)
  love.graphics.rectangle("fill", panelIzqX, panelIzqY, panelIzqW, panelIzqH, 8)
  love.graphics.setColor(0.10, 0.15, 0.25, 0.4)
  love.graphics.rectangle("fill", panelIzqX, panelIzqY, panelIzqW, panelIzqH * 0.4, 8)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.75)
  love.graphics.rectangle("line", panelIzqX, panelIzqY, panelIzqW, panelIzqH, 8)

  esquina(panelIzqX + 5, panelIzqY + 5, 1, 1, DORADO, 1.0, 12)
  esquina(panelIzqX + panelIzqW - 5, panelIzqY + 5, -1, 1, DORADO, 1.0, 12)
  esquina(panelIzqX + 5, panelIzqY + panelIzqH - 5, 1, -1, DORADO, 1.0, 12)
  esquina(panelIzqX + panelIzqW - 5, panelIzqY + panelIzqH - 5, -1, -1, DORADO, 1.0, 12)

  local p = Personajes.lista[L.personajePreview]
  local pulso = 0.5 + 0.5 * math.sin(L.tGlobal * 1.5)

  -- Nombre
  local txtNombre = p.nombre
  local twN = f:getWidth(txtNombre) * 1.4
  local txN = panelIzqX + (panelIzqW - twN) / 2
  local tyN = panelIzqY + 16

  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(txtNombre, txN + 2, tyN + 2, 0, 1.4, 1.4)

  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.7 + pulso * 0.2)
  love.graphics.print(txtNombre, txN - 1, tyN, 0, 1.4, 1.4)
  love.graphics.print(txtNombre, txN + 1, tyN, 0, 1.4, 1.4)
  love.graphics.print(txtNombre, txN, tyN - 1, 0, 1.4, 1.4)
  love.graphics.print(txtNombre, txN, tyN + 1, 0, 1.4, 1.4)

  love.graphics.setColor(1, 0.95, 0.75)
  love.graphics.print(txtNombre, txN, tyN, 0, 1.4, 1.4)

  -- Tipo
  love.graphics.setColor(0.75, 0.85, 0.95)
  local txtTipo = p.tipo
  local twTipo = f:getWidth(txtTipo) * 0.9
  love.graphics.print(txtTipo, panelIzqX + (panelIzqW - twTipo) / 2, panelIzqY + 44, 0, 0.9, 0.9)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.5)
  love.graphics.rectangle("fill", panelIzqX + 40, panelIzqY + 66, panelIzqW - 80, 1)

  -- Preview
  local previewCX = panelIzqX + panelIzqW / 2
  local previewCY = panelIzqY + 150

  local pulsoAura = 0.5 + 0.5 * math.sin(L.tGlobal * 2)
  love.graphics.setColor(0.30, 0.55, 0.85, 0.15 + pulsoAura * 0.08)
  love.graphics.circle("fill", previewCX, previewCY, 80 + pulsoAura * 6)

  love.graphics.setColor(0.25, 0.30, 0.45, 0.6)
  love.graphics.ellipse("fill", previewCX, previewCY + 44, 60, 12)
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.6)
  love.graphics.ellipse("line", previewCX, previewCY + 44, 60, 12)

  love.graphics.push()
  love.graphics.translate(previewCX, previewCY)
  love.graphics.scale(4, 4)

  local bob = math.sin(L.tGlobal * 2) * 0.5
  local dy = -bob

  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", 0, 9, 6, 2.5)

  love.graphics.setColor(p.colorCapa)
  love.graphics.polygon("fill", -6, dy - 2, 6, dy - 2, 8, dy + 8, -8, dy + 8)

  love.graphics.setColor(0.20, 0.15, 0.10)
  love.graphics.rectangle("fill", -4, dy + 6, 3, 4)
  love.graphics.rectangle("fill", 1, dy + 6, 3, 4)

  love.graphics.setColor(p.colorTunica)
  love.graphics.polygon("fill", -5, dy - 4, 5, dy - 4, 6, dy + 7, -6, dy + 7)

  love.graphics.setColor(
    math.max(0, p.colorTunica[1] - 0.15),
    math.max(0, p.colorTunica[2] - 0.15),
    math.max(0, p.colorTunica[3] - 0.15),
    0.9)
  love.graphics.rectangle("fill", -0.5, dy - 3, 1, 9)

  love.graphics.setColor(p.colorPiel)
  love.graphics.circle("fill", 0, dy - 8, 5)

  love.graphics.setColor(p.colorPelo)
  love.graphics.arc("fill", 0, dy - 9, 5, math.pi, math.pi * 2)

  love.graphics.setColor(0.10, 0.08, 0.12)
  love.graphics.circle("fill", -2, dy - 8, 1)
  love.graphics.circle("fill", 2, dy - 8, 1)

  love.graphics.pop()

  -- Descripciones
  local descY = panelIzqY + panelIzqH - 90

  love.graphics.setColor(0.88, 0.92, 0.98)
  love.graphics.print(p.desc1, panelIzqX + 30, descY)
  love.graphics.print(p.desc2, panelIzqX + 30, descY + 18)

  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3])
  love.graphics.print("Arma:", panelIzqX + 30, descY + 46)
  love.graphics.setColor(0.92, 0.95, 1.00)
  love.graphics.print(p.arma, panelIzqX + 30 + f:getWidth("Arma: "), descY + 46)

  -- Panel derecho
  local panelDerX = constantes.ANCHO_VIRTUAL - 240

  love.graphics.setColor(0.05, 0.08, 0.15, 0.85)
  love.graphics.rectangle("fill", panelDerX, 30, 220, constantes.ALTO_VIRTUAL - 60, 8)
  love.graphics.setColor(0.10, 0.15, 0.25, 0.4)
  love.graphics.rectangle("fill", panelDerX, 30, 220, 100, 8)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.75)
  love.graphics.rectangle("line", panelDerX, 30, 220, constantes.ALTO_VIRTUAL - 60, 8)

  esquina(panelDerX + 5, 35, 1, 1, DORADO, 1.0, 10)
  esquina(panelDerX + 215, 35, -1, 1, DORADO, 1.0, 10)
  esquina(panelDerX + 5, constantes.ALTO_VIRTUAL - 35, 1, -1, DORADO, 1.0, 10)
  esquina(panelDerX + 215, constantes.ALTO_VIRTUAL - 35, -1, -1, DORADO, 1.0, 10)

  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3])
  local txtTitulo = "ELEGIR PERSONAJE"
  local twTitulo = f:getWidth(txtTitulo) * 0.8
  love.graphics.print(txtTitulo, panelDerX + 110 - twTitulo / 2, 42, 0, 0.8, 0.8)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.5)
  love.graphics.rectangle("fill", panelDerX + 20, 62, 180, 1)
  love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.9)
  love.graphics.circle("fill", panelDerX + 20, 62.5, 2)
  love.graphics.circle("fill", panelDerX + 200, 62.5, 2)

  -- Lista scrollable
  love.graphics.setScissor(listaX, listaY, listaW, listaH)

  for i, b in ipairs(L.botonesPersonajes) do
    local yReal = listaY + (i - 1) * 38 - scrollY
    local esSeleccionado = (i == L.personajePreview)

    if yReal + 34 > listaY and yReal < listaY + listaH then
      if esSeleccionado then
        local pulsoSel = 0.5 + 0.5 * math.sin(L.tGlobal * 6)
        love.graphics.setColor(DORADO[1], DORADO[2], DORADO[3], 0.20 + pulsoSel * 0.15)
        love.graphics.rectangle("fill", listaX, yReal - 2, listaW, 38, 5)
      end

      dibujarBotonArcanoEn(
        listaX + 2, yReal, listaW - 4, 34,
        b.texto,
        esSeleccionado,
        AZUL_BRILLO
      )
    end
  end

  love.graphics.setScissor()

  -- Barra de scroll
  if scrollMax > 0 then
    local barX = panelDerX + 210
    local barY = listaY
    local barH = listaH

    love.graphics.setColor(0.10, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", barX, barY, 4, barH, 2)

    local thumbH = math.max(20, barH * (barH / (barH + scrollMax)))
    local thumbY = barY + (scrollY / scrollMax) * (barH - thumbH)

    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.85)
    love.graphics.rectangle("fill", barX, thumbY, 4, thumbH, 2)
  end

  -- Botones de accion
  dibujarBotonArcanoEn(
    L.botonElegir.x, L.botonElegir.y, L.botonElegir.w, L.botonElegir.h,
    L.botonElegir.texto, L.botonElegir.presionado,
    {0.55, 1.00, 0.65}
  )

  dibujarBotonArcanoEn(
    L.botonVolverSel.x, L.botonVolverSel.y, L.botonVolverSel.w, L.botonVolverSel.h,
    L.botonVolverSel.texto, L.botonVolverSel.presionado,
    {1.00, 0.55, 0.55}
  )
end

-- ============================================================
-- ACTUALIZAR (suavizar scroll)
-- ============================================================

function L.actualizarSelector(dt)
  local factor = math.min(1, dt * 14)
  scrollY = scrollY + (scrollObjetivo - scrollY) * factor

  if scrollObjetivo < 0 then scrollObjetivo = 0 end
  if scrollObjetivo > scrollMax then scrollObjetivo = scrollMax end
  if scrollY < 0 then scrollY = 0 end
  if scrollY > scrollMax then scrollY = scrollMax end
end

-- ============================================================
-- INPUT
-- ============================================================

-- Detecta si un punto esta en la region scrollable
local function enLista(x, y)
  return x >= listaX and x <= listaX + listaW
     and y >= listaY and y <= listaY + listaH
end

-- Devuelve el indice del boton bajo (x, y) con el scroll aplicado
local function indiceBotonEn(x, y)
  if not enLista(x, y) then return nil end
  for i in ipairs(L.botonesPersonajes) do
    local yReal = listaY + (i - 1) * 38 - scrollY
    if y >= yReal and y <= yReal + 34 then
      return i
    end
  end
  return nil
end

-- ------------------------------------------------------------
-- TOUCH PRESSED
-- ------------------------------------------------------------
function L.seleccionTouchpressed(id, x, y)
  -- 1. Botones de accion
  if L.botonElegir:touchpressed(id, x, y) then return end
  if L.botonVolverSel:touchpressed(id, x, y) then return end

  -- 2. Boton de personaje: NO lo activamos todavia.
  --    Solo guardamos el tap. Si no hay drag, aplicamos el cambio.
  local idx = indiceBotonEn(x, y)
  if idx then
    tapId = id
    tapIdx = idx
    tapX = x
    tapY = y
    tapMovido = false
    arrastrandoScroll = false
    return
  end

  -- 3. Iniciar scroll (si esta dentro del area)
  if enLista(x, y) then
    arrastrandoScroll = true
    touchScrollId = id
    arrastreInicialY = y
    scrollInicial = scrollObjetivo
    ultimoDeltaY = 0
  end
end

-- ------------------------------------------------------------
-- TOUCH MOVED
-- ------------------------------------------------------------
function L.seleccionTouchmoved(id, x, y)
  -- Scroll
  if arrastrandoScroll and id == touchScrollId then
    local dy = y - arrastreInicialY
    ultimoDeltaY = dy

    scrollObjetivo = scrollInicial - dy
    if scrollObjetivo < 0 then scrollObjetivo = 0 end
    if scrollObjetivo > scrollMax then scrollObjetivo = scrollMax end
    return
  end

  -- Tap en boton: si se mueve > 10px, marcar como drag (cancela el tap)
  if tapId == id then
    local dx = x - tapX
    local dy = y - tapY
    if dx * dx + dy * dy > 100 then
      tapMovido = true

      -- Convertir a scroll si sigue dentro de la lista
      if enLista(x, y) then
        arrastrandoScroll = true
        touchScrollId = id
        arrastreInicialY = tapY
        scrollInicial = scrollObjetivo
      end
    end
  end
end

-- ------------------------------------------------------------
-- TOUCH RELEASED
-- ------------------------------------------------------------
function L.seleccionTouchreleased(id, x, y)
  -- Scroll
  if arrastrandoScroll and id == touchScrollId then
    arrastrandoScroll = false
    touchScrollId = nil
    tapId = nil
    tapIdx = nil
    return
  end

  -- Tap en boton: si no se movio, aplicamos el cambio
  if tapId == id then
    if not tapMovido and tapIdx then
      L.personajePreview = tapIdx
    end
    tapId = nil
    tapIdx = nil
    tapMovido = false
  end

  L.botonElegir:touchreleased(id, x, y)
  L.botonVolverSel:touchreleased(id, x, y)
end

return L