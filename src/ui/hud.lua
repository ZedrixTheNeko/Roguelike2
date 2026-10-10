local constantes = require("src.constantes")
local Config     = require("src.datos.config")

local HUD = {}

-- ============================================================
-- PALETA
-- ============================================================
local AZUL_MEDIO     = {0.15, 0.35, 0.75}
local AZUL_BRILLO    = {0.55, 0.85, 1.00}
local AZUL_CLARO     = {0.85, 0.95, 1.00}
local DORADO         = {1.00, 0.80, 0.30}
local DORADO_CLARO   = {1.00, 0.95, 0.65}
local ROJO_VIDA      = {0.90, 0.25, 0.35}
local ROJO_VIDA_OSC  = {0.35, 0.08, 0.12}
local CIAN_ESCUDO    = {0.35, 0.85, 1.00}
local CIAN_ESCUDO_OS = {0.10, 0.30, 0.50}
local AMARILLO_STAM  = {1.00, 0.85, 0.30}
local AZUL_MANA      = {0.35, 0.55, 1.00}
local BALA_ACTIVA    = {1.00, 0.85, 0.30}
local BALA_GASTADA   = {0.30, 0.25, 0.15}

-- ============================================================
-- ESTADO INTERNO
-- ============================================================
local tGlobal = 0
local hpFlash = 0
local escudoFlash = 0
local ultimoHp = -1
local ultimoEscudo = -1

local nivelMostrado = nil
local nivelTimer = 0
local NIVEL_DURACION = 3.0
local NIVEL_FADE_IN = 0.3
local NIVEL_FADE_OUT = 0.8

-- ============================================================
-- HELPERS
-- ============================================================

local function esquina(x, y, ox, oy, color, alpha, s)
  s = s or 6
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.setLineWidth(1.8)
  love.graphics.line(x, y, x + s * ox, y)
  love.graphics.line(x, y, x, y + s * oy)
  love.graphics.setLineWidth(1)
end

-- ============================================================
-- CORAZONES
-- ============================================================

local function dibujarCorazon(cx, cy, tamano, hpParcial, flash)
  local w = tamano
  local colorLleno
  local colorSombra
  if hpParcial >= 2 then
    colorLleno = ROJO_VIDA
    colorSombra = ROJO_VIDA_OSC
  elseif hpParcial >= 1 then
    colorLleno = {0.65, 0.20, 0.28}
    colorSombra = ROJO_VIDA_OSC
  else
    colorLleno = {0.20, 0.10, 0.15}
    colorSombra = {0.10, 0.05, 0.08}
  end

  if flash > 0 then
    colorLleno = {
      colorLleno[1] + (1 - colorLleno[1]) * flash,
      colorLleno[2] + (1 - colorLleno[2]) * flash,
      colorLleno[3] + (1 - colorLleno[3]) * flash,
    }
  end

  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.circle("fill", cx, cy + 2, w * 0.55)

  love.graphics.setColor(colorLleno)
  love.graphics.circle("fill", cx - w * 0.22, cy - w * 0.10, w * 0.32)
  love.graphics.circle("fill", cx + w * 0.22, cy - w * 0.10, w * 0.32)
  love.graphics.polygon("fill",
    cx - w * 0.52, cy - w * 0.02,
    cx + w * 0.52, cy - w * 0.02,
    cx, cy + w * 0.52)

  if hpParcial >= 1 then
    love.graphics.setColor(1, 1, 1, 0.35 + flash * 0.4)
    love.graphics.circle("fill", cx - w * 0.24, cy - w * 0.18, w * 0.10)
    love.graphics.circle("fill", cx + w * 0.20, cy - w * 0.18, w * 0.08)
  end

  love.graphics.setColor(colorSombra[1], colorSombra[2], colorSombra[3], 0.9)
  love.graphics.setLineWidth(1)
  love.graphics.circle("line", cx - w * 0.22, cy - w * 0.10, w * 0.32)
  love.graphics.circle("line", cx + w * 0.22, cy - w * 0.10, w * 0.32)
end

-- ============================================================
-- ESCUDOS
-- ============================================================

