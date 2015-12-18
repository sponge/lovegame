local Console = require "game/console"
local Gamestate = require "gamestate"
local InputManager = require 'input'

local gs = {error = nil}

local inputs = nil

local selectedIndex = 1
local levelList = {}
local helptext =
[[welcome to my dumb game

arrows to move
z to jump/double jump
down while midair to pogo
hold left/right on wall to wallslide
wallslide + jump to walljump]]

local function cb_play(opt, inputs)
  if inputs then
    if inputs.jump then
      Console:dispatch("map", levelList[opt.counter])
    end
    
    if inputs.right then
      if opt.counter == #levelList then opt.counter = 1
      else opt.counter = opt.counter + 1 end
    end
    
    if inputs.left then
      if opt.counter == 1 then opt.counter = #levelList
      else opt.counter = opt.counter - 1 end
    end
  end
  
  opt.val = levelList[opt.counter]
end

local function cb_vsync(opt, inputs)
  local cvar = Console:getcvar("vid_vsync")
  
  if inputs and (inputs.jump or inputs.left or inputs.right) then
    cvar = Console:setcvar("vid_vsync", cvar.int == 0 and 1 or 0)
  end
  
  opt.val = cvar.int > 0 and "On" or "Off"
end

local function cb_fs(opt, inputs)
  local cvar = Console:getcvar("vid_fullscreen")
  
  if inputs and (inputs.jump or inputs.left or inputs.right) then
    cvar = Console:setcvar("vid_fullscreen", cvar.int == 0 and 1 or 0)
  end
  
  opt.val = cvar.int > 0 and "On" or "Off"
end

local function cb_quit(opt, inputs)
  if inputs and inputs.jump then
    Console:dispatch("quit")
  end
end


local options = {
  { label = "Play Level", value = nil, counter = 1, cb = cb_play },
  { label = "Fullscreen", value = nil, counter = 1, cb = cb_fs },
  { label = "VSync", value = nil, counter = 1, cb = cb_vsync },
  { label = "Quit", value = nil, counter = 1, cb = cb_quit },
}

function gs:enter()
  local mapdir = love.filesystem.getDirectoryItems("base/maps")
  
  for _, v in ipairs(mapdir) do
    if string.match(v, ".json$") then
      table.insert(levelList, "base/maps/"..v)
    end
  end
end

function gs:leave()
  gs.error = nil
end

function gs:keypressed(key, code, isrepeat)
  inputs = InputManager.getInputs()
end

function gs:gamepadpressed(pad, button)
  inputs = InputManager.getInputs()
end

function gs:draw()   
  if inputs then
    if inputs.down then
      selectedIndex = math.min(#options, selectedIndex + 1)
    elseif inputs.up then
      selectedIndex = math.max(1, selectedIndex - 1)
    end
    
    if love.keyboard.isDown('return') then inputs.jump = true end
      
  end
  
  if options[selectedIndex].cb then
    options[selectedIndex].cb(options[selectedIndex], inputs)
  end
  
  local width, height = love.graphics.getDimensions()
  
  love.graphics.setColor(30,30,30,255)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setColor(255, 255, 255, 255)
  
  if gs.error ~= nil then
    love.graphics.printf(gs.error, 0, 15, width, "center")
  end

  local w = math.min( 800, math.floor(0.8 * width) )
  local lside = math.floor((width - w) / 2)
  local x = math.floor(w / 2)
  local y = math.floor(height / 2 - 100)
  
  if InputManager.getPad() ~= nil then
    love.graphics.setColor(0,168,0,255)
    love.graphics.printf("GAMEPAD ENABLED! " .. InputManager.getPad():getName(), 0, y, width, "center")
    love.graphics.setColor(255,255,255,255)

    y = y + 20
  end
  love.graphics.printf(helptext, 0, y, width, "center")
  y = y + 150

  
  for i, v in ipairs(options) do
    if v.cb then v.cb(v, nil) end
      if i == selectedIndex then
        love.graphics.setColor(168,0,0,255)
        love.graphics.rectangle("fill", lside, y-3, w, 20)
        love.graphics.setColor(255,255,255,255)
        if v.val then
          love.graphics.printf( "<", lside+10, y, w, "left" )
          love.graphics.printf( ">", lside-10, y, w, "right" )
        end
      end

    if v.val then
      love.graphics.printf( v.label, lside+100, y, w, "left" )
      love.graphics.printf( v.val, lside-100, y, w, "right" )
    else
      love.graphics.printf( v.label, lside, y, w, "center" )
    end
    
    y = y + 25
  end
  
  inputs = nil
end

return gs