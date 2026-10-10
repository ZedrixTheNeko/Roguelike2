-- Jefe 1: REY SLIME (Catacumbas) - calibrado v2
local Base = require("src.entidades.jefes.base")
local Juice = require("src.sistemas.juice")
local atan2 = math.atan2 or math.atan
local PI = math.pi

local C = setmetatable({}, { __index = Base })
C.__index = C

function C.nuevo(x, y, escala)
  local j = Base.crear(C, {
    tipo = "slime_rey",
    nombre = "Sr. Babosius 3th",
    subtitulo = "Rey de las Catacumbas",
    x = x, y = y,
    hpMax = math.floor(340 * (escala or 1)),
    radio = 22,
    anchoDibujo = 56,
    altoDibujo = 46,
    recompensa = 30,
    danoContacto = 1,
    umbrales = { 0.66, 0.33 },
    intro = 2.4,
  })
  j.colorMuerte = { 0.4, 0.9, 0.5 }
  j.colorFase = { 0.5, 1.0, 0.3 }

  j.saltosSeguidos = 0
  j.maxSaltosSeguidos = 2
  j.recienInvocado = false

  j.squashX, j.squashY = 1, 1
  j.z, j.vz = 0, 0
  j.danoOndaPendiente = false

  j.dirX, j.dirY = 0, 1

  return j
end

function C:f()
  return (self.fase == 1 and 1) or (self.fase == 2 and 0.9) or 0.75
end

function C:iniciar(n, t)
  self.estado = "ataque"
  self.ataque = n
  self.timer = t
  self.sub = 0
  self.hecho = false
end