local function dibujarEscudo(cx, cy, radio, lleno, flash)
  local colorBorde
  local colorRelleno
  if lleno then
    colorBorde = CIAN_ESCUDO
    colorRelleno = {0.20, 0.55, 0.80}
  else
    colorBorde = {0.25, 0.35, 0.45}
    colorRelleno = {0.10, 0.15, 0.22}
  end

  if flash > 0 then
    colorBorde = {
      colorBorde[1] + (1 - colorBorde[1]) * flash,
      colorBorde[2] + (1 - colorBorde[2]) * flash,
      colorBorde[3] + (1 - colorBorde[3]) * flash,
    }
  end

  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.circle("fill", cx, cy + 1.5, radio)

  love.graphics.setColor(colorRelleno[1], colorRelleno[2], colorRelleno[3], 0.9)
  love.graphics.circle("fill", cx, cy, radio - 1)

  if lleno then
    love.graphics.setColor(0.75, 0.95, 1.00, 0.6 + flash * 0.4)
    love.graphics.circle("fill", cx - radio * 0.25, cy - radio * 0.30, radio * 0.35)
  end

  love.graphics.setColor(colorBorde[1], colorBorde[2], colorBorde[3], 1)
  love.graphics.setLineWidth(1.5)
  love.graphics.circle("line", cx, cy, radio)
  love.graphics.setLineWidth(1)

  if lleno then
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", cx, cy, radio * 0.25)
  end
end

-- ============================================================
-- BARRA DE RECURSO (estamina / mana)
-- ============================================================

local function dibujarBarraRecurso(x, y, w, h, fraccion, tipo)
  local colorBase
  local colorBrillo
  if tipo == "mana" then
    colorBase = AZUL_MANA
    colorBrillo = {0.65, 0.80, 1.00}
  else
    colorBase = AMARILLO_STAM
    colorBrillo = {1.00, 0.95, 0.55}
  end

  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", x - 3, y - 3, w + 6, h + 6, 4)
  love.graphics.setColor(0.08, 0.10, 0.18, 0.95)
  love.graphics.rectangle("fill", x, y, w, h, 3)

  local anchoLleno = w * fraccion
  if anchoLleno > 1 then
    love.graphics.setColor(colorBase[1] * 0.6, colorBase[2] * 0.6, colorBase[3] * 0.6)
    love.graphics.rectangle("fill", x, y, anchoLleno, h, 3)

    love.graphics.setColor(colorBase[1], colorBase[2], colorBase[3])
    love.graphics.rectangle("fill", x + 1, y + 1, anchoLleno - 2, h - 2, 2)

    love.graphics.setColor(colorBrillo[1], colorBrillo[2], colorBrillo[3], 0.7)
    love.graphics.rectangle("fill", x + 2, y + 1.5, anchoLleno - 4, 1.5)
  end

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.75)
  love.graphics.rectangle("line", x, y, w, h, 3)

  esquina(x + 1, y + 1, 1, 1, DORADO, 0.85, 4)
  esquina(x + w - 1, y + 1, -1, 1, DORADO, 0.85, 4)
  esquina(x + 1, y + h - 1, 1, -1, DORADO, 0.85, 4)
  esquina(x + w - 1, y + h - 1, -1, -1, DORADO, 0.85, 4)

  if fraccion >= 0.99 then
    local pulso = 0.5 + 0.5 * math.sin(tGlobal * 4)
    love.graphics.setColor(colorBrillo[1], colorBrillo[2], colorBrillo[3], 0.4 + pulso * 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2, 4)
    love.graphics.setLineWidth(1)
  end
end

-- ============================================================
-- BALAS (Coyote)
-- ============================================================
-- Muestra el recurso tipo "balas" como fila de puntitos (uno por bala).

