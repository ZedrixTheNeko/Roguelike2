-- ============================================================
-- RED: sistema de multijugador local WiFi
-- ============================================================
-- Host autoritativo. El host simula TODO y envia snapshots.
-- El cliente envia input, predice su propio jugador y aplica
-- snapshots a las entidades remotas.
-- ============================================================

local socket = require("socket")

local Red = {}

Red.PUERTO = 25565
Red.FREC_INPUT = 1 / 30
Red.FREC_SNAPSHOT = 1 / 30
Red.DELAY_INTERP = 0.08

Red.activo = false
Red.esHost = false
Red.miId = 1
Red.miNombre = "Jugador"
Red.miIp = "?"
Red.peerIp = nil
Red.peerPuerto = nil
Red.udp = nil
Red.rtt = 0
Red.rttSuavizado = 0

Red.inputLocal = { x = 0, y = 0, shoot = false, angle = 0, hab = false }
Red.inputRemoto = {
  x = 0, y = 0, shoot = false, angle = 0, hab = false,
  ultimoT = 0,
}

Red.bufferSnapshots = {}

Red.logs = {}
local function log(msg)
  table.insert(Red.logs, msg)
  if #Red.logs > 6 then table.remove(Red.logs, 1) end
  print("[RED] " .. msg)
end

-- ============================================================
-- IP
-- ============================================================
local function esIpPrivada(ip)
  return ip:match("^192%.168%.") or ip:match("^10%.")
      or ip:match("^172%.1[6-9]%.") or ip:match("^172%.2[0-9]%.")
      or ip:match("^172%.3[01]%.")
end

local function ipValida(ip)
  if type(ip) ~= "string" or #ip < 7 then return false end
  if ip == "127.0.0.1" or ip == "0.0.0.0" then return false end
  if ip:find(":") then return false end
  if ip:match("^169%.254%.") then return false end
  return true
end

function Red.detectarIp()
  if socket.getifaddrs then
    local ok, ifaddrs = pcall(socket.getifaddrs)
    if ok and ifaddrs then
      local cands = {}
      for _, iface in ipairs(ifaddrs) do
        if iface.addr and iface.addr.ip then
          local ip = iface.addr.ip
          if ipValida(ip) then
            if esIpPrivada(ip) then return ip end
            table.insert(cands, ip)
          end
        end
      end
      if #cands > 0 then return cands[1] end
    end
  end
  local objetivos = {
    {"8.8.8.8", 80}, {"1.1.1.1", 53},
    {"192.168.1.1", 1}, {"192.168.0.1", 1},
    {"192.168.43.1", 1}, {"10.0.0.1", 1},
  }
  for _, o in ipairs(objetivos) do
    local ok, s = pcall(socket.udp)
    if ok and s then
      pcall(function() s:settimeout(0) end)
      if pcall(function() s:connect(o[1], o[2]) end) then
        local ip = s:getsockname()
        pcall(function() s:close() end)
        if ipValida(ip) then return ip end
      else
        pcall(function() s:close() end)
      end
    end
  end
  return "?"
end

-- ============================================================
-- SERIALIZACION
-- ============================================================
local function serializarSnapshot()
  local J = require("src.estados.juego.estado")
  if not J.salaActual or not J.robin then return nil end

  local lineas = {"TICK " .. (Red.tick or 0)}

  -- Mi jugador
  local r = J.robin
  local angR = 0
  if r.ultimaDirX and r.ultimaDirY then
    angR = math.atan2(r.ultimaDirY, r.ultimaDirX)
  end
  table.insert(lineas, string.format(
    "PLAYER 1 %.1f %.1f %.2f %d %d %s",
    r.x, r.y, angR, r.hp or 0, r.hpMax or 1, r.tipoArma or "arco"))

  -- Enemigos con ID estable
  if J.salaActual.enemigos then
    for idx, e in ipairs(J.salaActual.enemigos) do
      if e.vivo then
        local angE = 0
        if e.ultimaDirX and e.ultimaDirY then
          angE = math.atan2(e.ultimaDirY, e.ultimaDirX)
        end
        local eid = e.id or idx
        table.insert(lineas, string.format(
          "ENEMY %d %s %.1f %.1f %d %d %.2f",
          eid, e.tipo or "slime_pequeno", e.x, e.y,
          math.floor(e.hp or 0), math.floor(e.hpMax or 1), angE))
      end
    end
  end

  -- Proyectiles del jugador (host)
  if J.poolFlechas then
    local n = 0
    for p in J.poolFlechas:iterarActivos() do
      n = n + 1
      if n > 40 then break end
      table.insert(lineas, string.format(
        "PROJ %d %s %.1f %.1f %.1f %.1f",
        n, p.tipo or "flecha", p.x, p.y, p.vx or 0, p.vy or 0))
    end
  end

  -- Proyectiles enemigos
  if J.poolFlechasEnemigas then
    local n = 100
    for p in J.poolFlechasEnemigas:iterarActivos() do
      n = n + 1
      if n > 140 then break end
      table.insert(lineas, string.format(
        "EPROJ %d %s %.1f %.1f %.1f %.1f",
        n, p.tipo or "flecha", p.x, p.y, p.vx or 0, p.vy or 0))
    end
  end

  -- Jefe
  if J.salaActual.jefe and J.salaActual.jefe.vivo then
    local jf = J.salaActual.jefe
    table.insert(lineas, string.format(
      "BOSS %s %.1f %.1f %d %d %d",
      jf.tipo or "jefe", jf.x, jf.y,
      math.floor(jf.hp or 0), math.floor(jf.hpMax or 1),
      jf.fase or 1))
  end

  -- Drops
  if J.drops then
    local n = 0
    for _, d in ipairs(J.drops) do
      n = n + 1
      if n > 30 then break end
      table.insert(lineas, string.format(
        "DROP %d %s %.1f %.1f",
        n, d.tipo or "moneda", d.x, d.y))
    end
  end

  return table.concat(lineas, "\n")
