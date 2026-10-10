local E = require("src.entidades.enemigo.base")
local Colisiones = require("src.sistemas.colisiones")

-- Decide si empezar un ataque especial (solo elites con cooldown listo)
function E:probarAtaqueEspecial(objetivo)
  if not self.esElite then return false end
  if self.habCooldown > 0 then return false end
  if self.habEstado ~= "listo" and self.habEstado ~= "cooldown" then return false end

  local dx = objetivo.x - self.x
  local dy = objetivo.y - self.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d > 300 then return false end

  if self.habEspecial and math.random() < 0.15 then
    self.habEstado = "windup"
    self.habTimer = 0
    return true
  end
  return false
end

-- Actualiza el ataque especial activo (llamado desde base cuando habEstado no es "listo")
function E:actualizarAtaqueEspecial(dt, mapa, objetivo)
  self.habTimer = self.habTimer + dt

  local velMult = self.velocidadMultiplicador or 1
  local danoMult = self.danoMultiplicador or 1

  -- ===== SLIME ELITE: SALTO TRIPLE =====
  if self.habEspecial == "salto_triple" then
    if self.habEstado == "windup" then
      if self.habTimer >= 0.6 then
        self.habEstado = "activo"
        self.habTimer = 0
        self.habExtraData.saltos = 0
        self.habExtraData.saltoTimer = 0
      end
    elseif self.habEstado == "activo" then
      self.habExtraData.saltoTimer = self.habExtraData.saltoTimer - dt
      if self.habExtraData.saltoTimer <= 0 then
        self.habExtraData.saltos = self.habExtraData.saltos + 1
        local dx = objetivo.x - self.x
        local dy = objetivo.y - self.y
        local m = math.sqrt(dx * dx + dy * dy)
        if m > 0.001 then
          self.dirX, self.dirY = dx / m, dy / m
        end
        self.saltoProgreso = 0
        self.estado = "saltando"
        self.timer = 0.25
        self.habExtraData.saltoTimer = 0.28

        if self.habExtraData.saltos >= 3 then
          self.habEstado = "cooldown"
          self.habTimer = 0
          self.habCooldown = 3.0
          return
        end
      end

      -- Movimiento durante el salto
      local vel = 260 * velMult
      local vx = self.dirX * vel * dt
      local vy = self.dirY * vel * dt
      local nx = self.x + vx
      if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
      local ny = self.y + vy
      if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end
    end
  end

  -- ===== GUARDIA ELITE: ESTOCADA CARGADA =====
  if self.habEspecial == "estocada_cargada" then
    if self.habEstado == "windup" then
      local ang = math.atan2(objetivo.y - self.y, objetivo.x - self.x)
      local vel = -40 * velMult
      self.x = self.x + math.cos(ang) * vel * dt
      self.y = self.y + math.sin(ang) * vel * dt

      if self.habTimer >= 1.0 then
        self.habEstado = "activo"
        self.habTimer = 0
        self.habExtraData.yaGolpeo = false
        local dx2 = objetivo.x - self.x
        local dy2 = objetivo.y - self.y
        local m2 = math.sqrt(dx2 * dx2 + dy2 * dy2)
        if m2 > 0.001 then
          self.ultimaDirX, self.ultimaDirY = dx2 / m2, dy2 / m2
        end
      end
    elseif self.habEstado == "activo" then
      local vel = 500 * velMult
      local vx = self.ultimaDirX * vel * dt
      local vy = self.ultimaDirY * vel * dt
      local nx = self.x + vx
      if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
      local ny = self.y + vy
      if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

      if not self.habExtraData.yaGolpeo then
        local dx = objetivo.x - self.x
        local dy = objetivo.y - self.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < self.radio + objetivo.radio + 8 then
          self.habExtraData.yaGolpeo = true
          objetivo:recibirDanio(3 * danoMult)
          local angulo = math.atan2(self.ultimaDirY, self.ultimaDirX)
          local empuje = 400
          if objetivo.aplicarKnockback then
            objetivo:aplicarKnockback(math.cos(angulo), math.sin(angulo), empuje)
          else
            objetivo.x = objetivo.x + math.cos(angulo) * 40
            objetivo.y = objetivo.y + math.sin(angulo) * 40
          end
        end
      end

      if self.habTimer >= 0.5 then
        self.habEstado = "cooldown"
        self.habTimer = 0
        self.habCooldown = 4.0
      end
    end
  end

  -- ===== ARQUERO ELITE: ABANICO DE FLECHAS =====
  if self.habEspecial == "abanico_flechas" then
    if self.habEstado == "windup" then
      if self.habTimer >= 0.7 then
        self.habEstado = "activo"
        self.habTimer = 0
        local baseAng = math.atan2(objetivo.y - self.y, objetivo.x - self.x)
        for k = -1, 1 do
          local ang = baseAng + k * math.rad(18)
          self.habExtraData["flecha_" .. (k + 2)] = {
            dirX = math.cos(ang),
            dirY = math.sin(ang),
          }
        end
        self.quiereDispararAbanico = true
      end
    elseif self.habEstado == "activo" then
      if self.habTimer >= 0.2 then
        self.habEstado = "cooldown"
        self.habTimer = 0
        self.habCooldown = 3.5
      end
    end
  end

  -- ===== RATA ELITE: DASH ATURDIDOR =====
  if self.habEspecial == "dash_aturdidor" then
    if self.habEstado == "windup" then
      if self.habTimer >= 0.5 then
        self.habEstado = "activo"
        self.habTimer = 0
        self.habExtraData.yaGolpeo = false
        local dx = objetivo.x - self.x
        local dy = objetivo.y - self.y
        local m = math.sqrt(dx * dx + dy * dy)
        if m > 0.001 then
          self.dashRata = {
            dirX = dx / m,
            dirY = dy / m,
            duracion = 0.35,
          }
        end
      end
    elseif self.habEstado == "activo" then
      if self.dashRata then
        local vel = 400 * velMult
        local vx = self.dashRata.dirX * vel * dt
        local vy = self.dashRata.dirY * vel * dt
        local nx = self.x + vx
        if not Colisiones.circuloConMapa(nx, self.y, self.radio, mapa) then self.x = nx end
        local ny = self.y + vy
        if not Colisiones.circuloConMapa(self.x, ny, self.radio, mapa) then self.y = ny end

        if not self.habExtraData.yaGolpeo then
          local dx = objetivo.x - self.x
          local dy = objetivo.y - self.y
          local d = math.sqrt(dx * dx + dy * dy)
          if d < self.radio + objetivo.radio + 6 then
            self.habExtraData.yaGolpeo = true
            objetivo:recibirDanio(2 * danoMult)
            if objetivo.aplicarStun then
              objetivo:aplicarStun(1.0)
            end
          end
        end

        if self.habTimer >= self.dashRata.duracion then
          self.dashRata = nil
          self.habEstado = "cooldown"
          self.habTimer = 0
          self.habCooldown = 5.0
        end
      else
        self.habEstado = "cooldown"
        self.habTimer = 0
        self.habCooldown = 5.0
      end
    end
  end

  -- ===== MURCIELAGO ELITE: ONDA SONICA =====
  if self.habEspecial == "onda_sonica" then
    if self.habEstado == "windup" then
      if self.habTimer >= 0.6 then
        self.habEstado = "activo"
        self.habTimer = 0
        self.ondaSonica = {
          x = self.x,
          y = self.y,
          radio = 0,
          timer = 0,
          hitPlayer = false,
        }
      end
    elseif self.habEstado == "activo" then
      if self.habTimer >= 1.5 then
        self.habEstado = "cooldown"
        self.habTimer = 0
        self.habCooldown = 4.5
      end
    end
  end

  -- ===== MAGO ELITE: LLUVIA DE BOLAS =====
  if self.habEspecial == "lluvia_bolas" then
    if self.habEstado == "windup" then
      if self.habTimer >= 1.0 then
        self.habEstado = "activo"
        self.habTimer = 0
        self.habExtraData.bolas = {}
        for k = 1, 5 do
          local ang = (k / 5) * math.pi * 2
          local dist = 30 + math.random() * 40
          table.insert(self.habExtraData.bolas, {
            x = objetivo.x + math.cos(ang) * dist,
            y = objetivo.y + math.sin(ang) * dist,
            timer = 0,
            delay = k * 0.1,
          })
        end
        self.quiereDispararLluvia = true
      end
    elseif self.habEstado == "activo" then
      if self.habTimer >= 1.5 then
        self.habEstado = "cooldown"
        self.habTimer = 0
        self.habCooldown = 5.0
      end
    end
  end
end

return E