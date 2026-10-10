-- ============================================================
-- SHADERS (GLSL) - sistema seguro
--
-- Principios anti-crash:
--   * TODO se compila y se usa dentro de pcall.
--   * Si algo falla (compilacion o ejecucion) se desactivan los shaders y
--     el juego sigue dibujando sin ellos (las luces tienen respaldo en Lua).
--   * GLSL compatible con OpenGL ES 1.00 (Android): floats con punto,
--     bucles de limite constante, sin arrays dinamicos, sin texture().
--   * Calidad adaptativa: si los FPS bajan se reduce la calidad sola.
--   * Se puede apagar desde Ajustes (Config "shaders" / "shaderCalidad").
-- ============================================================
local Config = require("src.datos.config")
local constantes = require("src.constantes")

local unpack = unpack or table.unpack

local Shaders = {}

Shaders.activo = false          -- shaders disponibles Y habilitados
Shaders.soportado = false       -- compilo correctamente
Shaders.calidad = 3             -- 1 baja, 2 media, 3 alta
Shaders.motivoFallo = nil
Shaders.tiempo = 0

local post, niebla, portal, luz, oscuridad
local fxExplosion, fxRayo, fxOnda
local variantesPost = {}
local blanco = nil

-- ------------------------------------------------------------
-- CODIGO GLSL
-- ------------------------------------------------------------
local GLSL_POST = [[
uniform float uTime;
uniform vec2 uRes;
uniform float uBloom;
uniform float uUmbral;
uniform float uAberr;
uniform float uVineta;
uniform float uSat;
uniform float uContraste;
uniform vec3 uTinte;
uniform float uPulso;
uniform float uOnda;
uniform float uGrano;
uniform vec3 uShock;
uniform float uShockF;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 brillo(vec3 c) {
  float l = dot(c, vec3(0.299, 0.587, 0.114));
  float k = smoothstep(uUmbral, uUmbral + 0.25, l);
  return c * k;
}

#define TAP(o) glow += brillo(Texel(tex, uv + (o) * px * radio).rgb)

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 px = vec2(1.0 / uRes.x, 1.0 / uRes.y);

  // Onda de calor (biomas de fuego)
  uv.x += sin(uv.y * 60.0 + uTime * 2.5) * uOnda;

  // Onda de choque (jefes, golpes fuertes)
  if (uShockF > 0.001) {
    vec2 d = uv - uShock.xy;
    d.x *= uRes.x / uRes.y;
    float dist = length(d);
    float q = (dist - uShock.z) * 16.0;
    float anillo = exp(-q * q) * uShockF;
    vec2 dir = d / max(dist, 0.0001);
    uv -= vec2(dir.x * uRes.y / uRes.x, dir.y) * anillo * 0.035;
  }

  // Aberracion cromatica
  vec2 off = (uv - vec2(0.5, 0.5)) * uAberr;
  vec3 col;
  col.r = Texel(tex, uv + off).r;
  col.g = Texel(tex, uv).g;
  col.b = Texel(tex, uv - off).b;

  // Bloom (resplandor de las zonas brillantes)
#if QUALITY >= 2
  if (uBloom > 0.001) {
    vec3 glow = vec3(0.0, 0.0, 0.0);
    float radio = 2.0 + 1.2 * float(QUALITY);
    TAP(vec2(1.0, 0.0));
    TAP(vec2(-1.0, 0.0));
    TAP(vec2(0.0, 1.0));
    TAP(vec2(0.0, -1.0));
    TAP(vec2(0.7, 0.7));
    TAP(vec2(-0.7, 0.7));
    TAP(vec2(0.7, -0.7));
    TAP(vec2(-0.7, -0.7));
#if QUALITY >= 3
    radio = radio * 2.1;
    TAP(vec2(1.0, 0.0));
    TAP(vec2(-1.0, 0.0));
    TAP(vec2(0.0, 1.0));
    TAP(vec2(0.0, -1.0));
    TAP(vec2(0.7, 0.7));
    TAP(vec2(-0.7, 0.7));
    TAP(vec2(0.7, -0.7));
    TAP(vec2(-0.7, -0.7));
    glow = glow / 16.0;
#else
    glow = glow / 8.0;
#endif
    col += glow * uBloom;
  }
#endif

  // Correccion de color
  float luma = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(luma, luma, luma), col, uSat);
  col = (col - vec3(0.5, 0.5, 0.5)) * uContraste + vec3(0.5, 0.5, 0.5);
  col = col * uTinte;

  // Vineta
  vec2 c = (uv - vec2(0.5, 0.5)) * vec2(1.0, 0.9);
  float v = 1.0 - smoothstep(0.38, 0.88, length(c)) * uVineta;
  col = col * v;

  // Pulso de dano (rojo en los bordes)
  float borde = smoothstep(0.25, 0.8, length(uv - vec2(0.5, 0.5)));
  col = mix(col, vec3(0.85, 0.05, 0.05), uPulso * (0.25 + 0.55 * borde));

  // Grano de pelicula muy sutil
#if QUALITY >= 3
  if (uGrano > 0.001) {
    float g = hash21(uv * uRes + vec2(uTime * 13.0, uTime * 7.0)) - 0.5;
    col = col + vec3(g * uGrano, g * uGrano, g * uGrano);
  }
#endif

  return vec4(clamp(col, 0.0, 1.0), 1.0) * color;
}
]]