end

-- ============================================================
-- APLICAR SNAPSHOT
-- ============================================================
local function aplicarSnapshot(str, ahora)
  local J = require("src.estados.juego.estado")

  local snap = {
    t = ahora,
    jugadores = {},
    enemigos = {},
    proyectiles = {},
    eproyectiles = {},
    drops = {},
    jefe = nil,
  }

  for linea in str:gmatch("[^\n]+") do
    local tipo = linea:match("^(%a+)") or ""

    if tipo == "PLAYER" then
      local id, x, y, dir, hp, hpmax, arma = linea:match(
        "^PLAYER (%d+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+) (%d+) (%d+) (%w+)$")
      if id then
        snap.jugadores[tonumber(id)] = {
          id = tonumber(id),
          x = tonumber(x), y = tonumber(y),
          dir = tonumber(dir),
          hp = tonumber(hp), hpMax = tonumber(hpmax),
          tipoArma = arma,
        }
      end

    elseif tipo == "ENEMY" then
      local id, etipo, x, y, hp, hpmax, dir = linea:match(
        "^ENEMY (%d+) ([%w_]+) (%-?[%d%.]+) (%-?[%d%.]+) (%d+) (%d+) (%-?[%d%.]+)$")
      if id then
        snap.enemigos[tonumber(id)] = {
          id = tonumber(id), tipo = etipo,
          x = tonumber(x), y = tonumber(y),
          hp = tonumber(hp), hpMax = tonumber(hpmax),
          dir = tonumber(dir),
        }
      end

    elseif tipo == "PROJ" then
      local id, ptipo, x, y, vx, vy = linea:match(
        "^PROJ (%d+) ([%w_]+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+)$")
      if id then
        snap.proyectiles[tonumber(id)] = {
          id = tonumber(id), tipo = ptipo,
          x = tonumber(x), y = tonumber(y),
          vx = tonumber(vx), vy = tonumber(vy),
        }
      end

    elseif tipo == "EPROJ" then
      local id, ptipo, x, y, vx, vy = linea:match(
        "^EPROJ (%d+) ([%w_]+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+) (%-?[%d%.]+)$")
      if id then
        snap.eproyectiles[tonumber(id)] = {
          id = tonumber(id), tipo = ptipo,
          x = tonumber(x), y = tonumber(y),
          vx = tonumber(vx), vy = tonumber(vy),
        }
      end

    elseif tipo == "BOSS" then
      local bt, x, y, hp, hpmax, fase = linea:match(
        "^BOSS ([%w_]+) (%-?[%d%.]+) (%-?[%d%.]+) (%d+) (%d+) (%d+)$")
      if bt then
        snap.jefe = {
          tipo = bt, x = tonumber(x), y = tonumber(y),
          hp = tonumber(hp), hpMax = tonumber(hpmax),
          fase = tonumber(fase),
        }
      end

    elseif tipo == "DROP" then
      local id, dtipo, x, y = linea:match(
        "^DROP (%d+) ([%w_]+) (%-?[%d%.]+) (%-?[%d%.]+)$")
      if id then
        snap.drops[tonumber(id)] = {
          id = tonumber(id), tipo = dtipo,
          x = tonumber(x), y = tonumber(y),
        }
      end
    end
  end

  table.insert(Red.bufferSnapshots, snap)
  if #Red.bufferSnapshots > 30 then
    table.remove(Red.bufferSnapshots, 1)
  end

  -- Reconciliar mi propio jugador
  local yo = snap.jugadores[2]
  if yo and J.robin then
    local errX = yo.x - J.robin.x
    local errY = yo.y - J.robin.y
    local errD = math.sqrt(errX * errX + errY * errY)
    if errD > 40 then
      J.robin.x, J.robin.y = yo.x, yo.y
    elseif errD > 1 then
      J.robin.x = J.robin.x + errX * 0.25
      J.robin.y = J.robin.y + errY * 0.25
    end
  end

  -- Guardar remotos para render
  J.remotos = J.remotos or {}
  local host = snap.jugadores[1]
  if host then
    J.remotos[1] = {
      id = 1, nombre = "Host",
      x = host.x, y = host.y, dir = host.dir,
      hp = host.hp, hpMax = host.hpMax,
      tipoArma = host.tipoArma,
    }
  end

  J.remotosEnemigos = {}
  for id, e in pairs(snap.enemigos) do
    J.remotosEnemigos[id] = e
  end

  J.remotosProyectiles = {}
  for id, p in pairs(snap.proyectiles) do
    J.remotosProyectiles[id] = p
  end

  J.remotosEProyectiles = {}
  for id, p in pairs(snap.eproyectiles) do
    J.remotosEProyectiles[id] = p
  end

  J.remotosDrops = {}
  for id, d in pairs(snap.drops) do
    J.remotosDrops[id] = d
  end

  J.remotosJefe = snap.jefe
