function love.conf(t)
  local isServer = false
  for i, v in ipairs(arg) do
    if v == '-server' then
      isServer = true
      break
    end
  end
  
  if isServer then
    t.console = true
    t.modules.audio = false              -- Enable the audio module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)
    t.modules.graphics = false           -- Enable the graphics module (boolean)
    t.modules.image = false              -- Enable the image module (boolean)
    t.modules.joystick = false           -- Enable the joystick module (boolean)
    t.modules.keyboard = true           -- Enable the keyboard module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.mouse = false              -- Enable the mouse module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)
    t.modules.sound = false              -- Enable the sound module (boolean)
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = false              -- Enable the touch module (boolean)
    t.modules.video = false              -- Enable the video module (boolean)
    t.modules.window = false             -- Enable the window module (boolean)
    t.modules.thread = true             -- Enable the thread module (boolean)
  else
    t.console = false
    t.window.width = 1280
    t.window.height = 720
    t.window.vsync = true
    t.window.fullscreen = false
    t.window.resizable = true
  end
end