local GLSL_NIEBLA = [[
uniform float uTime;
uniform vec2 uOffset;
uniform vec2 uVel;
uniform float uEscala;
uniform float uDensidad;
uniform float uCorte;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * ruido(p);
    p = p * 2.03 + vec2(1.7, 9.2);
    a = a * 0.5;
  }
  return v;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 p = uv * uEscala + uOffset + uVel * uTime;
  float n = fbm(p + vec2(fbm(p * 0.7 + vec2(uTime * 0.05, 0.0)) * 1.5, 0.0));
  float a = smoothstep(uCorte, uCorte + 0.45, n) * uDensidad;
  // se desvanece hacia los bordes del quad para evitar cortes
  vec2 e = min(uv, vec2(1.0, 1.0) - uv);
  a = a * smoothstep(0.0, 0.12, min(e.x, e.y));
  return vec4(color.rgb, color.a * a);
}
]]

local GLSL_PORTAL = [[
uniform float uTime;
uniform vec3 uColA;
uniform vec3 uColB;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 p = (uv - vec2(0.5, 0.5)) * 2.0;
  float r = length(p);
  float ang = atan(p.y, p.x);
  float e1 = 0.5 + 0.5 * sin(ang * 4.0 + r * 12.0 - uTime * 3.5);
  float e2 = 0.5 + 0.5 * sin(ang * 2.0 - r * 7.0 + uTime * 2.0);
  float borde = 1.0 - smoothstep(0.78, 1.0, r);
  float nucleo = 1.0 - smoothstep(0.0, 0.5, r);
  vec3 col = mix(uColA, uColB, e1 * 0.7 + e2 * 0.3);
  col = col + vec3(nucleo * 0.7, nucleo * 0.7, nucleo * 0.7);
  float alfa = borde * (0.5 + 0.5 * e1);
  return vec4(col, alfa) * color;
}
]]

local GLSL_LUZ = [[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  float d = length((uv - vec2(0.5, 0.5)) * 2.0);
  float f = clamp(1.0 - d, 0.0, 1.0);
  f = f * f * (3.0 - 2.0 * f);
  f = f * f;
  return vec4(color.rgb, color.a * f);
}
]]

-- Oscuridad de la mazmorra con "agujeros" de luz (hasta 8 luces)
local GLSL_OSCURIDAD = [[
uniform vec2 uRes;
uniform float uOscuridad;
uniform vec3 uTinte;
uniform vec3 uLuz[8];

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 p = uv * uRes;
  float luz = 0.0;
  for (int i = 0; i < 8; i++) {
    float r = uLuz[i].z;
    if (r > 0.5) {
      float d = length(p - uLuz[i].xy) / r;
      float f = clamp(1.0 - d, 0.0, 1.0);
      luz = luz + f * f * (3.0 - 2.0 * f);
    }
  }
  luz = clamp(luz, 0.0, 1.0);
  float a = uOscuridad * (1.0 - luz);
  return vec4(uTinte, a);
}
]]