local function dibujarBalas(x, y, cantidadMax, cantidadActual, recargando, timerRecarga)
  local radio = 6
  local espacio = 16

  -- Panel de fondo
  local anchoTotal = cantidadMax * espacio
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", x - 4, y - 4, anchoTotal + 4, radio * 2 + 8, 4)

  -- Borde
  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.5)
  love.graphics.rectangle("line", x - 4, y - 4, anchoTotal + 4, radio * 2 + 8, 4)

  -- Esquinas
  esquina(x - 3, y - 3, 1, 1, DORADO, 0.75, 4)
  esquina(x + anchoTotal, y - 3, -1, 1, DORADO, 0.75, 4)
  esquina(x - 3, y + radio * 2 + 3, 1, -1, DORADO, 0.75, 4)
  esquina(x + anchoTotal, y + radio * 2 + 3, -1, -1, DORADO, 0.75, 4)

  -- Puntitos
  for i = 1, cantidadMax do
    local cx = x + (i - 1) * espacio + radio / 2
    local cy = y + radio
    local lleno = i <= cantidadActual

    if lleno then
      -- Bala cargada: circulo dorado con brillo
      local pulso = 0.5 + 0.5 * math.sin(tGlobal * 6 + i * 0.5)
      love.graphics.setColor(BALA_ACTIVA[1], BALA_ACTIVA[2], BALA_ACTIVA[3], 0.25 + pulso * 0.15)
      love.graphics.circle("fill", cx, cy, radio + 2)

      love.graphics.setColor(0.85, 0.65, 0.20)
      love.graphics.circle("fill", cx, cy, radio)

      love.graphics.setColor(1, 0.90, 0.40)
      love.graphics.circle("fill", cx, cy, radio - 1.5)

      love.graphics.setColor(1, 1, 0.85, 0.9)
      love.graphics.circle("fill", cx - 1.5, cy - 1.5, 1.5)
    else
      -- Bala gastada: circulo vacio oscuro
      love.graphics.setColor(0.10, 0.08, 0.12, 0.9)
      love.graphics.circle("fill", cx, cy, radio)

      love.graphics.setColor(BALA_GASTADA[1], BALA_GASTADA[2], BALA_GASTADA[3], 0.85)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", cx, cy, radio)
      love.graphics.setLineWidth(1)
    end
  end

  -- Texto de recarga encima si esta recargando
  if recargando then
    local f = love.graphics.getFont()
    local txt = string.format("RECARGANDO %.1fs", timerRecarga)
    local tw = f:getWidth(txt) * 0.85
    local tx = x + anchoTotal / 2 - tw / 2
    local ty = y + radio * 2 + 8

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.print(txt, tx + 1, ty + 1, 0, 0.85, 0.85)
    love.graphics.setColor(1, 0.65, 0.30)
    love.graphics.print(txt, tx, ty, 0, 0.85, 0.85)
  end
end

-- ============================================================
-- PANEL CON ESQUINAS
-- ============================================================

local function dibujarPanelArcano(x, y, w, h)
  love.graphics.setColor(0.05, 0.08, 0.15, 0.85)
  love.graphics.rectangle("fill", x, y, w, h, 5)
  love.graphics.setColor(0.10, 0.15, 0.25, 0.4)
  love.graphics.rectangle("fill", x, y, w, h * 0.5, 5)

  love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.7)
  love.graphics.rectangle("line", x, y, w, h, 5)

  esquina(x + 2, y + 2, 1, 1, DORADO, 0.9, 5)
  esquina(x + w - 2, y + 2, -1, 1, DORADO, 0.9, 5)
  esquina(x + 2, y + h - 2, 1, -1, DORADO, 0.9, 5)
  esquina(x + w - 2, y + h - 2, -1, -1, DORADO, 0.9, 5)
end

-- ============================================================
-- ICONOS
-- ============================================================

local function dibujarMoneda(cx, cy, radio)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.circle("fill", cx, cy + 1, radio)

  love.graphics.setColor(0.85, 0.65, 0.15)
  love.graphics.circle("fill", cx, cy, radio)
  love.graphics.setColor(1, 0.90, 0.35)
  love.graphics.circle("fill", cx, cy, radio - 1)
  love.graphics.setColor(1, 0.98, 0.75, 0.9)
  love.graphics.circle("fill", cx - radio * 0.30, cy - radio * 0.30, radio * 0.30)

  love.graphics.setColor(0.55, 0.40, 0.08)
  love.graphics.setLineWidth(1)
  love.graphics.circle("line", cx, cy, radio)
end

local function dibujarGema(cx, cy, radio)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.circle("fill", cx, cy + 1, radio * 0.8)

  love.graphics.setColor(0.20, 0.70, 0.85)
  love.graphics.polygon("fill",
    cx, cy - radio,
    cx + radio * 0.85, cy,
    cx, cy + radio,
    cx - radio * 0.85, cy)

  love.graphics.setColor(0.40, 0.90, 1.00)
  love.graphics.polygon("fill",
    cx, cy - radio * 0.7,
    cx + radio * 0.55, cy,
    cx, cy + radio * 0.7,
    cx - radio * 0.55, cy)

  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.polygon("fill",
    cx, cy - radio * 0.4,
    cx + radio * 0.25, cy - radio * 0.05,
    cx, cy + radio * 0.15,
    cx - radio * 0.25, cy - radio * 0.05)

  love.graphics.setColor(0.10, 0.40, 0.55)
  love.graphics.setLineWidth(1)
  love.graphics.polygon("line",
    cx, cy - radio,
    cx + radio * 0.85, cy,
    cx, cy + radio,
    cx - radio * 0.85, cy)
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================