end

-- ============================================================
-- INTERPOLACION
-- ============================================================
function Red.actualizarInterpolacion(ahora)
  if Red.esHost then return end

  local tObjetivo = ahora - Red.DELAY_INTERP
  local buffer = Red.bufferSnapshots
  if #buffer < 2 then return end

  local s0, s1
  for i = #buffer, 1, -1 do
    if buffer[i].t <= tObjetivo then
      s0 = buffer[i]
      s1 = buffer[i + 1]
      break
    end
  end
  if not s0 then
    s0 = buffer[#buffer]
    s1 = nil
  end

  local J = require("src.estados.juego.estado")

  if J.remotosEnemigos and s0 then
    local snapA = s0.enemigos
    local snapB = (s1 and s1.enemigos) or snapA
    local span = s1 and (s1.t - s0.t) or 0
    local k = 0
    if span > 0 then
      k = math.max(0, math.min(1, (tObjetivo - s0.t) / span))
    end
    for id, eA in pairs(snapA) do
      local eB = snapB[id]
      local e = J.remotosEnemigos[id]
      if e and eB then
        e.x = eA.x + (eB.x - eA.x) * k
        e.y = eA.y + (eB.y - eA.y) * k
      end
    end
  end
end

-- ============================================================
-- HOST
-- ============================================================
function Red.iniciarHost(nombre)
  Red.activo = true
  Red.esHost = true
  Red.miId = 1
  Red.miNombre = nombre or "Host"

  Red.udp = socket.udp()
  Red.udp:settimeout(0)
  Red.udp:setoption("broadcast", true)

  local ok, err = Red.udp:setsockname("0.0.0.0", Red.PUERTO)
  if not ok then
    log("ERROR setsockname: " .. tostring(err))
    Red.detener()
    return false
  end

  Red.miIp = Red.detectarIp()
  log("HOST en " .. Red.miIp .. ":" .. Red.PUERTO)
  return true
end

function Red.actualizarHost(dt)
  while true do
    local data, ip, puerto = Red.udp:receivefrom()
    if not data then break end

    if not Red.peerIp then
      Red.peerIp = ip
      Red.peerPuerto = puerto
      log("Cliente: " .. ip .. ":" .. puerto)
    end

    local seq, dxS, dyS, shS, angS, habS = data:match(
      "^INPUT (%d+) (%-?[%d%.]+) (%-?[%d%.]+) (%d) (%-?[%d%.]+) (%d)$")
    if seq then
      Red.inputRemoto.x = tonumber(dxS) or 0
      Red.inputRemoto.y = tonumber(dyS) or 0
      Red.inputRemoto.shoot = (shS == "1")
      Red.inputRemoto.angle = tonumber(angS) or 0
      Red.inputRemoto.hab = (habS == "1")
      Red.inputRemoto.ultimoT = love.timer.getTime()
    end

    local pSeq, pTs = data:match("^PING (%d+) ([%d%.]+)$")
    if pSeq and pTs then
      Red.udp:sendto("PONG " .. pSeq .. " " .. pTs, ip, puerto)
    end

    if data == "BYE" then
      log("Cliente desconectado")
      Red.peerIp = nil
      Red.peerPuerto = nil
    end
  end

  if (love.timer.getTime() - Red.inputRemoto.ultimoT) > 0.5 then
    Red.inputRemoto.x = 0
    Red.inputRemoto.y = 0
    Red.inputRemoto.shoot = false
    Red.inputRemoto.hab = false
  end

  Red.tiempoSnapshot = (Red.tiempoSnapshot or 0) + dt
  if Red.tiempoSnapshot >= Red.FREC_SNAPSHOT and Red.peerIp and Red.peerPuerto then
    Red.tiempoSnapshot = 0
    Red.tick = (Red.tick or 0) + 1
    local str = serializarSnapshot()
    if str then
      Red.udp:sendto(str, Red.peerIp, Red.peerPuerto)
    end
  end
end

-- ============================================================
-- CLIENTE
-- ============================================================
function Red.conectar(ip, nombre)
  Red.activo = true
  Red.esHost = false
  Red.miId = 2
  Red.miNombre = nombre or "Cliente"

  Red.udp = socket.udp()
  Red.udp:settimeout(0)

  local ok, err = Red.udp:setpeername(ip, Red.PUERTO)
  if not ok then
    log("ERROR: " .. tostring(err))
    Red.detener()
    return false
  end

  Red.peerIp = ip
  Red.peerPuerto = Red.PUERTO
  Red.bufferSnapshots = {}

  Red.udp:send("HELLO " .. Red.miNombre)
  log("Conectado a " .. ip)
  return true
end

function Red.actualizarCliente(dt)
  Red.tiempoSeq = (Red.tiempoSeq or 0) + dt
  if Red.tiempoSeq >= Red.FREC_INPUT then
    Red.tiempoSeq = 0
    Red.seq = (Red.seq or 0) + 1
    local i = Red.inputLocal
    local shoot = i.shoot and 1 or 0
    local hab = i.hab and 1 or 0
    Red.udp:send(string.format("INPUT %d %.3f %.3f %d %.3f %d",
      Red.seq, i.x, i.y, shoot, i.angle or 0, hab))
  end

  Red.tiempoPing = (Red.tiempoPing or 0) + dt
  if Red.tiempoPing >= 0.5 then
    Red.tiempoPing = 0
    Red.pingSeq = (Red.pingSeq or 0) + 1
    Red.udp:send("PING " .. Red.pingSeq .. " " .. string.format("%.3f", love.timer.getTime()))
  end

  local ahora = love.timer.getTime()
  while true do
    local data = Red.udp:receive()
    if not data then break end

    local pSeq, pTs = data:match("^PONG (%d+) ([%d%.]+)$")
    if pSeq and pTs then
      local rtt = (ahora - tonumber(pTs)) * 1000
      if rtt >= 0 and rtt < 5000 then
        Red.rtt = math.floor(rtt)
        Red.rttSuavizado = Red.rttSuavizado == 0 and Red.rtt
          or (Red.rttSuavizado * 0.7 + Red.rtt * 0.3)
      end
    elseif data:sub(1, 4) == "TICK" then
      aplicarSnapshot(data, ahora)
    end
  end
end

-- ============================================================
-- GENERAL
-- ============================================================
function Red.actualizar(dt)
  if not Red.activo or not Red.udp then return end
  if Red.esHost then
    Red.actualizarHost(dt)
  else
    Red.actualizarCliente(dt)
  end
  Red.actualizarInterpolacion(love.timer.getTime())
end

function Red.detener()
  if Red.udp then
    pcall(function()
      if Red.esHost and Red.peerIp and Red.peerPuerto then
        Red.udp:sendto("BYE", Red.peerIp, Red.peerPuerto)
      elseif not Red.esHost then
        Red.udp:send("BYE")
      end
    end)
    pcall(function() Red.udp:close() end)
  end
  Red.activo = false
  Red.esHost = false
  Red.udp = nil
  Red.peerIp = nil
  Red.peerPuerto = nil
  Red.bufferSnapshots = {}
  Red.logs = {}
end

function Red.enviarInput(x, y, shoot, angle, hab)
  Red.inputLocal.x = x or 0
  Red.inputLocal.y = y or 0
  Red.inputLocal.shoot = shoot or false
  Red.inputLocal.angle = angle or 0
  Red.inputLocal.hab = hab or false
end

return Red