-- Efectos de habilidades (quads pequenos, aditivos, baratos)
local GLSL_FX_COMUN = [[
uniform float uT;
uniform float uSeed;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
]]

local GLSL_FX_EXPLOSION = GLSL_FX_COMUN .. [[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 p = (uv - vec2(0.5, 0.5)) * 2.0;
  float r = length(p);
  float ang = atan(p.y, p.x);
  float t = uT;
  float expan = 1.0 - (1.0 - t) * (1.0 - t);
  float radio = 0.20 + 0.68 * expan;
  float n = ruido(vec2(ang * 1.6 + uSeed * 7.0, r * 4.0 - t * 2.5));
  float borde = radio * (0.80 + 0.35 * n);
  float cuerpo = (1.0 - smoothstep(borde * 0.45, borde, r)) * (1.0 - t * t);
  float q = (r - radio * 1.02) * 11.0;
  float anillo = exp(-q * q) * (1.0 - t);
  float nucleo = (1.0 - smoothstep(0.0, radio * 0.55, r)) * clamp(1.0 - t * 1.5, 0.0, 1.0);
  float a = clamp(cuerpo + anillo, 0.0, 1.0);
  a = a * (1.0 - smoothstep(0.88, 1.0, r));
  vec3 col = mix(color.rgb, vec3(1.0, 0.96, 0.85), clamp(nucleo + anillo * 0.4, 0.0, 1.0));
  return vec4(col, a * color.a);
}
]]

local GLSL_FX_RAYO = GLSL_FX_COMUN .. [[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  float y = uv.y;
  float desv = (ruido(vec2(y * 10.0 + uSeed * 5.0, uSeed)) - 0.5) * 0.45 * (0.2 + 0.8 * y);
  float x = uv.x - 0.5 - desv;
  float g = 0.045 * (1.0 - uT * 0.5);
  float core = exp(-(x * x) / (g * g));
  float halo = exp(-(x * x) / (g * g * 24.0)) * 0.55;
  float x2 = x - (ruido(vec2(y * 7.0 + uSeed * 3.0, 4.0)) - 0.5) * 0.7 * smoothstep(0.30, 0.95, y);
  float rama = exp(-(x2 * x2) / (g * g * 0.5)) * 0.45 * smoothstep(0.35, 0.7, y);
  float fade = 1.0 - uT;
  float parpadeo = 0.65 + 0.35 * step(0.5, fract(uT * 12.0 + uSeed));
  float cae = 1.0 - smoothstep(uT * 8.0, uT * 8.0 + 0.08, y);
  float a = clamp((core + halo + rama) * fade * parpadeo * cae, 0.0, 1.0);
  vec3 col = mix(color.rgb, vec3(1.0, 1.0, 1.0), clamp(core, 0.0, 1.0));
  return vec4(col, a * color.a);
}
]]

local GLSL_FX_ONDA = GLSL_FX_COMUN .. [[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec2 p = (uv - vec2(0.5, 0.5)) * 2.0;
  float r = length(p);
  float radio = 0.9 * (1.0 - (1.0 - uT) * (1.0 - uT));
  float q = (r - radio) * 9.0;
  float anillo = exp(-q * q) * (1.0 - uT);
  float cola = smoothstep(radio, radio * 0.2, r) * 0.22 * (1.0 - uT);
  float a = clamp(anillo + cola, 0.0, 1.0);
  vec3 col = color.rgb + vec3(anillo * 0.45, anillo * 0.45, anillo * 0.45);
  return vec4(col, a * color.a);
}
]]

-- ------------------------------------------------------------
-- UTILIDADES SEGURAS
-- ------------------------------------------------------------
local function compilar(nombre, src)
  local ok, res = pcall(love.graphics.newShader, src)
  if not ok then
    print("[SHADER] '" .. nombre .. "' no compilo: " .. tostring(res))
    return nil, tostring(res)
  end
  return res
end

local function enviar(sh, nombre, ...)
  if not sh then return end
  local ok, tiene = pcall(sh.hasUniform, sh, nombre)
  if ok and tiene then
    pcall(sh.send, sh, nombre, ...)
  end
end

