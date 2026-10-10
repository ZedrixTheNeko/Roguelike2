local Guardado = {}

Guardado.ARCHIVO = "factral_save.lua"

local DEFAULTS = {
  version = 1,
  gemas = 0,
  gemasTotales = 0,
  mejoras = {
    robin    = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    conan    = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    merlin   = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    kael     = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    shadow   = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    brunilda = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    coyote   = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    shen     = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    sable    = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    nyx      = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    lyra     = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    thorin   = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
    rex      = { vida = 0, dano = 0, velocidad = 0, habilidad = 0 },
  },
  personajesDesbloqueados = {
    robin = true, conan = true, merlin = true,
    kael = true, shadow = true, brunilda = true,
    coyote = true, shen = true, sable = true,
    nyx = true, lyra = true, thorin = true, rex = true,
  },
  estadisticas = {
    partidasJugadas = 0,
    victorias = 0,
    nivelesCompletados = 0,
    jefesDerrotados = 0,
    slimesMatados = 0,
    esqueletosMatados = 0,
    arquerosMatados = 0,
  },
  mack = {
    inventario = {},
  },
  logros = {},
}

Guardado.datos = nil
Guardado.autosaveTimer = 0
Guardado.autosaveIntervalo = 20
Guardado.guardadoPendiente = false

local function serializar(t, indent)
  indent = indent or ""
  if type(t) ~= "table" then
    if type(t) == "string" then return string.format("%q", t) end
    if type(t) == "number" then return tostring(t) end
    if type(t) == "boolean" then return tostring(t) end
    return "nil"
  end
  local partes = {"{\n"}
  local claves = {}
  for k, _ in pairs(t) do table.insert(claves, k) end
  table.sort(claves, function(a, b) return tostring(a) < tostring(b) end)

  for _, k in ipairs(claves) do
    local v = t[k]
    local clave
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then
      clave = k
    else
      clave = "[" .. serializar(k) .. "]"
    end
    table.insert(partes, indent .. "  " .. clave .. " = " .. serializar(v) .. ",\n")
  end
  table.insert(partes, indent .. "}")
  return table.concat(partes)
end

local function copia(t)
  if type(t) ~= "table" then return t end
  local c = {}
  for k, v in pairs(t) do
    c[k] = copia(v)
  end
  return c
end

local function fusionar(destino, origen)
  for k, v in pairs(origen) do
    if type(v) == "table" and type(destino[k]) == "table" then
      fusionar(destino[k], v)
    elseif destino[k] == nil then
      destino[k] = v
    end
  end
end

function Guardado.cargar()
  Guardado.datos = copia(DEFAULTS)

  if love.filesystem.getInfo(Guardado.ARCHIVO) then
    local contenido = love.filesystem.read(Guardado.ARCHIVO)
    if contenido then
      local chunk = load("return " .. contenido)
      if chunk then
        local ok, datos = pcall(chunk)
        if ok and type(datos) == "table" then
          fusionar(Guardado.datos, datos)
          print("[GUARDADO] Cargado OK. Gemas: " .. tostring(Guardado.datos.gemas))
        else
          print("[GUARDADO] ERROR al parsear, usando defaults")
        end
      end
    end
  else
    print("[GUARDADO] No existe archivo, creando uno nuevo")
    Guardado.guardar()
  end
end

function Guardado.guardar()
  if not Guardado.datos then return end
  local contenido = "return " .. serializar(Guardado.datos)
  local ok = love.filesystem.write(Guardado.ARCHIVO, contenido)
  if ok then
    print("[GUARDADO] Saved. Gemas: " .. tostring(Guardado.datos.gemas))
  else
    print("[GUARDADO] ERROR al escribir archivo")
  end
  Guardado.guardadoPendiente = false
end

function Guardado.marcarCambio()
  Guardado.guardadoPendiente = true
end

function Guardado.actualizar(dt)
  Guardado.autosaveTimer = Guardado.autosaveTimer + dt
  if Guardado.autosaveTimer >= Guardado.autosaveIntervalo then
    Guardado.autosaveTimer = 0
    if Guardado.guardadoPendiente then
      Guardado.guardar()
    end
  end
end

function Guardado.get(clave)
  if not Guardado.datos then Guardado.cargar() end
  return Guardado.datos[clave]
end

function Guardado.set(clave, valor)
  if not Guardado.datos then Guardado.cargar() end
  Guardado.datos[clave] = valor
  Guardado.marcarCambio()
end

function Guardado.agregarGemas(cantidad)
  if not Guardado.datos then Guardado.cargar() end
  Guardado.datos.gemas = Guardado.datos.gemas + cantidad
  Guardado.datos.gemasTotales = Guardado.datos.gemasTotales + cantidad
  Guardado.marcarCambio()
end

function Guardado.gastarGemas(cantidad)
  if not Guardado.datos then Guardado.cargar() end
  if Guardado.datos.gemas < cantidad then return false end
  Guardado.datos.gemas = Guardado.datos.gemas - cantidad
  Guardado.guardar()
  return true
end

function Guardado.reset()
  Guardado.datos = copia(DEFAULTS)
  Guardado.guardar()
end

return Guardado