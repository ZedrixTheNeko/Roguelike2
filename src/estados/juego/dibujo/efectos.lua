local J = require("src.estados.juego.estado")

function J.dibujarEfectosMundo()
  -- ============================================================
  -- ZONA DE LLUVIA DE FLECHAS (Robin hab 2)
  -- ============================================================
  if J.accionEspecial.tipo == "zona_flechas" then
    local a = J.accionEspecial
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 8)
    love.graphics.setColor(0.30, 0.65, 1.0, 0.15 + pulso * 0.10)
    love.graphics.circle("fill", a.zonaX, a.zonaY, a.radio)
    love.graphics.setColor(0.45, 0.80, 1.0, 0.60 + pulso * 0.30)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", a.zonaX, a.zonaY, a.radio)
    love.graphics.setColor(0.70, 0.90, 1.0, 0.40 + pulso * 0.20)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", a.zonaX, a.zonaY, a.radio * 0.65)
    love.graphics.setColor(0.80, 0.95, 1.0, 0.7)
    for i = 1, 6 do
      local ang = love.timer.getTime() * 0.5 + (i - 1) * (math.pi * 2 / 6)
      local rx2 = a.zonaX + math.cos(ang) * a.radio * 0.85
      local ry2 = a.zonaY + math.sin(ang) * a.radio * 0.85
      love.graphics.rectangle("fill", rx2 - 2, ry2 - 2, 4, 4)
    end
  end

  -- ============================================================
  -- ESPERANDO MARCADORA (Robin hab 2)
  -- ============================================================
  if J.accionEspecial.tipo == "esperando_marcadora" then
    local m = J.accionEspecial.marcadoraRef
    if m then
      love.graphics.setColor(0.35, 0.70, 1.0, 0.4)
      love.graphics.circle("line", m.x, m.y, 15)
      love.graphics.setColor(0.55, 0.85, 1.0, 0.7)
      love.graphics.circle("fill", m.x, m.y, 2)
    end
  end

  -- ============================================================
  -- IRA CARMESI - CARGANDO (Merlin hab 3)
  -- ============================================================
  if J.accionEspecial.tipo == "carga_ira_carmesi" then
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 6)
    local crecido = math.min(1, J.accionEspecial.timer / J.accionEspecial.duracion)

    love.graphics.setColor(0.85, 0.15, 0.10, 0.30 + pulso * 0.20)
    love.graphics.circle("fill", J.robin.x, J.robin.y, 60 * crecido)
    love.graphics.setColor(1, 0.30, 0.20, 0.7 + pulso * 0.3)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", J.robin.x, J.robin.y, 55 * crecido)

    love.graphics.setColor(0.05, 0.02, 0.02, 0.6)
    love.graphics.circle("fill", J.robin.x, J.robin.y, 35 * crecido)
    love.graphics.setColor(0.85, 0.10, 0.05, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", J.robin.x, J.robin.y, 30 * crecido)

    love.graphics.setColor(1, 0.40, 0.20, 0.9)
    for i = 1, 8 do
      local ang = love.timer.getTime() * 3 + (i - 1) * (math.pi * 2 / 8)
      local rx2 = J.robin.x + math.cos(ang) * 45 * crecido
      local ry2 = J.robin.y + math.sin(ang) * 45 * crecido
      love.graphics.rectangle("fill", rx2 - 2, ry2 - 2, 4, 4)
    end
    love.graphics.setLineWidth(1)
  end

  -- ============================================================
  -- PARTICULAS CARGA ESTOCADA (Conan hab 2)
  -- ============================================================
  if J.accionEspecial.tipo == "carga_estocada" then
    for _, p in ipairs(J.accionEspecial.particulas or {}) do
      love.graphics.setColor(1, 0.85, 0.30, math.min(1, p.vida * 2))
      love.graphics.circle("fill", p.x, p.y, p.radio)
    end
    local puntaX = J.robin.x + J.robin.ultimaDirX * 18
    local puntaY = J.robin.y + J.robin.ultimaDirY * 18
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 20)
    love.graphics.setColor(1, 0.85, 0.30, 0.5 + pulso * 0.5)
    love.graphics.circle("line", puntaX, puntaY, 8 + pulso * 3)
    love.graphics.setColor(1, 0.95, 0.55, 0.8)
    love.graphics.circle("fill", puntaX, puntaY, 4)
  end

  -- ============================================================
  -- PARTICULAS CARGA RAYO ARCANO (Merlin hab 2)
  -- ============================================================
  if J.accionEspecial.tipo == "carga_rayo_arcano" then
    for _, p in ipairs(J.accionEspecial.particulas or {}) do
      love.graphics.setColor(0.55, 0.85, 1.0, math.min(1, p.vida * 2))
      love.graphics.circle("fill", p.x, p.y, p.radio)
    end
    local puntaX = J.robin.x + J.robin.ultimaDirX * 20
    local puntaY = J.robin.y + J.robin.ultimaDirY * 20
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 25)
    love.graphics.setColor(0.55, 0.85, 1.0, 0.6 + pulso * 0.4)
    love.graphics.circle("line", puntaX, puntaY, 10 + pulso * 4)
    love.graphics.setColor(0.85, 0.95, 1.0, 0.9)
    love.graphics.circle("fill", puntaX, puntaY, 5)
  end

  -- ============================================================
  -- PARTICULAS CARGA IRA CARMESI (Merlin hab 3)
  -- ============================================================
  if J.accionEspecial.tipo == "carga_ira_carmesi" then
    for _, p in ipairs(J.accionEspecial.particulas or {}) do
      love.graphics.setColor(0.85, 0.10, 0.05, math.min(1, p.vida * 1.5))
      love.graphics.circle("fill", p.x, p.y, p.radio)
      love.graphics.setColor(1, 0.40, 0.20, math.min(1, p.vida * 2))
      love.graphics.circle("fill", p.x, p.y, p.radio * 0.5)
    end
  end

  -- ============================================================
  -- RAYOS CAYENDO DE IRA CARMESI (Merlin hab 3)
  -- ============================================================
  if J.accionEspecial.tipo == "ira_carmesi_activa" then
    for _, r in ipairs(J.accionEspecial.rayos or {}) do
      if r.activo and r.target then
        local tx = r.target.x
        local ty = r.target.y
        local tiempo = r.timer - r.delay
        local alpha = math.max(0, 1 - tiempo / 0.6)

        love.graphics.setColor(0.65, 0.05, 0.02, 0.30 * alpha)
        love.graphics.rectangle("fill", tx - 30, ty - 260, 60, 260)

        love.graphics.setColor(1, 0.15, 0.08, 0.9 * alpha)
        love.graphics.setLineWidth(22)
        love.graphics.line(tx, ty - 240, tx, ty)

        love.graphics.setColor(1, 0.45, 0.18, 0.9 * alpha)
        love.graphics.setLineWidth(14)
        love.graphics.line(tx, ty - 240, tx, ty)

        love.graphics.setColor(0.85, 0.10, 0.05, 0.95 * alpha)
        love.graphics.setLineWidth(7)
        love.graphics.line(tx, ty - 240, tx, ty)

        love.graphics.setColor(0.05, 0.01, 0.01, 0.9 * alpha)
        love.graphics.setLineWidth(3)
        love.graphics.line(tx, ty - 240, tx, ty)
        love.graphics.setLineWidth(1)

        if tiempo < 0.5 then
          local rExp = tiempo * 180
          love.graphics.setColor(1, 0.20, 0.10, 0.7 * alpha)
          love.graphics.circle("fill", tx, ty, rExp)
          love.graphics.setColor(1, 0.50, 0.20, 0.6 * alpha)
          love.graphics.circle("fill", tx, ty, rExp * 0.65)
          love.graphics.setColor(1, 0.90, 0.60, 0.55 * alpha)
          love.graphics.circle("fill", tx, ty, rExp * 0.35)
          love.graphics.setColor(0.05, 0.01, 0.01, 0.7 * alpha)
          love.graphics.setLineWidth(3)
          love.graphics.circle("line", tx, ty, rExp * 0.9)
          love.graphics.setLineWidth(1)
        end

        for i = 1, 6 do
          local ang = love.timer.getTime() * 10 + i * 1.2
          local dd = 30 + math.sin(love.timer.getTime() * 8 + i) * 10
          local dx = math.cos(ang) * dd
          local dy = math.sin(ang) * dd
          love.graphics.setColor(1, 0.40, 0.20, 0.9 * alpha)
          love.graphics.circle("fill", tx + dx, ty + dy, 3)
          love.graphics.setColor(1, 0.90, 0.50, 0.9 * alpha)
          love.graphics.circle("fill", tx + dx, ty + dy, 1.5)
        end
      end
    end
  end

  -- ============================================================
  -- ESPADA VOLANDO EN DANZA CORTANTE (Conan hab 3)
  -- ============================================================
  if J.accionEspecial.tipo == "danza_cortante"
     and J.accionEspecial.fase == 1
     and J.accionEspecial.enemigoObjetivo then
    local e = J.accionEspecial.enemigoObjetivo
    local total = J.accionEspecial.duracion
    local progreso = math.min(1, J.accionEspecial.timer / (total * 0.30))
    local espadaX = J.accionEspecial.origenX + (e.x - J.accionEspecial.origenX) * progreso
    local espadaY = J.accionEspecial.origenY + (e.y - J.accionEspecial.origenY) * progreso
    local angulo = math.atan2(e.y - J.accionEspecial.origenY, e.x - J.accionEspecial.origenX)
    love.graphics.push()
    love.graphics.translate(espadaX, espadaY)
    love.graphics.rotate(angulo)
    love.graphics.setColor(0.90, 0.90, 0.95)
    love.graphics.rectangle("fill", -10, -2, 22, 4)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle("fill", -10, -2, 22, 1.5)
    love.graphics.setColor(0.55, 0.40, 0.25)
    love.graphics.rectangle("fill", -14, -3, 5, 6, 1)
    love.graphics.pop()
  end

  -- ============================================================
  -- ESCUDO ARCANO
  -- ============================================================
  if J.accionEspecial.tipo == "escudo_arcano" then
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 8)
    love.graphics.setColor(0.65, 0.55, 1.0, 0.20 + pulso * 0.20)
    love.graphics.circle("fill", J.robin.x, J.robin.y, 24)
    love.graphics.setColor(0.85, 0.75, 1.0, 0.7 + pulso * 0.3)
    love.graphics.circle("line", J.robin.x, J.robin.y, 24)
  end

  -- ============================================================
  -- DRON CENTINELA (Nyx-7 hab 1)
  -- ============================================================
  if J.robin.dron and J.robin.dron.activo then
    local d = J.robin.dron
    local dx = J.robin.x + math.cos(d.angulo) * d.radioOrbita
    local dy = J.robin.y + math.sin(d.angulo) * d.radioOrbita
    local pulso = 0.5 + 0.5 * math.sin(love.timer.getTime() * 8)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.30, 0.75, 1.0, 0.20 + pulso * 0.15)
    love.graphics.circle("fill", dx, dy, 10)
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(0.35, 0.40, 0.50)
    love.graphics.circle("fill", dx, dy, 5)
    love.graphics.setColor(0.60, 0.75, 0.90)
    love.graphics.circle("line", dx, dy, 5)

    love.graphics.setColor(0.55, 0.90, 1.0)
    love.graphics.circle("fill", dx, dy, 2.5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", dx, dy, 1)

    local t = love.timer.getTime()
    for i = 1, 4 do
      local a = t * 15 + i * (math.pi * 2 / 4)
      love.graphics.setColor(0.55, 0.90, 1.0, 0.7)
      love.graphics.line(dx, dy, dx + math.cos(a) * 7, dy + math.sin(a) * 7)
    end
  end

  -- ============================================================
  -- ANCLAJE GRAVIMETRICO (Nyx-7 hab 2)
  -- ============================================================
  if J.accionEspecial.tipo == "anclaje_gravimetrico" then
    local a = J.accionEspecial
    local t = love.timer.getTime()
    local pulso = 0.5 + 0.5 * math.sin(t * 6)
    local progreso = 1 - (a.timer / a.duracion)

    love.graphics.setColor(0.30, 0.75, 1.0, 0.10 + pulso * 0.08)
    love.graphics.circle("fill", a.zonaX, a.zonaY, a.radio)

    love.graphics.setColor(0.55, 0.90, 1.0, 0.55 + pulso * 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", a.zonaX, a.zonaY, a.radio)
    love.graphics.setLineWidth(1)

    for i = 1, 3 do
      local r = a.radio * (i / 4)
      local ang = t * (i % 2 == 0 and 1 or -1) * 1.5
      love.graphics.setColor(0.55, 0.90, 1.0, 0.40)
      love.graphics.circle("line", a.zonaX, a.zonaY, r)

      love.graphics.setColor(0.85, 0.98, 1.0, 0.9)
      love.graphics.circle("fill",
        a.zonaX + math.cos(ang) * r,
        a.zonaY + math.sin(ang) * r, 2.5)
    end

    love.graphics.setColor(0.85, 0.98, 1.0, 0.7 + pulso * 0.3)
    love.graphics.circle("fill", a.zonaX, a.zonaY, 6 + pulso * 2)
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.circle("fill", a.zonaX, a.zonaY, 3)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(0.30, 0.75, 1.0, 0.10 + pulso * 0.10)
    love.graphics.circle("fill", a.zonaX, a.zonaY, a.radio * (1.0 + progreso * 0.1))
    love.graphics.setBlendMode("alpha")
  end

  -- ============================================================
  -- RAFAGA ORBITAL (Nyx-7 hab 3)
  -- ============================================================
  if J.accionEspecial.tipo == "rafaga_orbital_activa" then
    local a = J.accionEspecial
    local t = love.timer.getTime()

    for _, r in ipairs(a.rayos or {}) do
      if r.activo then
        local tx = r.x
        local ty = r.y
        local tiempo = r.timer - r.delay
        local alpha = math.max(0, 1 - tiempo / 0.55)

        love.graphics.setColor(0.30, 0.75, 1.0, 0.20 * alpha)
        love.graphics.rectangle("fill", tx - 20, ty - 280, 40, 280)

        love.graphics.setColor(0.55, 0.90, 1.0, 0.85 * alpha)
        love.graphics.setLineWidth(16)
        love.graphics.line(tx, ty - 260, tx, ty)

        love.graphics.setColor(0.85, 0.98, 1.0, 0.95 * alpha)
        love.graphics.setLineWidth(9)
        love.graphics.line(tx, ty - 260, tx, ty)

        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineWidth(3)
        love.graphics.line(tx, ty - 260, tx, ty)
        love.graphics.setLineWidth(1)

        if tiempo < 0.45 then
          local rExp = tiempo * 200
          love.graphics.setColor(0.55, 0.90, 1.0, 0.85 * alpha)
          love.graphics.circle("fill", tx, ty, rExp)
          love.graphics.setColor(1, 1, 1, 0.90 * alpha)
          love.graphics.circle("fill", tx, ty, rExp * 0.5)
          love.graphics.setColor(0.30, 0.75, 1.0, 0.70 * alpha)
          love.graphics.setLineWidth(3)
          love.graphics.circle("line", tx, ty, rExp * 1.2)
          love.graphics.setLineWidth(1)
        end

        for i = 1, 4 do
          local ang = t * 8 + i * 1.6
          local d = 15 + math.sin(t * 6 + i) * 6
          love.graphics.setColor(0.85, 0.98, 1.0, 0.90 * alpha)
          love.graphics.circle("fill", tx + math.cos(ang) * d, ty + math.sin(ang) * d, 2)
        end
      end
    end
  end

  -- ============================================================
  -- CANCION DE CUNA (Lyra hab 1)
  -- ============================================================
  if J.accionEspecial.tipo == "cancion_cuna" then
    -- La cancion de cuna es instantanea, se dibuja a traves del corte
    -- (ver cortes.lua). Aqui solo dejamos un hook por si se necesita.
  end

  -- ============================================================
  -- PARTICULAS DE DESINTEGRACION (Nyx-7 - kills de rafaga orbital)
  -- ============================================================
  for _, p in ipairs(J.designtegraciones or {}) do
    local a = p.vida / p.maxVida
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], a * 0.35)
    love.graphics.circle("fill", p.x, p.y, p.radio * 3)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], a)
    love.graphics.circle("fill", p.x, p.y, p.radio)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.circle("fill", p.x, p.y, p.radio * 0.4)
  end
end

return J