local function compilarPost(calidad)
  if variantesPost[calidad] then return variantesPost[calidad] end
  local src = "#define QUALITY " .. tostring(calidad) .. "\n" .. GLSL_POST
  local sh = compilar("post(q" .. calidad .. ")", src)
  variantesPost[calidad] = sh or false
  return sh
end

-- ------------------------------------------------------------
-- PERFILES DE COLOR (se interpolan suavemente)
-- ------------------------------------------------------------
local function nuevoPerfil(t)
  local p = {
    bloom = 0.35, umbral = 0.60, aberr = 0.0, vineta = 0.35,
    sat = 1.05, contraste = 1.04, tr = 1, tg = 1, tb = 1,
    onda = 0.0, grano = 0.0,
    oscuridad = 0.0, osr = 0.02, osg = 0.02, osb = 0.06,
  }
  for k, v in pairs(t or {}) do p[k] = v end
  return p
end

local PERFILES = {
  menu    = nuevoPerfil({ bloom = 0.50, vineta = 0.45, sat = 1.10, tr = 1.00, tg = 0.98, tb = 1.06 }),
  intro   = nuevoPerfil({ bloom = 0.55, vineta = 0.55, sat = 1.05, grano = 0.03 }),
  lobby   = nuevoPerfil({ bloom = 0.55, umbral = 0.52, vineta = 0.45, sat = 1.10, contraste = 1.06,
                          tr = 0.97, tg = 1.00, tb = 1.07 }),
  juego   = nuevoPerfil({}),
  neutro  = nuevoPerfil({ bloom = 0.25, vineta = 0.25 }),
}

local PERFILES_BIOMA = {
  catacumbas = nuevoPerfil({ bloom = 0.40, sat = 0.96, tr = 0.97, tg = 0.98, tb = 1.05,
                             oscuridad = 0.38, osr = 0.02, osg = 0.02, osb = 0.07 }),
  bosque     = nuevoPerfil({ bloom = 0.45, sat = 1.12, tr = 0.95, tg = 1.05, tb = 0.95, contraste = 1.05,
                             oscuridad = 0.36, osr = 0.01, osg = 0.05, osb = 0.02 }),
  magma      = nuevoPerfil({ bloom = 0.65, umbral = 0.50, sat = 1.12, contraste = 1.09,
                             tr = 1.09, tg = 0.97, tb = 0.91, onda = 0.0007,
                             oscuridad = 0.22, osr = 0.09, osg = 0.01, osb = 0.0 }),
  glaciar    = nuevoPerfil({ bloom = 0.50, sat = 0.96, tr = 0.93, tg = 1.00, tb = 1.10,
                             oscuridad = 0.16, osr = 0.0, osg = 0.03, osb = 0.11 }),
  vacio      = nuevoPerfil({ bloom = 0.60, sat = 1.06, contraste = 1.07,
                             tr = 1.04, tg = 0.93, tb = 1.10, aberr = 0.0012,
                             oscuridad = 0.42, osr = 0.05, osg = 0.0, osb = 0.10 }),
}

local actual = nuevoPerfil({})
local objetivo = nuevoPerfil({})

local function copiarPerfil(dst, src)
  for k, v in pairs(src) do dst[k] = v end
end

function Shaders.perfilEstado(nombre)
  local p = PERFILES[nombre]
  if not p then
    if nombre == "beta" then p = PERFILES.juego else p = PERFILES.neutro end
  end
  copiarPerfil(objetivo, p)
end

function Shaders.perfilBioma(bioma)
  local id = bioma and bioma.id
  local p = PERFILES_BIOMA[id] or PERFILES.juego
  copiarPerfil(objetivo, p)
end

-- ------------------------------------------------------------
-- EFECTOS PUNTUALES
-- ------------------------------------------------------------
local pulsoAberr = 0
local pulsoDano = 0
local shockT = -1
local shockX, shockY = 0.5, 0.5

function Shaders.shock(cx, cy)
  shockT = 0
  shockX, shockY = cx or 0.5, cy or 0.5
end

function Shaders.golpe(k)
  pulsoAberr = math.max(pulsoAberr, k or 0.003)
end

