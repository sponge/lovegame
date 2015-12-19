local Strictness = require "game/strictness"
if arg and arg[#arg] ~= "-debug" then
  Strictness.strict(_G)
else
  require("mobdebug").start()
  --require("mobdebug").off()
end


-- globals
_, s_mainmenu, s_game, game_err= nil

local Gamestate = require "gamestate"
local InputManager = require 'input'
local Console = require 'game/console'

s_mainmenu = require "st_mainmenu"
s_game = require "st_game"
local s_console = require "st_console"
local s_debug = require "st_debug"


function game_err(msg)
  s_mainmenu.error = msg
  Gamestate.switch(s_mainmenu)
end

local timers = {
  frame = {0,0},
  events = {0,0},
  update = {0,0},
  draw = {0,0},
  gc = {0,0},
}

local max_timers = {
  frame = 0,
  events = 0,
  update = 0,
  draw = 0,
  gc = 0
}

local debugY = 20
local function addDebugLine(col1, col2, col3)
  if col1 ~= nil then love.graphics.print(col1, 10, debugY) end
  if col2 ~= nil then love.graphics.print(col2, 90, debugY) end
  if col3 ~= nil then love.graphics.print(col3, 130, debugY) end
  debugY = debugY + 20
end

local write = io.write
local origprint = print
print = function(...)
   write("[", love.timer.getTime(), "] ")
   origprint(...)
   Console:addline(...)
end

local function con_quit(name)
  if love.event then
    love.event.push('quit')
  end
end

local function cb_vid_vsync(old, cvar)
  local width, height, flags = love.window.getMode()
  flags.vsync = tonumber(cvar.int) > 0
  love.window.setMode(width, height, flags)
end

local function cb_vid_fullscreen(old, cvar)
  local width, height, flags = love.window.getMode()
  flags.fullscreen = tonumber(cvar.int) > 0
  love.window.setMode(width, height, flags)
end

function love.load(arg)
  local width, height, flags = love.window.getMode()
  
  Console:init()
  
  Console:addcommand("quit", con_quit)
  Console:addcvar("vid_vsync", flags.vsync, cb_vid_vsync)
  Console:addcvar("vid_fullscreen", flags.fullscreen, cb_vid_fullscreen)
  
  -- we'll handle draw ourselves so we can draw debug stuff
  local callbacks = { 'errhand', 'update' }
  for k in pairs(love.handlers) do
    callbacks[#callbacks+1] = k
  end
  Gamestate.registerEvents(callbacks)
  
  Gamestate.switch(s_mainmenu)
end

function love.joystickadded( gamepad )
  InputManager.gamepadAdded(gamepad)
end

function love.joystickremoved( gamepad )
  InputManager.gamepadRemoved(gamepad)
end

function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.event then
		love.event.pump()
	end
 
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
  local tickrate = 1/200
 
	-- Main loop time.
	while true do
    timers.frame[1] = love.timer.getTime()
		-- Process events.
		if love.event then
      timers.events[1] = love.timer.getTime()
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
      timers.events[2] = love.timer.getTime() - timers.events[1]
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = dt + love.timer.getDelta()
      -- Call update and draw
      while dt > tickrate do
        timers.update[1] = love.timer.getTime()
        if love.update then love.update(tickrate) end -- will pass 0 if love.timer is disabled
        timers.update[2] = love.timer.getTime() - timers.update[1]
        dt = dt - tickrate
      end
    else
      if love.update then love.update(0) end
		end
 
		if love.graphics and love.graphics.isActive() then
      timers.draw[1] = love.timer.getTime()
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
      timers.draw[2] = love.timer.getTime() - timers.draw[1]
		end
    
    timers.gc[1] = love.timer.getTime()
    collectgarbage("step")
    timers.gc[2] = love.timer.getTime() - timers.gc[1]

    
    timers.frame[2] = love.timer.getTime() - timers.frame[1]
    
    if love.timer then love.timer.sleep(0.001) end
    
    if love.keyboard.isDown("delete") then
      for i, v in pairs(max_timers) do
        max_timers[i] = 0
      end
    else
      for i, v in pairs(max_timers) do
        max_timers[i] = math.max(max_timers[i], timers[i][2])
      end
    end
	end
 
end

function love.draw()
  Gamestate.draw()
  
  if Gamestate.current() ~= s_console then
    debugY = 20
    addDebugLine("FPS:", love.timer.getFPS())
    addDebugLine("Memory:", math.floor(collectgarbage("count")))
    addDebugLine("Time (Max Time - del to reset)")
    addDebugLine("Frame:", string.format("%.1f", timers.frame[2] * 1000), string.format("(%.2f)", max_timers.frame * 1000))
    addDebugLine("Events:", string.format("%.1f", timers.events[2] * 1000), string.format("(%.2f)", max_timers.events * 1000))
    addDebugLine("Update:", string.format("%.1f", timers.update[2] * 1000), string.format("(%.2f)", max_timers.update * 1000))
    addDebugLine("Draw:", string.format("%.1f", timers.draw[2] * 1000), string.format("(%.2f)", max_timers.draw * 1000))
    addDebugLine("GC:", string.format("%.1f", timers.gc[2] * 1000), string.format("(%.2f)", max_timers.gc * 1000))
  end
end
  
function love.keypressed(key, code, isrepeat)
  if key == '`' then
    if Gamestate.current() == s_console then
      Gamestate.pop()
    else
      Gamestate.push(s_console)
    end
  end
  
  if key == 'd' and love.keyboard.isDown('lctrl') then
    if Gamestate.current() == s_debug then
      Gamestate.pop()
    elseif Gamestate.current() == s_game then
      Gamestate.push(s_debug)
    end
  end
end