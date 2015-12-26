local Console = require "game/console"
local Gamestate = require "gamestate"
local InputManager = require "input"
local st_mainmenu = require "st_mainmenu"

local vid = nil

local gs = {}

function gs:enter()
  collectgarbage("collect")
  
  self.start_time = love.timer.getTime()
  
  vid = love.graphics.newVideo("base/youwin.ogv")
  local src = vid:getSource()
  src:setVolume(0.5)
  vid:play()
end

function gs:leave()
  vid:pause()
  vid = nil
end

function gs:keypressed(key, code, isrepeat)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.switch(st_mainmenu)
  end
end

function gs:gamepadpressed(pad, button)
  local inputs = InputManager.getInputs()
  if inputs.jump then
    Gamestate.switch(st_mainmenu)
  end
end

function gs:draw()   
  local Easing = require('game/easing')
  
  if not vid:isPlaying() then
    vid:rewind()
    vid:play()
  end
    
  local width, height = love.graphics.getDimensions()
  
  local t = love.timer.getTime() - self.start_time
  
  local x = Easing.bounce(t%2, width*0.3, width*0.3, 2)
  local y = Easing.bounce(t%2, height*0.5, -height*0.2, 2)

  love.graphics.draw(vid, 0, 0, 0, width/vid:getWidth(), height/vid:getHeight())
  love.graphics.setColor(255, 182, 13, 255)
  love.graphics.printf("YOU WIN!", 0, height*0.2, width/4, "center", 0, 4, 4)
  love.graphics.printf("Press jump to go back to the menu", 0, height*0.3, width, "center", 0, 1, 1)
  
  love.graphics.print("good dog", x, y, -2+(t%2), 4*(t%2))  

  love.graphics.setColor(255, 255, 255, 255)
end

return gs