function Shaders.dano(k)
  pulsoDano = math.max(pulsoDano, k or 0.6)
end

-- ------------------------------------------------------------
-- INICIALIZACION / CONFIG
-- ------------------------------------------------------------
local function pruebaDeDibujo()
  -- Dibuja un quad diminuto con cada shader para detectar fallos en ejecucion
  local c = love.graphics.newCanvas(8, 8)
  local prev = love.graphics.getCanvas()
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
  for _, sh in ipairs({ post, niebla, portal, luz, oscuridad, fxExplosion, fxRayo, fxOnda }) do
    if sh then
      love.graphics.setShader(sh)
      love.graphics.draw(blanco, 0, 0, 0, 8, 8)
    end
  end
  love.graphics.setShader()
  love.graphics.setCanvas(prev)
end

function Shaders.aplicarConfig()
  local habilitado = Config.get("shaders")
  if habilitado == nil then habilitado = true end
  local cal = tonumber(Config.get("shaderCalidad")) or 3
  if cal < 1 then cal = 1 elseif cal > 3 then cal = 3 end
  Shaders.calidad = math.floor(cal)
  Shaders.activo = (habilitado and Shaders.soportado) and true or false
  if Shaders.soportado then
    post = compilarPost(Shaders.calidad) or compilarPost(1) or nil
    if not post then Shaders.activo = false end
  end
end

function Shaders.inicializar()
  Shaders.soportado = false
  Shaders.activo = false
  local ok, err = pcall(function()
    if not love.graphics or not love.graphics.newShader then error("sin soporte de shaders") end
    if love.graphics.getSupported then
      local sup = love.graphics.getSupported()
      if sup and sup.glsl3 == false and sup.glsl1 == false then error("GLSL no soportado") end
    end

    local d = love.image.newImageData(1, 1)
    d:setPixel(0, 0, 1, 1, 1, 1)
    blanco = love.graphics.newImage(d)
    blanco:setFilter("nearest", "nearest")

    post   = compilarPost(3) or compilarPost(2) or compilarPost(1)
    niebla = compilar("niebla", GLSL_NIEBLA)
    portal = compilar("portal", GLSL_PORTAL)
    luz    = compilar("luz", GLSL_LUZ)
    oscuridad = compilar("oscuridad", GLSL_OSCURIDAD)
    fxExplosion = compilar("fx_explosion", GLSL_FX_EXPLOSION)
    fxRayo = compilar("fx_rayo", GLSL_FX_RAYO)
    fxOnda = compilar("fx_onda", GLSL_FX_ONDA)

    if not post then error("el shader de post-proceso no compilo") end

    pruebaDeDibujo()
  end)

  love.graphics.setShader()
  if not ok then
    Shaders.motivoFallo = tostring(err)
    print("[SHADER] Desactivados: " .. Shaders.motivoFallo)
    Shaders.soportado = false
    Shaders.activo = false
    return false
  end

  Shaders.soportado = true
  Shaders.aplicarConfig()
  copiarPerfil(actual, PERFILES.neutro)
  copiarPerfil(objetivo, PERFILES.neutro)
  print("[SHADER] OK. Calidad " .. Shaders.calidad)
  return true
end

function Shaders.desactivar(motivo)
  Shaders.activo = false
  Shaders.motivoFallo = tostring(motivo)
  pcall(love.graphics.setShader)
  print("[SHADER] Desactivados por error en ejecucion: " .. tostring(motivo))
end

-- Estado legible para el menu de ajustes
function Shaders.textoAjuste()
  if not Shaders.soportado then return "No disponible" end
  local h = Config.get("shaders")
  if h == nil then h = true end
  if not h then return "OFF" end
  local n = { "BAJA", "MEDIA", "ALTA" }
  return n[Shaders.calidad] or "ON"
end

-- OFF -> BAJA -> MEDIA -> ALTA -> OFF
function Shaders.ciclarAjuste()
  if not Shaders.soportado then return end
  local h = Config.get("shaders")
  if h == nil then h = true end
  if not h then
    Config.set("shaders", true)
    Config.set("shaderCalidad", 1)
  elseif Shaders.calidad < 3 then
    Config.set("shaderCalidad", Shaders.calidad + 1)
  else
    Config.set("shaders", false)
  end
  Shaders.aplicarConfig()
