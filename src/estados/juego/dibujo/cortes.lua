local J = require("src.estados.juego.estado")

function J.dibujarCorte(c)
  local alpha = c.vida / c.duracion
  love.graphics.push()
  love.graphics.translate(c.x, c.y)
  love.graphics.rotate(c.angulo or 0)

  -- ============================================================
  -- CORTES BASICOS
  -- ============================================================
  if c.tipo == "corte_izq" then
    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.arc("line", "open", 0, 0, 26, -math.pi * 0.70, math.pi * 0.10)
    love.graphics.setColor(0.85, 0.92, 1.0, 0.6 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", 0, 0, 22, -math.pi * 0.65, math.pi * 0.05)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "corte_der" then
    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.arc("line", "open", 0, 0, 26, -math.pi * 0.10, math.pi * 0.70)
    love.graphics.setColor(0.85, 0.92, 1.0, 0.6 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", 0, 0, 22, -math.pi * 0.05, math.pi * 0.65)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "estocada" then
    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.line(6, 0, 46, 0)
    love.graphics.setColor(0.85, 0.92, 1.0, 0.7 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.line(8, 0, 42, 0)
    love.graphics.setColor(1, 1, 1, 0.98 * alpha)
    love.graphics.polygon("fill", 42, -5, 54, 0, 42, 5)
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- ESTOCADA DE LANZA (Brunilda)
  -- ============================================================
  elseif c.tipo == "estocada_lanza" then
    local rangoMax = c.rango or 55
    local crecer = math.min(1, (1 - alpha) * 6)
    local rango = rangoMax * crecer

    love.graphics.setColor(1, 0.85, 0.35, 0.30 * alpha)
    love.graphics.rectangle("fill", 8, -8, rango, 16, 4)

    love.graphics.setColor(0.90, 0.90, 0.95, 0.95 * alpha)
    love.graphics.rectangle("fill", 10, -3, rango - 8, 6, 2)

    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.rectangle("fill", 12, -1.5, rango - 12, 3, 2)

    love.graphics.setColor(1, 0.90, 0.40, 0.85 * alpha)
    love.graphics.rectangle("fill", 12, -3, rango - 12, 1.2)

    love.graphics.setColor(0.55, 0.55, 0.65, 0.9 * alpha)
    love.graphics.rectangle("fill", 6, -4, 6, 8, 1)
    love.graphics.setColor(0.90, 0.70, 0.25, 0.85 * alpha)
    love.graphics.rectangle("fill", 6, -4, 6, 1.5)

    local puntaX = 10 + rango - 8
    love.graphics.setColor(0.95, 0.95, 1.0, 0.95 * alpha)
    love.graphics.polygon("fill",
      puntaX, -6,
      puntaX + 12, 0,
      puntaX, 6)

    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.polygon("fill",
      puntaX + 2, -3,
      puntaX + 9, 0,
      puntaX + 2, 3)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.90, 0.45, 0.4 * alpha)
    love.graphics.circle("fill", puntaX + 8, 0, 8)
    love.graphics.setColor(1, 1, 0.85, 0.6 * alpha)
    love.graphics.circle("fill", puntaX + 8, 0, 4)
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- GOLPE FUERTE (Conan hab 1)
  -- ============================================================
  elseif c.tipo == "golpe_fuerte" then
    love.graphics.setColor(1, 0.95, 0.75, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.arc("line", "open", 0, 0, 48, -math.pi * 0.55, math.pi * 0.55)
    love.graphics.setColor(1, 0.85, 0.55, 0.6 * alpha)
    love.graphics.setLineWidth(3.5)
    love.graphics.arc("line", "open", 0, 0, 42, -math.pi * 0.5, math.pi * 0.5)
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- ESTOCADA DORADA (Conan hab 2)
  -- ============================================================
  elseif c.tipo == "estocada_dorada" then
    love.graphics.setColor(1, 0.85, 0.30, 0.9 * alpha)
    love.graphics.setLineWidth(8)
    love.graphics.line(6, 0, 70, 0)
    love.graphics.setColor(1, 0.95, 0.55, 0.85 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.line(8, 0, 64, 0)
    love.graphics.setColor(1, 1, 0.85, 0.95 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.line(8, 0, 60, 0)
    love.graphics.setColor(1, 0.90, 0.40, 0.95 * alpha)
    love.graphics.polygon("fill", 64, -8, 84, 0, 64, 8)
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- CORTES ROJOS (Conan hab 3 - Danza Cortante)
  -- ============================================================
  elseif c.tipo == "corte_rojo_1" then
    love.graphics.setColor(1, 0.30, 0.25, 0.9 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.arc("line", "open", 0, 0, 28, -math.pi * 0.65, math.pi * 0.10)
    love.graphics.setColor(1, 0.55, 0.40, 0.7 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.arc("line", "open", 0, 0, 24, -math.pi * 0.6, math.pi * 0.05)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "corte_rojo_2" then
    love.graphics.setColor(1, 0.25, 0.20, 0.95 * alpha)
    love.graphics.setLineWidth(8)
    love.graphics.arc("line", "open", 0, 0, 42, -math.pi * 0.6, math.pi * 0.6)
    love.graphics.setColor(1, 0.45, 0.30, 0.7 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.arc("line", "open", 0, 0, 36, -math.pi * 0.55, math.pi * 0.55)
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- CORTE SAMURAI (Shen/Sable combo paso 3)
  -- ============================================================
  elseif c.tipo == "corte_samurai" then
    love.graphics.setColor(0.55, 0.80, 1.0, 0.35 * alpha)
    love.graphics.setLineWidth(8)
    love.graphics.arc("line", "open", 0, 0, 46, -math.pi * 0.55, math.pi * 0.55)

    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.arc("line", "open", 0, 0, 42, -math.pi * 0.5, math.pi * 0.5)

    love.graphics.setColor(0.75, 0.92, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", 0, 0, 38, -math.pi * 0.45, math.pi * 0.45)

    love.graphics.setColor(0.90, 0.95, 1.0, 0.9 * alpha)
    for i = -3, 3 do
      local ang = i * 0.20
      local x1 = math.cos(ang) * 30
      local y1 = math.sin(ang) * 30
      local x2 = math.cos(ang) * 44
      local y2 = math.sin(ang) * 44
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- IAI CORTE (Shen hab 1)
  -- ============================================================
  elseif c.tipo == "iai_corte" then
    local rBase = c.radio or 50
    local progreso = 1 - alpha
    local r = rBase * progreso

    love.graphics.setColor(0.55, 0.80, 1.0, 0.30 * alpha)
    love.graphics.circle("fill", 0, 0, r + 15)

    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, r)

    love.graphics.setColor(0.75, 0.92, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r * 0.85)

    love.graphics.setColor(1, 1, 1, 0.7 * alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", 0, 0, r * 0.65)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.90, 0.95, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(2)
    for i = 1, 16 do
      local ang = i * math.pi / 8
      local x1 = math.cos(ang) * r * 0.7
      local y1 = math.sin(ang) * r * 0.7
      local x2 = math.cos(ang) * r
      local y2 = math.sin(ang) * r
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.85, 0.95, 1.0, 0.6 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.4)
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- ESTELA DE VIENTO (Shen hab 2 - Pasos de Viento)
  -- ============================================================
  elseif c.tipo == "estela_viento" then
    local rango = c.rango or 55

    love.graphics.setColor(0.55, 0.80, 1.0, 0.35 * alpha)
    love.graphics.rectangle("fill", -rango / 2, -10, rango, 20, 6)

    love.graphics.setColor(0.75, 0.92, 1.0, 0.55 * alpha)
    love.graphics.rectangle("fill", -rango / 2, -6, rango, 12, 4)

    love.graphics.setColor(0.90, 0.95, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(2)
    for i = -1, 1 do
      local yy = i * 3
      love.graphics.line(-rango / 2 + 4, yy, rango / 2 - 4, yy)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    for i = 1, 4 do
      local x = -rango / 2 + (i / 5) * rango
      love.graphics.circle("fill", x, 0, 2)
    end

  -- ============================================================
  -- CORTE DEL VACIO (Shen hab 3)
  -- ============================================================
  elseif c.tipo == "corte_vacio" then
    local rango = c.rango or 80
    local progreso = 1 - alpha

    love.graphics.setColor(0.05, 0.02, 0.10, 0.35 * alpha)
    love.graphics.polygon("fill", 0, -40, rango, -25, rango, 25, 0, 40)

    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.polygon("fill", 0, -8, rango, -4, rango, 4, 0, 8)

    love.graphics.setColor(0.55, 0.80, 1.0, 0.55 * alpha)
    love.graphics.polygon("fill", 0, -16, rango, -10, rango, 10, 0, 16)

    love.graphics.setColor(0.65, 0.40, 0.95, 0.5 * alpha)
    love.graphics.polygon("fill", 0, -22, rango, -14, rango, 14, 0, 22)

    love.graphics.setColor(0.90, 0.85, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(2)
    for i = -3, 3 do
      local yy = i * 4
      love.graphics.line(0, yy, rango, yy * 0.6)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.85, 0.95, 1.0, 0.5 * alpha)
    love.graphics.circle("fill", rango * 0.7, 0, 30 + progreso * 10)
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- EXPLOSION VACIO (onda expansiva)
  -- ============================================================
  elseif c.tipo == "explosion_vacio" then
    local progreso = 1 - alpha
    local rBase = c.radio or 60
    local r = progreso * rBase

    love.graphics.setColor(0.10, 0.05, 0.20, 0.4 * alpha)
    love.graphics.circle("fill", 0, 0, r + 20)

    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, r)

    love.graphics.setColor(0.55, 0.80, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", 0, 0, r * 0.8)

    love.graphics.setColor(0.65, 0.40, 0.95, 0.8 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, r * 0.55)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.90, 0.95, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(2)
    for i = 1, 10 do
      local ang = i * math.pi / 5 + love.timer.getTime() * 2
      local x1 = math.cos(ang) * r * 0.4
      local y1 = math.sin(ang) * r * 0.4
      local x2 = math.cos(ang) * r
      local y2 = math.sin(ang) * r
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- EXPLOSIONES
  -- ============================================================
  elseif c.tipo == "explosion_arcana" then
    local progreso = 1 - alpha
    love.graphics.setColor(0.65, 0.35, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, 80 * progreso)
    love.graphics.setColor(0.85, 0.60, 1.0, 0.7 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, 55 * progreso)
    love.graphics.setColor(0.95, 0.85, 1.0, 0.5 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, 30 * progreso)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "explosion_fuego" then
    local progreso = 1 - alpha
    local rBase = c.radio or 42
    local r = progreso * rBase
    love.graphics.setColor(1, 0.35, 0.10, 0.9 * alpha)
    love.graphics.circle("fill", 0, 0, r)
    love.graphics.setColor(1, 0.65, 0.20, 0.7 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.7)
    love.graphics.setColor(1, 0.90, 0.50, 0.6 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.4)
    love.graphics.setColor(1, 0.95, 0.75, 0.5 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r + 8)
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- RAYO ARCANO (Merlin hab 2)
  -- ============================================================
  elseif c.tipo == "rayo_arcano" then
    local rango = c.rango or 400
    local ancho = c.ancho or 32

    love.graphics.setColor(0.30, 0.55, 1.0, 0.35 * alpha)
    love.graphics.rectangle("fill", 0, -ancho/2 - 8, rango, ancho + 16)

    love.graphics.setColor(0.45, 0.75, 1.0, 0.75 * alpha)
    love.graphics.rectangle("fill", 0, -ancho/2, rango, ancho)

    love.graphics.setColor(0.75, 0.92, 1.0, 0.9 * alpha)
    love.graphics.rectangle("fill", 0, -ancho/4, rango, ancho/2)

    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.rectangle("fill", 0, -ancho/8, rango, ancho/4)

    love.graphics.setColor(0.85, 0.95, 1.0, 0.6 * alpha)
    love.graphics.setLineWidth(2)
    for i = 1, 5 do
      local yy = -ancho/2 + (i - 1) * (ancho / 4)
      local desvio = math.sin(love.timer.getTime() * 30 + i) * 4
      love.graphics.line(0, yy, rango, yy + desvio)
    end
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- MARCA CAZADOR (Kael hab 3)
  -- ============================================================
  elseif c.tipo == "marca_cazador" then
    local progreso = 1 - alpha
    local radio = (c.radio or 200) * progreso

    love.graphics.setColor(1, 0.85, 0.35, 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", 0, 0, radio)

    love.graphics.setColor(1, 0.95, 0.65, 0.7 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, radio * 0.9)

    love.graphics.setColor(1, 0.80, 0.30, 0.15 * alpha)
    love.graphics.circle("fill", 0, 0, radio)

    love.graphics.setColor(1, 0.90, 0.50, 0.7 * alpha)
    love.graphics.setLineWidth(2)
    for i = 1, 8 do
      local ang = i * math.pi / 4 + love.timer.getTime() * 0.5
      local x1 = math.cos(ang) * radio * 0.7
      local y1 = math.sin(ang) * radio * 0.7
      local x2 = math.cos(ang) * radio
      local y2 = math.sin(ang) * radio
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- CARGA DEL CUERVO (Brunilda hab 1)
  -- ============================================================
  elseif c.tipo == "carga_cuervo" then
    local rango = c.rango or 90
    local progreso = alpha

    love.graphics.setColor(1, 0.85, 0.35, 0.4 * progreso)
    love.graphics.polygon("fill", 0, -14, rango, -8, rango, 8, 0, 14)

    love.graphics.setColor(1, 0.95, 0.55, 0.7 * progreso)
    love.graphics.setLineWidth(3)
    for i = -2, 2 do
      local yy = i * 5
      love.graphics.line(6, yy, rango * 0.9, yy * 0.6)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0.90, 0.50, 0.9 * progreso)
    for i = 1, 4 do
      local d = rango * (i / 5)
      love.graphics.circle("fill", d, 0, 2)
    end

  -- ============================================================
  -- EXPLOSION SAGRADA (Brunilda hab 2)
  -- ============================================================
  elseif c.tipo == "explosion_sagrada" then
    local progreso = 1 - alpha
    local rBase = c.radio or 60
    local r = progreso * rBase

    love.graphics.setColor(1, 0.85, 0.35, 0.30 * alpha)
    love.graphics.circle("fill", 0, 0, r + 20)

    love.graphics.setColor(1, 0.90, 0.50, 0.9 * alpha)
    love.graphics.circle("fill", 0, 0, r)
    love.graphics.setColor(1, 1, 0.85, 0.95 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.5)

    love.graphics.setColor(1, 0.95, 0.65, 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0.90, 0.40, 0.8 * alpha)
    love.graphics.setLineWidth(3)
    for i = 1, 6 do
      local ang = i * math.pi / 3 + love.timer.getTime() * 3
      local x1 = math.cos(ang) * r * 0.6
      local y1 = math.sin(ang) * r * 0.6
      local x2 = math.cos(ang) * (r + 12)
      local y2 = math.sin(ang) * (r + 12)
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

  -- ============================================================
  -- ESTELA DE LANZA (Brunilda hab 2)
  -- ============================================================
  elseif c.tipo == "estela_lanza" then
    local rango = c.rango or 200

    love.graphics.setColor(1, 0.85, 0.35, 0.6 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.line(0, 0, rango, 0)

    love.graphics.setColor(1, 0.95, 0.65, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.line(0, 0, rango, 0)

    love.graphics.setColor(1, 1, 0.85, 0.95 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, 0, rango, 0)

    love.graphics.setLineWidth(1)

  -- ============================================================
  -- EXPLOSION VALQUIRIA (Brunilda hab 3)
  -- ============================================================
  elseif c.tipo == "explosion_valquiria" then
    local progreso = 1 - alpha
    local rBase = c.radio or 100
    local r = progreso * rBase

    love.graphics.setColor(1, 0.85, 0.35, 0.5 * alpha)
    love.graphics.circle("fill", 0, 0, r + 25)

    love.graphics.setColor(1, 0.90, 0.50, 0.85 * alpha)
    love.graphics.circle("fill", 0, 0, r)

    love.graphics.setColor(1, 1, 0.85, 0.95 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.55)

    love.graphics.setColor(1, 0.95, 0.65, 0.95 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r * 0.8)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0.90, 0.40, 0.85 * alpha)
    love.graphics.setLineWidth(4)
    for i = 1, 12 do
      local ang = i * math.pi / 6
      local x1 = math.cos(ang) * r * 0.5
      local y1 = math.sin(ang) * r * 0.5
      local x2 = math.cos(ang) * (r + 20)
      local y2 = math.sin(ang) * (r + 20)
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 0.95, 0.55, 0.9 * alpha)
    for i = 1, 8 do
      local a = i * (math.pi * 2 / 8) + love.timer.getTime()
      local d = r * 0.7
      love.graphics.circle("fill", math.cos(a) * d, math.sin(a) * d, 3)
    end

  -- ============================================================
  -- COYOTE
  -- ============================================================
  elseif c.tipo == "disparo_revolver" then
    local progreso = alpha
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.85, 0.40, 0.7 * progreso)
    love.graphics.circle("fill", 0, 0, 8)
    love.graphics.setColor(1, 0.95, 0.65, 0.9 * progreso)
    love.graphics.circle("fill", 0, 0, 4)
    love.graphics.setColor(1, 1, 0.90, 0.95 * progreso)
    love.graphics.circle("fill", 0, 0, 2)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 0.90, 0.50, 0.6 * progreso)
    love.graphics.setLineWidth(2)
    love.graphics.line(4, 0, 18, 0)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "disparo_doble" then
    local progreso = alpha
    love.graphics.setBlendMode("add")
    for i = -1, 1, 2 do
      love.graphics.setColor(1, 0.85, 0.40, 0.7 * progreso)
      love.graphics.circle("fill", 0, i * 4, 10)
      love.graphics.setColor(1, 0.95, 0.65, 0.9 * progreso)
      love.graphics.circle("fill", 0, i * 4, 5)
      love.graphics.setColor(1, 1, 0.90, 0.95 * progreso)
      love.graphics.circle("fill", 0, i * 4, 2)
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 0.90, 0.50, 0.6 * progreso)
    love.graphics.setLineWidth(2)
    for i = -1, 1, 2 do
      love.graphics.line(4, i * 4, 20, i * 4)
    end
    love.graphics.setLineWidth(1)

  elseif c.tipo == "slowmo_activado" then
    local progreso = 1 - alpha
    local rBase = c.radio or 80
    local r = progreso * rBase
    love.graphics.setColor(0.10, 0.05, 0.20, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r + 30)
    love.graphics.setColor(0.55, 0.30, 0.85, 0.7 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setColor(0.85, 0.60, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r * 0.7)
    love.graphics.setColor(1, 0.90, 1.0, 0.95 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", 0, 0, r * 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.65, 0.45, 0.95, 0.6 * alpha)
    love.graphics.setLineWidth(2)
    for i = 1, 12 do
      local ang = i * math.pi / 6
      local x1 = math.cos(ang) * r * 0.3
      local y1 = math.sin(ang) * r * 0.3
      local x2 = math.cos(ang) * r
      local y2 = math.sin(ang) * r
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.85, 0.60, 1.0, 0.9 * alpha)
    for i = 1, 6 do
      local a = i * (math.pi * 2 / 6) + love.timer.getTime() * 2
      local d = r * 0.85
      love.graphics.circle("fill", math.cos(a) * d, math.sin(a) * d, 3)
    end
    love.graphics.setBlendMode("alpha")

  elseif c.tipo == "dual_wield_activado" then
    local progreso = 1 - alpha
    local rBase = c.radio or 60
    local r = progreso * rBase
    love.graphics.setColor(0.15, 0.10, 0.05, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r + 25)
    love.graphics.setColor(1, 0.80, 0.30, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setColor(1, 0.95, 0.55, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r * 0.75)
    love.graphics.setColor(1, 1, 0.85, 0.95 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", 0, 0, r * 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 0.90, 0.40, 0.7 * alpha)
    love.graphics.setLineWidth(3)
    for i = 1, 12 do
      local ang = i * math.pi / 6 + love.timer.getTime() * 1.5
      local x1 = math.cos(ang) * r * 0.35
      local y1 = math.sin(ang) * r * 0.35
      local x2 = math.cos(ang) * r
      local y2 = math.sin(ang) * r
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.90, 0.45, 0.9 * alpha)
    for i = 1, 6 do
      local a = i * (math.pi * 2 / 6) + love.timer.getTime() * 3
      local d = r * 1.05
      love.graphics.circle("fill", math.cos(a) * d, math.sin(a) * d, 2.5)
    end
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- NYX-7 - DESINTEGRACION + DRON
  -- ============================================================
  elseif c.tipo == "desintegracion_anillo" then
    local progreso = 1 - alpha
    local rBase = c.radio or 20
    local r = progreso * rBase
    love.graphics.setColor(0.30, 0.75, 1.0, 0.40 * alpha)
    love.graphics.circle("fill", 0, 0, r + 8)
    love.graphics.setColor(0.55, 0.90, 1.0, 0.95 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", 0, 0, r * 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.55, 0.90, 1.0, 0.5 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.3)
    love.graphics.setBlendMode("alpha")

  elseif c.tipo == "dron_activado" then
    local progreso = 1 - alpha
    local rBase = c.radio or 40
    local r = progreso * rBase
    love.graphics.setColor(0.30, 0.75, 1.0, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r)
    love.graphics.setColor(0.55, 0.90, 1.0, 0.95 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setColor(1, 1, 1, 0.85 * alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", 0, 0, r * 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.55, 0.90, 1.0, 0.4 * alpha)
    love.graphics.circle("fill", 0, 0, r * 0.4)
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- LYRA - CANCION DE CUNA + NOTA RESONANTE + SINFONIA
  -- ============================================================
  elseif c.tipo == "cancion_cuna" then
    local rango = c.rango or 100
    local apertura = c.apertura or math.rad(45)
    local progreso = 1 - alpha

    love.graphics.setColor(0.75, 0.50, 1.0, 0.25 * alpha)
    love.graphics.arc("fill", 0, 0, rango, -apertura, apertura)

    love.graphics.setColor(0.85, 0.65, 1.0, 0.85 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.arc("line", "open", 0, 0, rango, -apertura, apertura)

    love.graphics.setColor(1, 0.85, 1.0, 0.6 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", 0, 0, rango * 0.7, -apertura * 0.8, apertura * 0.8)
    love.graphics.setLineWidth(1)

    for i = 1, 5 do
      local a = -apertura + (i - 1) * (apertura * 2 / 4)
      local r = rango * (0.5 + progreso * 0.5)
      love.graphics.setColor(0.85, 0.65, 1.0, 0.8 * alpha)
      love.graphics.circle("fill", math.cos(a) * r, math.sin(a) * r, 3)
    end

  elseif c.tipo == "nota_resonante" then
    local progreso = 1 - alpha
    local rBase = c.radio or 70
    local r = progreso * rBase

    love.graphics.setColor(0.65, 0.35, 1.0, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r + 15)

    love.graphics.setColor(0.85, 0.65, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.circle("line", 0, 0, r)

    love.graphics.setColor(1, 0.90, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, r * 0.6)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.75, 0.55, 1.0, 0.85 * alpha)
    for i = 1, 6 do
      local ang = i * math.pi / 3 + love.timer.getTime() * 2
      local x = math.cos(ang) * r * 0.75
      local y = math.sin(ang) * r * 0.75
      love.graphics.circle("fill", x, y, 2.5)
    end

  elseif c.tipo == "sinfonia_activada" then
    local progreso = 1 - alpha
    local rBase = c.radio or 60
    local r = progreso * rBase

    love.graphics.setColor(0.65, 0.30, 1.0, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r + 25)

    love.graphics.setColor(0.85, 0.55, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", 0, 0, r)

    love.graphics.setColor(1, 0.85, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r * 0.75)
    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", 0, 0, r * 0.4)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.85, 0.60, 1.0, 0.7 * alpha)
    love.graphics.setLineWidth(3)
    for i = 1, 12 do
      local ang = i * math.pi / 6 + love.timer.getTime() * 2
      local x1 = math.cos(ang) * r * 0.35
      local y1 = math.sin(ang) * r * 0.35
      local x2 = math.cos(ang) * r
      local y2 = math.sin(ang) * r
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 0.85, 1.0, 0.9 * alpha)
    for i = 1, 6 do
      local a = i * (math.pi * 2 / 6) + love.timer.getTime() * 3
      local d = r * 1.05
      love.graphics.circle("fill", math.cos(a) * d, math.sin(a) * d, 2.5)
    end
    love.graphics.setBlendMode("alpha")

  -- ============================================================
  -- SHADOW (dagas), THORIN (martillo), REX (rifle), SABLE (katana)
  -- ============================================================
  elseif c.tipo == "tajo_dagas" then
    local l = c.lado or 1
    love.graphics.setColor(0.80, 0.55, 1.0, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.arc("line", "open", 0, 0, 22, -0.9 * l - 0.5, 0.9 * l + 0.5)
    love.graphics.setColor(1, 1, 1, 0.9 * alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.arc("line", "open", 0, 0, 20, -0.7 * l - 0.4, 0.7 * l + 0.4)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "tajo_katana" then
    local r = c.rango or 38
    love.graphics.setColor(0.85, 0.95, 1.0, 0.45 * alpha)
    love.graphics.setLineWidth(7)
    love.graphics.arc("line", "open", 0, 0, r * 0.8, -0.95, 0.95)
    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(2.5)
    love.graphics.arc("line", "open", 0, 0, r * 0.8, -0.85, 0.85)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "impacto_martillo" then
    local k = 1 - alpha
    local r = (c.radio or 28) * (0.4 + 0.6 * k)
    love.graphics.rotate(-(c.angulo or 0))
    love.graphics.setColor(1.0, 0.92, 0.55, 0.35 * alpha)
    love.graphics.circle("fill", 0, 0, r)
    love.graphics.setColor(1.0, 0.95, 0.70, 0.9 * alpha)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setLineWidth(1)
    for i = 1, 8 do
      local a = i * math.pi / 4 + 0.3
      love.graphics.line(math.cos(a) * r * 0.5, math.sin(a) * r * 0.5,
        math.cos(a) * r * 1.15, math.sin(a) * r * 1.15)
    end

  elseif c.tipo == "onda_tierra" then
    local k = 1 - alpha
    local r = (c.radio or 80) * k
    love.graphics.rotate(-(c.angulo or 0))
    love.graphics.setColor(0.70, 0.55, 0.30, 0.25 * alpha)
    love.graphics.circle("fill", 0, 0, r)
    love.graphics.setColor(0.90, 0.75, 0.40, 0.9 * alpha)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", 0, 0, r)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.25, 0.18, 0.10, 0.8 * alpha)
    for i = 1, 10 do
      local a = i * math.pi / 5
      love.graphics.line(math.cos(a) * 10, math.sin(a) * 10,
        math.cos(a + 0.15) * r * 0.9, math.sin(a + 0.15) * r * 0.9)
    end

  elseif c.tipo == "rastro" then
    local col = c.color or {0.75, 0.45, 1.0}
    local rg = c.rango or 100
    local w = (c.ancho or 12) * (0.4 + 0.6 * alpha)
    love.graphics.setColor(col[1], col[2], col[3], 0.40 * alpha)
    love.graphics.rectangle("fill", 0, -w, rg, w * 2)
    love.graphics.setColor(1, 1, 1, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, -w * 0.25, rg, w * 0.5)

  elseif c.tipo == "corte_aleatorio" then
    local rg = c.rango or 30
    love.graphics.setColor(1, 1, 1, 0.95 * alpha)
    love.graphics.setLineWidth(2.5)
    love.graphics.line(-rg / 2, 0, rg / 2, 0)
    love.graphics.setColor(0.85, 0.95, 1.0, 0.6 * alpha)
    love.graphics.setLineWidth(5)
    love.graphics.line(-rg / 2, 0, rg / 2, 0)
    love.graphics.setLineWidth(1)

  elseif c.tipo == "pilar_luz" then
    love.graphics.rotate(-(c.angulo or 0))
    local w = (c.radio or 30) * (0.5 + 0.5 * alpha)
    love.graphics.setColor(1.0, 0.95, 0.55, 0.35 * alpha)
    love.graphics.rectangle("fill", -w, -150, w * 2, 150)
    love.graphics.setColor(1.0, 1.0, 0.85, 0.85 * alpha)
    love.graphics.rectangle("fill", -w * 0.45, -150, w * 0.9, 150)
    love.graphics.setColor(1.0, 0.95, 0.60, 0.7 * alpha)
    love.graphics.ellipse("fill", 0, 0, w * 1.4, w * 0.5)

  end

  love.graphics.pop()
end

return J