function HUD.actualizar(dt, jugador)
  tGlobal = tGlobal + dt

  if jugador then
    if ultimoHp == -1 then
      ultimoHp = jugador.hp
    elseif jugador.hp < ultimoHp then
      hpFlash = 1.0
      ultimoHp = jugador.hp
    elseif jugador.hp > ultimoHp then
      ultimoHp = jugador.hp
    end

    if ultimoEscudo == -1 then
      ultimoEscudo = jugador.escudo
    elseif jugador.escudo < ultimoEscudo then
      escudoFlash = 1.0
      ultimoEscudo = jugador.escudo
    elseif jugador.escudo > ultimoEscudo then
      ultimoEscudo = jugador.escudo
    end
  end

  if hpFlash > 0 then
    hpFlash = math.max(0, hpFlash - dt * 3)
  end
  if escudoFlash > 0 then
    escudoFlash = math.max(0, escudoFlash - dt * 3)
  end

  if nivelTimer > 0 then
    nivelTimer = math.max(0, nivelTimer - dt)
  end
end

function HUD.mostrarNivel(nivel)
  nivelMostrado = nivel
  nivelTimer = NIVEL_DURACION
end

-- ============================================================
-- DIBUJAR PRINCIPAL
-- ============================================================

function HUD.dibujar(jugador, nivel)
  local escala = Config.get("escalaHUD") or 1.0

  if nivel and nivel ~= nivelMostrado then
    nivelMostrado = nivel
    nivelTimer = NIVEL_DURACION
  end

  love.graphics.push()
  love.graphics.translate(10, 10)
  love.graphics.scale(escala, escala)

  -- Corazones
  local hpMax = jugador.hpMax or 6
  local hp = jugador.hp or 0
  local corazonTam = 12
  local corazonEspacio = corazonTam + 3
  local numCorazones = math.floor(hpMax / 2)

  for i = 1, numCorazones do
    local cx = corazonTam / 2 + (i - 1) * corazonEspacio
    local cy = corazonTam / 2
    local hpCorazon = hp - (i - 1) * 2
    if hpCorazon > 2 then hpCorazon = 2 end
    if hpCorazon < 0 then hpCorazon = 0 end

    dibujarCorazon(cx, cy, corazonTam, hpCorazon, hpFlash)
  end

  -- Escudos
  local escMax = jugador.escudoMax or 0
  local esc = jugador.escudo or 0
  local escRadio = 5
  local escEspacio = 13
  local escY = corazonTam + 6

  for i = 1, escMax do
    local cx = escRadio + (i - 1) * escEspacio
    local cy = escY
    dibujarEscudo(cx, cy, escRadio, i <= esc, escudoFlash)
  end

  -- ============================================================
  -- RECURSO: barra o balas segun tipo
  -- ============================================================
  local by = escY + escRadio + 8

  if jugador.recursoTipo == "balas" then
    -- Coyote: mostrar las 6 balas como puntitos
    local cantidadMax = jugador.recursoMax or 6
    local cantidadActual = jugador.recurso or 0
    local recargando = jugador.recargando or false
    local timerRecarga = jugador.timerRecarga or 0

    dibujarBalas(0, by, cantidadMax, cantidadActual, recargando, timerRecarga)
    by = by + escRadio * 2 + 20  -- ajustar para los siguientes paneles

  else
    -- Robin/Conan/Brunilda/Merlin: barra normal
    local bw, bh = 100, 10
    local recurso = jugador.recurso or 0
    local recursoMax = jugador.recursoMax or 100
    local frac = 0
    if recursoMax > 0 then
      frac = math.min(1, recurso / recursoMax)
    end

    dibujarBarraRecurso(0, by, bw, bh, frac, jugador.recursoTipo)

    local f = love.graphics.getFont()
    local label = (jugador.recursoTipo == "mana") and "MP" or "SP"
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.print(label, bw + 6, by - 1)
    love.graphics.setColor(AZUL_CLARO[1], AZUL_CLARO[2], AZUL_CLARO[3], 0.9)
    love.graphics.print(label, bw + 6, by - 1.5)

    by = by + bh + 10
  end

  -- Monedas
  local my = by
  local monW, monH = 80, 24
  dibujarPanelArcano(0, my, monW, monH)
  dibujarMoneda(14, my + monH / 2, 7)
  love.graphics.setColor(1, 0.95, 0.75)
  love.graphics.print(tostring(jugador.monedas or 0), 26, my + 5)

  -- Gemas
  local gy = my + monH + 6
  local gemW, gemH = 80, 24
  dibujarPanelArcano(0, gy, gemW, gemH)
  dibujarGema(14, gy + gemH / 2, 8)
  love.graphics.setColor(0.85, 0.95, 1.00)
  love.graphics.print(tostring(jugador.gemas or 0), 26, gy + 5)

  -- Buffs
  local buffY = gy + gemH + 8

  local buffVel = jugador.buffVelocidad or 0
  if buffVel > 0 then
    local pulso = 0.5 + 0.5 * math.sin(tGlobal * 6)
    local pw, ph = 60, 16

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, buffY, pw, ph, 4)
    love.graphics.setColor(0.35, 0.90, 0.50, 0.5 + pulso * 0.3)
    love.graphics.rectangle("fill", 0, buffY, pw, ph, 4)
    love.graphics.setColor(0.55, 1.00, 0.70)
    love.graphics.rectangle("line", 0, buffY, pw, ph, 4)

    esquina(1, buffY + 1, 1, 1, DORADO, 0.9, 4)
    esquina(pw - 1, buffY + 1, -1, 1, DORADO, 0.9, 4)

    love.graphics.setColor(0.05, 0.10, 0.05)
    love.graphics.print("SPD+", 8, buffY + 1)

    buffY = buffY + ph + 4
  end

  local slow = jugador.slowTimer or 0
  if slow > 0 then
    local pw, ph = 60, 16
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, buffY, pw, ph, 4)
    love.graphics.setColor(0.55, 0.85, 0.30, 0.5)
    love.graphics.rectangle("fill", 0, buffY, pw, ph, 4)
    love.graphics.setColor(0.75, 1.00, 0.45)
    love.graphics.rectangle("line", 0, buffY, pw, ph, 4)

    esquina(1, buffY + 1, 1, 1, DORADO, 0.9, 4)
    esquina(pw - 1, buffY + 1, -1, 1, DORADO, 0.9, 4)

    love.graphics.setColor(0.10, 0.05, 0.02)
    love.graphics.print("SLOW", 8, buffY + 1)

    buffY = buffY + ph + 4
  end

  love.graphics.pop()

  -- ============================================================
  -- INDICADOR DE NIVEL TEMPORAL
  -- ============================================================
  if nivel and nivelTimer > 0 then
    local alpha = 1
    local transcurrido = NIVEL_DURACION - nivelTimer
    if transcurrido < NIVEL_FADE_IN then
      alpha = transcurrido / NIVEL_FADE_IN
    elseif nivelTimer < NIVEL_FADE_OUT then
      alpha = nivelTimer / NIVEL_FADE_OUT
    end
    alpha = math.max(0, math.min(1, alpha))

    local cx = constantes.ANCHO_VIRTUAL / 2
    local txt = "Nivel " .. tostring(nivel)
    local f2 = love.graphics.getFont()
    local tw = f2:getWidth(txt)
    local th = f2:getHeight()
    local pw = tw + 40
    local ph = th + 14
    local px = cx - pw / 2
    local py = 55

    love.graphics.setColor(0.05, 0.08, 0.15, 0.85 * alpha)
    love.graphics.rectangle("fill", px, py, pw, ph, 6)
    love.graphics.setColor(0.10, 0.18, 0.30, 0.4 * alpha)
    love.graphics.rectangle("fill", px, py, pw, ph * 0.5, 6)

    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.7 * alpha)
    love.graphics.rectangle("line", px, py, pw, ph, 6)

    esquina(px + 2, py + 2, 1, 1, DORADO, 0.9 * alpha, 6)
    esquina(px + pw - 2, py + 2, -1, 1, DORADO, 0.9 * alpha, 6)
    esquina(px + 2, py + ph - 2, 1, -1, DORADO, 0.9 * alpha, 6)
    esquina(px + pw - 2, py + ph - 2, -1, -1, DORADO, 0.9 * alpha, 6)

    local tx = cx - tw / 2
    local ty = py + (ph - th) / 2

    love.graphics.setColor(0, 0, 0, 0.75 * alpha)
    love.graphics.print(txt, tx + 1, ty + 1)

    love.graphics.setColor(AZUL_BRILLO[1], AZUL_BRILLO[2], AZUL_BRILLO[3], 0.7 * alpha)
    love.graphics.print(txt, tx - 1, ty)
    love.graphics.print(txt, tx + 1, ty)
    love.graphics.print(txt, tx, ty - 1)
    love.graphics.print(txt, tx, ty + 1)

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(txt, tx, ty)
  end
end

return HUD