end

-- ------------------------------------------------------------
-- ACTUALIZACION (suavizado de perfil + calidad adaptativa)
-- ------------------------------------------------------------
local emaDt = 1 / 60
local lentoT = 0
local vivoT = 0

function Shaders.actualizar(dt)
  Shaders.tiempo = (Shaders.tiempo + dt) % 1000
  if not Shaders.activo then return end

  local k = math.min(1, dt * 3.0)
  for clave, v in pairs(objetivo) do
    actual[clave] = actual[clave] + (v - actual[clave]) * k
  end

  pulsoAberr = math.max(0, pulsoAberr - dt * 0.012)
  pulsoDano = math.max(0, pulsoDano - dt * 1.8)
  if shockT >= 0 then
    shockT = shockT + dt
    if shockT > 0.9 then shockT = -1 end
  end

  -- calidad adaptativa: solo baja, nunca sube
  local dtc = math.min(dt, 0.25)
  emaDt = emaDt * 0.95 + dtc * 0.05
  vivoT = vivoT + dt
  if vivoT > 6 and Shaders.calidad > 1 and emaDt > 1 / 32 then
    lentoT = lentoT + dt
    if lentoT > 4 then
      lentoT = 0
      local nueva = Shaders.calidad - 1
      local sh = compilarPost(nueva)
      if sh then
        Shaders.calidad = nueva
        post = sh
        print("[SHADER] Rendimiento bajo: calidad reducida a " .. nueva)
      end
    end
  else
    lentoT = 0
  end
end

-- ------------------------------------------------------------
-- DIBUJO DEL CANVAS CON POST-PROCESO
-- Devuelve true si dibujo con shader; false si el llamador debe dibujar normal
-- ------------------------------------------------------------
function Shaders.dibujarCanvas(canvas, ox, oy, esc, ancho, alto)
  if not Shaders.activo or not post then return false end
  local ok, err = pcall(function()
    local p = actual
    enviar(post, "uTime", Shaders.tiempo)
    enviar(post, "uRes", { ancho, alto })
    enviar(post, "uBloom", p.bloom)
    enviar(post, "uUmbral", p.umbral)
    enviar(post, "uAberr", p.aberr + pulsoAberr)
    enviar(post, "uVineta", p.vineta)
    enviar(post, "uSat", p.sat)
    enviar(post, "uContraste", p.contraste)
    enviar(post, "uTinte", { p.tr, p.tg, p.tb })
    enviar(post, "uPulso", pulsoDano)
    enviar(post, "uOnda", p.onda)
    enviar(post, "uGrano", p.grano)
    if shockT >= 0 then
      enviar(post, "uShock", { shockX, shockY, shockT * 0.9 })
      enviar(post, "uShockF", math.max(0, 1 - shockT / 0.9))
    else
      enviar(post, "uShockF", 0)
      enviar(post, "uShock", { 0.5, 0.5, 0 })
    end
    love.graphics.setShader(post)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, ox, oy, 0, esc, esc)
    love.graphics.setShader()
  end)
  if not ok then
    love.graphics.setShader()
    Shaders.desactivar(err)
    return false
  end
  return true
end

-- ------------------------------------------------------------
-- QUADS CON SHADER (luces, niebla, portal)
-- ------------------------------------------------------------
local function quad(sh, x, y, w, h)
  love.graphics.setShader(sh)
  love.graphics.draw(blanco, x, y, 0, w, h)
  love.graphics.setShader()
end

-- Luz suave aditiva. Con shaders: gradiente liso. Sin shaders: circulos apilados.
function Shaders.luz(x, y, radio, r, g, b, a)
  local modoPrevio = love.graphics.getBlendMode()
  love.graphics.setBlendMode("add")
  local hecho = false
  if Shaders.activo and luz and blanco then
    local ok = pcall(function()
      love.graphics.setColor(r, g, b, a)
      quad(luz, x - radio, y - radio, radio * 2, radio * 2)
    end)
    if ok then hecho = true else love.graphics.setShader() end
  end
  if not hecho then
    for i = 3, 1, -1 do
      love.graphics.setColor(r, g, b, a * 0.22 * (4 - i) / 3)
      love.graphics.circle("fill", x, y, radio * i / 3)
    end
  end
  love.graphics.setBlendMode(modoPrevio)
