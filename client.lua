local Gamestate = require "gamestate"
local InputManager = require 'input'
local Console = require 'game/console'

local st_mainmenu = require "st_mainmenu"
local st_game = require "st_game"
local st_console = require "st_console"
local st_debug = require "st_debug"

local r_drawdebug = nil

function game_err(msg)
  st_mainmenu.error = msg
  Gamestate.switch(st_mainmenu)
end

local timers = {}
local function measure(mode, metric, time)
  if mode ~= 'clearall' and timers[metric] == nil then
    timers[metric] = {0,0,0,0}
  end
  
  if mode == 'get' then
    return string.format("%.1f", timers[metric][2] * 1000)
  elseif mode == 'getmax' then
    return string.format("%.1f", timers[metric][3] * 1000)
  elseif mode == 'getsum' then
    return string.format("%.1f", timers[metric][4] * 1000)
  elseif mode == 'getpct' then
    return string.format("%.1f", timers[metric][4] / timers.frame[4] * 100 )
  elseif mode == 'clearall' then
    for i, v in pairs(timers) do
      timers[i][3] = 0
      timers[i][4] = 0
    end
  elseif mode == 'start' then
    timers[metric][1] = love.timer.getTime()
  elseif mode == 'end' then
    timers[metric][2] = love.timer.getTime() - timers[metric][1]
    timers[metric][3] = math.max(timers[metric][3], timers[metric][2])
    timers[metric][4] = timers[metric][4] + timers[metric][2]
  end
  
end

local function addDebugLine(y, ...)
  local x = 10
  for _, e in ipairs({...}) do
    love.graphics.print(e, x, y)
    x = x + 80
  end
  return y + 20
end

local function con_map(mapname)
  local st_game = require 'st_game'
  print("Switching to gameplay scene with map", mapname)
  Gamestate.switch(st_game, mapname)
end

local function con_connect(host)
  local st_connect = require 'st_connect'
  print("Connecting to", host)
  Gamestate.switch(st_connect, host)
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
  require("lovebird").update()
  io.stdout:setvbuf("no")

  local width, height, flags = love.window.getMode()
  
  Console:init()
  print("pgup/pgdn to scroll back through history")
  print("alt + pgup/pgdn to jump to top/bottom")
  print("up arrow and down arrow to go through command history")
  print("alt+backspace to backspace a full word")
  
  Console:addcvar("vid_vsync", flags.vsync, cb_vid_vsync)
  Console:addcvar("vid_fullscreen", flags.fullscreen, cb_vid_fullscreen)
  
  Console:addcommand("map", con_map)
  Console:addcommand("connect", con_connect)
  
  r_drawdebug = Console:addcvar("r_drawdebug", 0)
  
  -- we'll handle draw ourselves so we can draw debug stuff
  local callbacks = { 'errhand', 'update' }
  for k in pairs(love.handlers) do
    callbacks[#callbacks+1] = k
  end
  Gamestate.registerEvents(callbacks)
  
  Gamestate.switch(st_mainmenu)
end

function love.joystickadded( gamepad )
  InputManager.gamepadAdded(gamepad)
end

function love.joystickremoved( gamepad )
  InputManager.gamepadRemoved(gamepad)
end

function love.run()
	if love.math then	love.math.setRandomSeed(os.time()) end
 	if love.event then	love.event.pump()	end
 	if love.load then love.load(arg) end
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
  local tickrate = 1/200
 
	-- Main loop time.
	while true do
    measure('start', 'frame')
    
    require("lovebird").update()
    
		-- Process events.
		if love.event then
      measure('start', 'events')
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
      measure('end', 'events')
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = dt + love.timer.getDelta()
      -- Call update and draw
      while dt > tickrate do
        measure('start', 'update')
        if love.update then love.update(tickrate) end -- will pass 0 if love.timer is disabled
        measure('end', 'update')
        dt = dt - tickrate
      end
    else
      if love.update then love.update(0) end
		end
 
		if love.graphics and love.graphics.isActive() then
      measure('start', 'draw')
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
      measure('end', 'draw')
		end
    
    measure('start', 'gc')
    collectgarbage("step")
    measure('end', 'gc')

    measure('end', 'frame')
    
    if love.timer then love.timer.sleep(0.001) end
    
    if love.keyboard.isDown("delete") then
      measure('clearall')
    end
	end
 
end

function love.draw()
  Gamestate.draw()
  
  if r_drawdebug.int > 0 and Gamestate.current() ~= st_console then
    local y = 20
    y = addDebugLine(y, "FPS:",    love.timer.getFPS(), string.format("avg %.1fms", love.timer.getAverageDelta( )*1000))
    if r_drawdebug.int > 1 then
      y = addDebugLine(y, "Memory:", math.floor(collectgarbage("count")))
      y = addDebugLine(y, "",        "Time",                  "Max",                     "% (del resets)")
      y = addDebugLine(y, "Frame:",  measure('get','frame'),  measure('getmax','frame'),  measure('getpct','frame'))
      y = addDebugLine(y, "Events:", measure('get','events'), measure('getmax','events'), measure('getpct','events'))
      y = addDebugLine(y, "Update:", measure('get','update'), measure('getmax','update'), measure('getpct','update'))
      y = addDebugLine(y, "Draw:",   measure('get','draw'),   measure('getmax','draw'),   measure('getpct','draw'))
      y = addDebugLine(y, "GC:",     measure('get','gc'),     measure('getmax','gc'),     measure('getpct','gc'))
    end
  end
end
  
function love.keypressed(key, code, isrepeat)
  if key == '`' then
    if Gamestate.current() == st_console then
      Gamestate.pop()
    else
      Gamestate.push(st_console)
    end
  end
  
  if key == 'd' and love.keyboard.isDown('lctrl') then
    if Gamestate.current() == st_debug then
      Gamestate.pop()
    elseif Gamestate.current() == st_game then
      Gamestate.push(st_debug)
    end
  end
end