local Gamestate = require "gamestate"

local gs = {error = nil}

local selectedIndex = 1
local levelList = {}
local helptext =
[[welcome to my dumb game

arrows to move
z to jump/double jump
down while midair to pogo
hold left/right on wall to wallslide
wallslide + jump to walljump]]

local function cb_play(opt, key)
  if key == "return" then
    Gamestate.switch(s_game, levelList[opt.counter])
  end
  
  if key == "right" then
    if opt.counter == #levelList then opt.counter = 1
    else opt.counter = opt.counter + 1 end
  end

  
  if key == "left" then
    if opt.counter == 1 then opt.counter = #levelList
    else opt.counter = opt.counter - 1 end
  end
  
  opt.val = levelList[opt.counter]
end

local function cb_vsync(opt, key)
  local width, height, flags = love.window.getMode()
  
  if key == 'return' or key == 'left' or key == 'right' then
    flags.vsync = not flags.vsync
    love.window.setMode( width, height, flags)
  end
  
  opt.val = flags.vsync and "On" or "Off"
end

local function cb_fs(opt, key)
  local width, height, flags = love.window.getMode()
  
  if key == 'return' or key == 'left' or key == 'right' then
    flags.fullscreen = not flags.fullscreen
    if not fullscreen then
      love.window.setMode( 1280, 720, flags)
    else
      love.window.setMode( width, height, flags)
    end
  end
  
  opt.val = flags.fullscreen and "On" or "Off"
end

local function cb_quit(opt, key)
  if key == 'return' then
    love.event.push('quit')
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

function gs:draw()
  local width, height = love.graphics.getDimensions()
  
  if gs.error ~= nil then
    love.graphics.printf(gs.error, 0, 15, width, "center")
  end
  
  love.graphics.printf(helptext, 0, 120, width, "center")

  
  local x = width / 2
  local y = height / 2 - 100
  local lside = 0.3 * width
  local w = 0.4 * width

  
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
end

function gs:keypressed(key, code, isrepeat)
  if key == 'z' then key = 'return' end
    
  if key == 'down' then
    selectedIndex = math.min(#options, selectedIndex + 1)
    return
  elseif key == 'up' then
    selectedIndex = math.max(1, selectedIndex - 1)
    return
  end
    
  if options[selectedIndex].cb then
    options[selectedIndex].cb(options[selectedIndex], key)
  end
end

return gs