end

-- Niebla animada. opts: color{r,g,b}, alpha, escala, vel{x,y}, offset{x,y}, corte
function Shaders.niebla(x, y, w, h, opts)
  if not (Shaders.activo and niebla and blanco) then return false end
  opts = opts or {}
  local c = opts.color or { 1, 1, 1 }
  local vel = opts.vel or { 0.03, 0.01 }
  local off = opts.offset or { 0, 0 }
  local ok = pcall(function()
    enviar(niebla, "uTime", Shaders.tiempo)
    enviar(niebla, "uOffset", { off[1], off[2] })
    enviar(niebla, "uVel", { vel[1], vel[2] })
    enviar(niebla, "uEscala", opts.escala or 3.0)
    enviar(niebla, "uDensidad", opts.densidad or 1.0)
    enviar(niebla, "uCorte", opts.corte or 0.35)
    love.graphics.setColor(c[1], c[2], c[3], opts.alpha or 0.25)
    quad(niebla, x, y, w, h)
  end)
  if not ok then love.graphics.setShader() Shaders.desactivar("niebla") return false end
  return true
end

-- Efecto de habilidad (explosion | rayo | onda). Dibujar con blend "add".
-- t: progreso 0..1. Devuelve false si no hay shader (el llamador no hace nada).
-- En calidad BAJA se omiten (ahorro de rendimiento).
function Shaders.efecto(nombre, x, y, w, h, r, g, b, a, t, semilla)
  if not (Shaders.activo and blanco) or Shaders.calidad < 2 then return false end
  local sh = (nombre == "explosion" and fxExplosion) or (nombre == "rayo" and fxRayo)
          or (nombre == "onda" and fxOnda) or nil
  if not sh then return false end
  local ok = pcall(function()
    enviar(sh, "uT", t)
    enviar(sh, "uSeed", semilla or 0)
    love.graphics.setColor(r, g, b, a)
    quad(sh, x, y, w, h)
  end)
  if not ok then love.graphics.setShader() return false end
  return true
end

-- Oscuridad de la mazmorra. luces: lista de {x, y, radio} en pixeles virtuales.
-- escala: 0..1 para atenuar (p. ej. en salas de jefe).
function Shaders.oscuridad(luces, escala)
  if not (Shaders.activo and oscuridad and blanco) then return false end
  local nivel = actual.oscuridad * (escala or 1)
  if nivel < 0.01 then return false end
  local ok = pcall(function()
    local arr = {}
    for i = 1, 8 do
      local l = luces[i]
      arr[i] = l and { l[1], l[2], l[3] } or { 0, 0, 0 }
    end
    enviar(oscuridad, "uRes", { constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL })
    enviar(oscuridad, "uOscuridad", nivel)
    enviar(oscuridad, "uTinte", { actual.osr, actual.osg, actual.osb })
    if oscuridad:hasUniform("uLuz") then
      oscuridad:send("uLuz", unpack(arr))
    end
    love.graphics.setColor(1, 1, 1, 1)
    quad(oscuridad, 0, 0, constantes.ANCHO_VIRTUAL, constantes.ALTO_VIRTUAL)
  end)
  if not ok then love.graphics.setShader() Shaders.desactivar("oscuridad") return false end
  return true
end

-- Vortice del portal. Dibujar con blend "add".
function Shaders.portal(x, y, w, h, colA, colB)
  if not (Shaders.activo and portal and blanco) then return false end
  colA = colA or { 0.15, 0.45, 1.0 }
  colB = colB or { 0.60, 0.95, 1.0 }
  local ok = pcall(function()
    enviar(portal, "uTime", Shaders.tiempo)
    enviar(portal, "uColA", colA)
    enviar(portal, "uColB", colB)
    love.graphics.setColor(1, 1, 1, 1)
    quad(portal, x - w / 2, y - h / 2, w, h)
  end)
  if not ok then love.graphics.setShader() Shaders.desactivar("portal") return false end
  return true
end

return Shaders