-- ============================================================
-- ELECCION DE ATAQUE
-- ============================================================
function C:elegir(objetivo, enemigos)
  local pool
  if self.fase == 1 then
    pool = { "salto", "salto", "escupitajo" }
  elseif self.fase == 2 then
    pool = { "salto", "salto", "salto", "escupitajo", "invocar" }
  else
    pool = { "salto", "salto", "salto", "salto", "escupitajo", "invocar" }
  end

  for _ = 1, 4 do
    local a = pool[math.random(#pool)]
    if a ~= self.ultimoAtaque then
      self.ultimoAtaque = a
      return a
    end
  end
  return pool[1]
end

-- ============================================================
-- CAMBIOS DE FASE
-- ============================================================
function C:alCambiarFase(nueva, ctx, mapa)
  self.saltosSeguidos = 0

  if nueva == 2 then
    self.maxSaltosSeguidos = 3
    self.charcos[#self.charcos + 1] = {
      x = self.x, y = self.y, radio = 22, vida = 6, dano = 1, tipo = "veneno",
    }
    ctx.minion("slime_pequeno", self.x - 50, self.y + 30)
    ctx.minion("slime_pequeno", self.x + 50, self.y + 30)

  elseif nueva == 3 then
    self.maxSaltosSeguidos = 4
    for i = 1, 3 do
      local ang = (i - 1) * PI * 2 / 3
      self.charcos[#self.charcos + 1] = {
        x = self.x + math.cos(ang) * 45,
        y = self.y + math.sin(ang) * 45,
        radio = 20, vida = 6, dano = 1, tipo = "veneno",
      }
    end
    ctx.minion("slime_pequeno", self.x - 60, self.y + 30)
    ctx.minion("slime_pequeno", self.x, self.y + 50)
    ctx.minion("slime_pequeno", self.x + 60, self.y + 30)
  end

  Juice.sacudir(6, 0.5)
  Juice.flash(0.5, 1.0, 0.4, 0.35, 0.4)
  Juice.chispas(self.x, self.y, 14, { 0.5, 1.0, 0.3 }, 120, 0.6)
end

function C:duranteTransicion(dt)
  if math.random() < 0.5 then
    Juice.chispas(
      self.x + (math.random() - 0.5) * 40,
      self.y + (math.random() - 0.5) * 30,
      1, { 0.5, 1.0, 0.3 }, 70, 0.6)
  end
end

-- ============================================================
-- ACTUALIZAR
-- ============================================================
function C:actualizar(dt, mapa, objetivo, enemigos, ctx)
  -- Fisica del salto (Z)
  if self.z > 0 or self.vz ~= 0 then
    self.vz = self.vz - 900 * dt
    self.z = self.z + self.vz * dt
    if self.z <= 0 then
      self.z = 0
      self.vz = 0
    end
  end

  -- Squash/stretch vuelve suavemente a 1
  self.squashX = self.squashX + (1 - self.squashX) * math.min(1, dt * 8)
  self.squashY = self.squashY + (1 - self.squashY) * math.min(1, dt * 8)

  if not self:tickBase(dt, mapa, objetivo, enemigos, ctx) then
    return
  end

  local f = self:f()
  local d, ux, uy = self:distA(objetivo)

  -- ============================================================
  -- IDLE
  -- ============================================================
  if self.estado == "idle" then
    if d > 100 then
      self:mover(ux, uy, 40, dt, mapa)
    end
    self.dirX, self.dirY = ux, uy
    self.timer = self.timer - dt
    if self.timer <= 0 then
      local a = self:elegir(objetivo, enemigos)
      if a == "salto" then
        self:iniciar(a, 0.55 * f)
      elseif a == "escupitajo" then
        self:iniciar(a, 0.5 * f)
      elseif a == "invocar" then
        self:iniciar(a, 0.9)
      end
    end
    return
  end

  self.timer = self.timer - dt
  local a = self.ataque

  -- ============================================================
  -- ATAQUE: SALTO (calibrado)
  -- ============================================================
  if a == "salto" then
    if self.sub == 0 then
      -- Telegraph: squash preparatorio
      self.squashX = 1.35
      self.squashY = 0.7
      if self.timer <= 0 then
        self.objetivoX = objetivo.x
        self.objetivoY = objetivo.y
        local dist = math.sqrt(
          (self.x - self.objetivoX)^2 + (self.y - self.objetivoY)^2)
        self.duracionSalto = 0.35 + dist / 400
        self.timer = self.duracionSalto

        -- UN SOLO circulo telegrafiado en el destino, que detona
        -- exactamente cuando el slime aterriza. Radio = 46.
        -- El charco y las bolas radiales se anaden como efectos.
        self:agregarZona({
          tipo = "circulo",
          x = self.objetivoX, y = self.objetivoY, r = 46,
          delay = self.duracionSalto,
          dano = 2,
          color = { 0.40, 0.85, 0.30 },
          sacudida = 4,
          post = 0.22,
          charco = (self.fase >= 2)
            and { radio = 22, vida = 6, dano = 1, tipo = "veneno" }
            or nil,
          alExplotar = function(s, z, ctx2)
            if s.fase >= 3 then
              local n = 8
              for i = 1, n do
                local ang = (i - 1) * PI * 2 / n + math.random() * 0.3
                ctx2.disparar(z.x, z.y,
                  math.cos(ang), math.sin(ang), 130, 1, "bola_slime")
              end
            end
          end,
        })

        -- Empieza el salto
        self.z = 5
        self.vz = 260
        self.sub = 1
      end

    elseif self.sub == 1 then
      -- En el aire. Aterriza cuando llega al destino.
      if self.timer <= 0 then
        self.x = self.objetivoX
        self.y = self.objetivoY
        self.squashX = 1.55
        self.squashY = 0.55
        self.z = 0
        self.vz = 0

        self.saltosSeguidos = self.saltosSeguidos + 1

        if self.saltosSeguidos < self.maxSaltosSeguidos
           and math.random() < 0.6 then
          self.sub = 0
          self.timer = 0.35 * f
        else
          self.saltosSeguidos = 0
          self.sub = 0
          self.estado = "idle"
          self.timer = 0.7 * f
        end
      end
    end

  -- ============================================================
  -- ATAQUE: ESCUPITAJO (calibrado)
  -- ============================================================
  elseif a == "escupitajo" then
    if self.sub == 0 then
      self.squashX = 0.85
      self.squashY = 1.2
      local ang = atan2(uy, ux)
      self.angEscupitajo = ang

      -- Numero de balas a cada lado segun fase:
      --   fase 1 -> 1 a cada lado (3 en total)
      --   fase 2 -> 2 a cada lado (5 en total)
      --   fase 3 -> 3 a cada lado (7 en total)
      local nExtremos = 1
      if self.fase >= 2 then nExtremos = 2 end
      if self.fase >= 3 then nExtremos = 3 end

      -- Apertura del cono = nExtremos * 14 grados (mitad).
      -- Asi el cono coincide EXACTAMENTE con el abanico de balas.
      local apertura = nExtremos * math.rad(14)

      self:agregarZona({
        tipo = "cono",
        x = self.x, y = self.y,
        ang = ang,
        apertura = apertura,
        r = 150,                    -- rango reducido (antes 230)
        delay = 0.5 * f,
        dano = 0, soloAviso = true,
        color = { 0.40, 0.85, 0.30 },
        post = 0.1,
      })

      self.timer = 0.5 * f
      self.sub = 1

    elseif self.sub == 1 then
      if self.timer <= 0 then
        self.squashX = 1.15
        self.squashY = 0.85
        local base = self.angEscupitajo

        local nExtremos = 1
        if self.fase >= 2 then nExtremos = 2 end
        if self.fase >= 3 then nExtremos = 3 end

        -- Dispara el abanico simetrico
        for i = -nExtremos, nExtremos do
          local ang = base + i * math.rad(14)
          ctx.disparar(self.x, self.y - 8,
            math.cos(ang), math.sin(ang), 180, 1, "bola_slime")
        end

        Juice.chispas(self.x, self.y - 8, 6, { 0.5, 1.0, 0.3 }, 80, 0.3)
        self.estado = "idle"
        self.timer = 0.6 * f
      end
    end

  -- ============================================================
  -- ATAQUE: INVOCAR
  -- ============================================================
  elseif a == "invocar" then
    if self.sub == 0 then
      self.squashX = 0.9
      self.squashY = 1.15
      self.timer = 0.6
      self.sub = 1
    elseif self.sub == 1 then
      if self.timer <= 0 and not self.hecho then
        self.hecho = true
        local n = (self.fase == 3) and 3 or 2
        for i = 1, n do
          local ang = (i - 1) * PI * 2 / n + math.random() * 0.5
          local px = self.x + math.cos(ang) * 50
          local py = self.y + math.sin(ang) * 50
          ctx.minion("slime_pequeno", px, py)
        end
        Juice.explosion(self.x, self.y, { 0.5, 1.0, 0.3 }, 1.2)
        Juice.sacudir(3, 0.3)
        self.timer = 0.6
      elseif self.timer <= 0 then
        self.estado = "idle"
        self.timer = 0.6 * f
      end
    end
  end
end

-- ============================================================
-- DIBUJADO
-- ============================================================
function C:dibujarCuerpo(alpha, muerto)
  local x, y = self.x, self.y - self.z
  local t = self.anim
  local f = self.fase
  local fl = self.flashDanio > 0

  local function c(r, g, b)
    if fl then love.graphics.setColor(1, 1, 1, alpha)
    else love.graphics.setColor(r, g, b, alpha) end
  end

  -- Sombra en el suelo
  love.graphics.setColor(0, 0, 0, 0.42 * alpha)
  local shadowK = 1 - math.min(0.7, self.z / 100)
  love.graphics.ellipse("fill", self.x, self.y + 14,
    (self.anchoDibujo / 2) * shadowK, 7 * shadowK)

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(self.squashX, self.squashY)

  local w, h = self.anchoDibujo, self.altoDibujo
  local colorCuerpo, colorSombra

  if fl then
    colorCuerpo, colorSombra = {1,1,1}, {0.85,0.85,0.85}
  elseif f == 3 then
    colorCuerpo, colorSombra = {0.60, 0.88, 0.45}, {0.22, 0.45, 0.28}
  elseif f == 2 then
    colorCuerpo, colorSombra = {0.45, 0.85, 0.55}, {0.18, 0.42, 0.30}
  else
    colorCuerpo, colorSombra = {0.35, 0.78, 0.62}, {0.18, 0.42, 0.35}
  end

  love.graphics.setColor(colorSombra[1], colorSombra[2], colorSombra[3], alpha)
  love.graphics.ellipse("fill", 0, h * 0.06, w / 2, h / 2)

  love.graphics.setColor(colorCuerpo[1], colorCuerpo[2], colorCuerpo[3], alpha)
  love.graphics.ellipse("fill", 0, 0, w / 2 - 1, h / 2 - 1)

  love.graphics.setColor(1, 1, 1, 0.35 * alpha)
  love.graphics.ellipse("fill", -w / 8, -h / 4, w / 3.5, h / 5)

  love.graphics.setColor(1, 1, 1, 0.20 * alpha)
  love.graphics.ellipse("fill", w / 6, -h / 6, w / 8, h / 10)

  love.graphics.setColor(1, 1, 1, 0.55 * alpha)
  love.graphics.circle("fill", -w / 4, -h / 3, 2)
  love.graphics.circle("fill", -w / 6, -h / 3 - 3, 1)

  love.graphics.setColor(colorSombra[1], colorSombra[2], colorSombra[3], 0.6 * alpha)
  love.graphics.ellipse("line", 0, 0, w / 2 - 2, h / 2 - 2)

  -- Cara
  local eyeBaseX = -6
  local eyeBaseY = -3
  local eyeOffset = 1.8

  love.graphics.setColor(1, 1, 1, 0.95 * alpha)
  love.graphics.circle("fill", eyeBaseX, eyeBaseY, 4)
  love.graphics.circle("fill", -eyeBaseX, eyeBaseY, 4)

  love.graphics.setColor(0.08, 0.08, 0.12, alpha)
  love.graphics.circle("fill",
    eyeBaseX + self.mirandoX * eyeOffset,
    eyeBaseY + self.mirandoY * eyeOffset, 2.2)
  love.graphics.circle("fill",
    -eyeBaseX + self.mirandoX * eyeOffset,
    eyeBaseY + self.mirandoY * eyeOffset, 2.2)

  love.graphics.setColor(1, 1, 1, 0.9 * alpha)
  love.graphics.circle("fill",
    eyeBaseX + self.mirandoX * eyeOffset - 0.8,
    eyeBaseY + self.mirandoY * eyeOffset - 0.8, 0.6)
  love.graphics.circle("fill",
    -eyeBaseX + self.mirandoX * eyeOffset - 0.8,
    eyeBaseY + self.mirandoY * eyeOffset - 0.8, 0.6)

  if f >= 2 then
    love.graphics.setColor(colorSombra[1], colorSombra[2], colorSombra[3], alpha)
    if f == 3 then
      love.graphics.polygon("fill",
        eyeBaseX - 4, eyeBaseY - 5,
        eyeBaseX + 1, eyeBaseY - 2,
        eyeBaseX + 1, eyeBaseY - 4)
      love.graphics.polygon("fill",
        -eyeBaseX - 1, eyeBaseY - 2,
        -eyeBaseX + 4, eyeBaseY - 5,
        -eyeBaseX - 1, eyeBaseY - 4)
    else
      love.graphics.polygon("fill",
        eyeBaseX - 3.5, eyeBaseY - 4.5,
        eyeBaseX + 1, eyeBaseY - 3,
        eyeBaseX + 1, eyeBaseY - 4)
      love.graphics.polygon("fill",
        -eyeBaseX - 1, eyeBaseY - 3,
        -eyeBaseX + 3.5, eyeBaseY - 4.5,
        -eyeBaseX - 1, eyeBaseY - 4)
    end
  end

  love.graphics.setColor(0.10, 0.10, 0.15, 0.85 * alpha)
  if self.estado == "ataque" and self.ataque == "escupitajo" then
    love.graphics.ellipse("fill", 0, 6, 5, 4)
    love.graphics.setColor(0.40, 0.90, 0.55, alpha)
    love.graphics.ellipse("fill", 0, 6, 3, 2.5)
  elseif f == 3 then
    love.graphics.arc("line", "open", 0, 4, 6, 0.2, PI - 0.2)
    love.graphics.arc("line", "open", 0, 6, 8, 0.3, PI - 0.3)
  else
    love.graphics.arc("line", "open", 0, 4, 5, 0.2, PI - 0.2)
  end

  love.graphics.pop()

  -- Corona
  love.graphics.push()
  love.graphics.translate(x, y - (self.altoDibujo / 2) * self.squashY + 2
                           + math.sin(t * 2) * 0.5)

  love.graphics.setColor(0.75, 0.55, 0.10, alpha)
  love.graphics.rectangle("fill", -16, 0, 32, 4, 1)
  love.graphics.setColor(0.95, 0.75, 0.20, alpha)
  love.graphics.rectangle("fill", -16, 0, 32, 2, 1)

  love.graphics.setColor(0.95, 0.80, 0.20, alpha)
  love.graphics.polygon("fill", -16, 0, -12, -12, -8, 0)
  love.graphics.polygon("fill", -5, 0, 0, -15, 5, 0)
  love.graphics.polygon("fill", 8, 0, 12, -12, 16, 0)

  love.graphics.setColor(1, 0.95, 0.55, alpha)
  love.graphics.polygon("fill", -15, 0, -12, -11, -10, 0)
  love.graphics.polygon("fill", -3, 0, 0, -14, 3, 0)
  love.graphics.polygon("fill", 10, 0, 12, -11, 15, 0)

  love.graphics.setColor(0.90, 0.15, 0.25, alpha)
  love.graphics.circle("fill", -12, -10, 1.8)
  love.graphics.setColor(0.30, 0.85, 0.95, alpha)
  love.graphics.circle("fill", 0, -12, 2)
  love.graphics.setColor(0.90, 0.15, 0.25, alpha)
  love.graphics.circle("fill", 12, -10, 1.8)

  love.graphics.setColor(1, 1, 1, 0.85 * alpha)
  love.graphics.circle("fill", -12.5, -10.5, 0.6)
  love.graphics.circle("fill", -0.5, -12.5, 0.7)
  love.graphics.circle("fill", 11.5, -10.5, 0.6)

  love.graphics.setColor(0.55, 0.35, 0.10, alpha)
  love.graphics.rectangle("fill", -16, 2, 32, 1)

  love.graphics.pop()
end

return C