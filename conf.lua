function love.conf(t)
  t.identity = "factralcodice"
  t.version = "11.4"
  t.window.title = "Factral Codice"
  t.window.width = 960
  t.window.height = 540
  t.window.resizable = false
  t.window.fullscreen = true
  t.window.fullscreentype = "desktop"
  t.window.vsync = 1
  t.window.msaa = 0

  t.modules.joystick = false
  t.modules.physics = false
  t.modules.video = false
end