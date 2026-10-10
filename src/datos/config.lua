local Config = {}

Config.ARCHIVO = "factral_config.lua"

Config.valores = {
  volumen = 0.8,
  autoAim = true,
  escalaControles = 1.0,
  zoom = 1.5,
  escalaHUD = 1.0,
  debugConsola = false,
  efectosVisuales = true,
  shaders = true,
  sangre = true,
  shaderCalidad = 3,
}

local function serializar(t, indent)
  indent = indent or ""
  if type(t) ~= "table" then
    if type(t) == "string" then return string.format("%q", t) end
    if type(t) == "number" then return tostring(t) end
    if type(t) == "boolean" then return tostring(t) end
    return "nil"
  end
  local partes = {"{\n"}
  for k, v in pairs(t) do
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

function Config.cargar()
  if love.filesystem.getInfo(Config.ARCHIVO) then
    local contenido = love.filesystem.read(Config.ARCHIVO)
    local chunk = load("return " .. contenido)
    if chunk then
      local ok, datos = pcall(chunk)
      if ok and type(datos) == "table" then
        for k, v in pairs(datos) do
          Config.valores[k] = v
        end
      end
    end
  end
  love.audio.setVolume(Config.valores.volumen or 0.8)
end

function Config.guardar()
  local contenido = "return " .. serializar(Config.valores)
  love.filesystem.write(Config.ARCHIVO, contenido)
end

function Config.get(clave)
  return Config.valores[clave]
end

function Config.set(clave, valor)
  Config.valores[clave] = valor
  if clave == "volumen" then
    love.audio.setVolume(valor)
  end
  Config.guardar()
end

return Config